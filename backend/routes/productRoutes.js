const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const Product = require('../models/Product');
const Category = require('../models/Category');
const mongoose = require('mongoose');

const router = express.Router();

// Apply protection to all routes
router.use(protect);

const findCategory = async (category) => {
  if (!category) return null;
  let categoryDoc = null;
  try {
    if (mongoose.Types.ObjectId.isValid(category)) {
      categoryDoc = await Category.findById(category);
    }
    if (!categoryDoc) {
      categoryDoc = await Category.findOne({
        name: { $regex: new RegExp('^' + category + '$', 'i') }
      });
    }
  } catch (err) {
    console.error('Category find error:', err);
  }
  return categoryDoc;
};

/**
 * Formats product to include categoryName and ensure category is just an ID
 */
const formatProduct = (product) => {
  if (!product) return null;

  // Mongoose document ko plain object mein badlein
  const p = product.toObject ? product.toObject() : JSON.parse(JSON.stringify(product));

  let categoryName = '';
  let categoryId = p.category;

  if (p.category && typeof p.category === 'object') {
    // Agar populated object hai toh name nikaalein
    if (p.category.name) {
      categoryName = p.category.name;
      categoryId = p.category._id || p.category;
    } else if (p.category._id) {
      categoryId = p.category._id;
    }
  }

  // Use product.category as fallback if name is missing (Fix for "General" label)
  if (categoryName === 'General' && categoryId) {
    categoryName = categoryId.toString();
  }

  // Double check if categoryName is still 'General' and p has a populated category object
  if (categoryName === 'General' && p.category && typeof p.category === 'object' && p.category.name) {
    categoryName = p.category.name;
  }

  // Ensure categoryId string format mein ho (Frontend/Edit ke liye)
  if (categoryId && typeof categoryId === 'object' && categoryId.toString) {
    categoryId = categoryId.toString();
  }

  return {
    ...p,
    category: categoryId,
    categoryName: categoryName
  };
};

// GET all products
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const search = req.query.search || '';
    const category = req.query.category || '';

    const query = {};

    // IMPORTANT: Admins see EVERYTHING (On & Off)
    // Regular users ONLY see visible products (On)
    if (!req.user.isAdmin) {
      query.visibility = true;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    if (category) {
      const catDoc = await findCategory(category);
      if (catDoc) query.category = catDoc._id;
    }

    const products = await Product.find(query)
      .populate('category', 'name slug')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    const productsWithNames = products.map(p => formatProduct(p));

    const total = await Product.countDocuments(query);

    res.json({
      success: true,
      data: {
        products: productsWithNames,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Fetch products error:', error);
    res.status(500).json({ success: false, message: 'Error fetching products' });
  }
});

// GET single product
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    // Non-admins shouldn't see hidden products
    if (!req.user.isAdmin && !product.visibility) {
      return res.status(403).json({ success: false, message: 'This product is currently unavailable' });
    }

    res.status(200).json({ success: true, data: { product: formatProduct(product) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching product' });
  }
});

// Admin-only operations below
router.use(adminOnly);

// POST Add product
router.post('/admin/add-product', async (req, res) => {
  try {
    const { name, category, price, stock, description, visibility, image, productLink } = req.body;
    const categoryDoc = await findCategory(category);
    if (!categoryDoc) return res.status(400).json({ success: false, message: 'Category not found' });

    const product = await Product.create({
      name,
      category: categoryDoc._id,
      price,
      stock: stock || 0,
      description,
      visibility: visibility === undefined ? true : (visibility === true || visibility === 'true' || visibility === 'visible'),
      image: image || '',
      productLink: productLink || ''
    });

    // Populate category before sending response
    const populatedProduct = await Product.findById(product._id).populate('category', 'name slug');

    res.status(201).json({ success: true, data: { product: formatProduct(populatedProduct) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating product: ' + error.message });
  }
});

// PUT Update product
router.put('/admin/update-product/:id', async (req, res) => {
  try {
    const { name, category, price, stock, description, visibility, image, productLink } = req.body;
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    let categoryId = product.category;
    if (category) {
      const categoryDoc = await findCategory(category);
      if (categoryDoc) categoryId = categoryDoc._id;
    }

    const updated = await Product.findByIdAndUpdate(
      req.params.id,
      {
        name: name || product.name,
        category: categoryId,
        price: price !== undefined ? price : product.price,
        stock: stock !== undefined ? stock : product.stock,
        description: description || product.description,
        visibility: visibility !== undefined ? (visibility === true || visibility === 'true' || visibility === 'visible') : product.visibility,
        image: image || product.image,
        productLink: productLink || product.productLink
      },
      { new: true }
    ).populate('category');

    res.json({ success: true, data: { product: formatProduct(updated) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating product' });
  }
});

// PATCH Toggle Visibility
router.patch('/admin/toggle-visibility/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    if (req.body.visibility !== undefined) {
      product.visibility = (req.body.visibility === true || req.body.visibility === 'true' || req.body.visibility === 'visible');
    } else {
      product.visibility = !product.visibility;
    }

    await product.save();

    // Populate category name before sending back
    const populatedProduct = await Product.findById(product._id).populate('category', 'name slug');

    res.json({ success: true, data: { product: formatProduct(populatedProduct) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error toggling visibility' });
  }
});

// DELETE Product
router.delete('/admin/delete-product/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Product deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting product' });
  }
});

module.exports = router;
