const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const Product = require('../models/Product');
const Category = require('../models/Category');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// Drop legacy slug_1 unique index if it exists to prevent slug: null duplicate key errors
Product.collection.dropIndex('slug_1').catch(() => {});

const productUpload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => {
      try {
        const uploadDir = path.join(process.cwd(), 'uploads', 'products');
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
      } catch (dirErr) {
        cb(dirErr, null);
      }
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, 'product-' + uniqueSuffix + path.extname(file.originalname));
    }
  }),
  limits: { fileSize: 50 * 1024 * 1024 }
}).fields([
  { name: 'imageFile', maxCount: 1 },
  { name: 'image', maxCount: 1 },
  { name: 'file', maxCount: 1 },
  { name: 'productImage', maxCount: 1 }
]);

const processBase64Image = (imgStr) => {
  if (typeof imgStr === 'string' && imgStr.startsWith('data:image/')) {
    try {
      const matches = imgStr.match(/^data:image\/([A-Za-z-+]+);base64,(.+)$/);
      if (matches && matches.length === 3) {
        const ext = matches[1] === 'jpeg' ? 'jpg' : matches[1];
        const base64Data = matches[2];
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadDir = path.join(process.cwd(), 'uploads', 'products');
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }
        const filename = 'product-b64-' + Date.now() + '-' + Math.round(Math.random() * 1E9) + '.' + ext;
        const filepath = path.join(uploadDir, filename);
        fs.writeFileSync(filepath, buffer);
        return `/uploads/products/${filename}`;
      }
    } catch (e) {
      console.error('Error processing base64 image:', e);
    }
  }
  return imgStr;
};

const checkIsAdmin = async (req) => {
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      const token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id);
      if (user && user.isAdmin) {
        return true;
      }
    } catch (e) {}
  }
  return false;
};

const findCategory = async (category) => {
  if (!category) return null;
  let categoryDoc = null;
  try {
    const catStr = typeof category === 'object' && category !== null
      ? (category._id?.toString() || category.name || '')
      : category.toString();

    if (mongoose.Types.ObjectId.isValid(catStr)) {
      categoryDoc = await Category.findById(catStr);
    }
    if (!categoryDoc) {
      categoryDoc = await Category.findOne({
        name: { $regex: new RegExp('^' + catStr + '$', 'i') }
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
    } else if (p.category.toString) {
      categoryId = p.category.toString();
    }
  } else if (p.category) {
    categoryId = p.category;
    categoryName = p.category.toString();
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

  // If image is base64, convert to file on the fly
  let img = p.image || (p.images && p.images.length > 0 ? p.images[0] : '');
  if (typeof img === 'string' && img.startsWith('data:image/')) {
    img = processBase64Image(img);
  }

  let imagesArr = p.images || [];
  imagesArr = imagesArr.map(im => (typeof im === 'string' && im.startsWith('data:image/') ? processBase64Image(im) : im));

  if (imagesArr.length === 0 && img) {
    imagesArr = [img];
  } else if (img && !imagesArr.includes(img)) {
    imagesArr.unshift(img);
  }

  return {
    ...p,
    image: img,
    images: imagesArr,
    category: categoryId,
    categoryName: categoryName
  };
};

// GET all products (Publicly accessible for user app and admin)
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const search = req.query.search || '';
    const category = req.query.category || '';

    const query = {};

    const isAdmin = await checkIsAdmin(req);
    // Regular users ONLY see visible products (On) unless admin
    if (!isAdmin) {
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

// GET single product (Publicly accessible)
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    const isAdmin = await checkIsAdmin(req);
    // Non-admins shouldn't see hidden products
    if (!isAdmin && !product.visibility) {
      return res.status(403).json({ success: false, message: 'This product is currently unavailable' });
    }

    res.status(200).json({ success: true, data: { product: formatProduct(product) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching product' });
  }
});

const generateSlug = (name) => {
  if (!name) return 'product-' + Date.now();
  return name.toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/-+/g, '-') + '-' + Date.now() + '-' + Math.floor(Math.random() * 1000);
};

// POST Add product
const handleAddProduct = async (req, res) => {
  productUpload(req, res, async (uploadErr) => {
    if (uploadErr) {
      console.error('Product upload error:', uploadErr);
      return res.status(400).json({ success: false, message: uploadErr.message });
    }

    try {
      const {
        name, category, price, originalPrice, stock, countInStock,
        description, visibility, productLink,
        keyBenefits, highlights, brand, sku, shelfLife, madeIn, ingredients
      } = req.body;

      const uploadedFile = req.files?.imageFile?.[0] || req.files?.image?.[0] || req.files?.file?.[0] || req.files?.productImage?.[0];

      let imgVal = req.body.image || '';
      if (uploadedFile) {
        imgVal = `/uploads/products/${uploadedFile.filename}`;
      } else if (imgVal) {
        imgVal = processBase64Image(imgVal);
      }

      const categoryDoc = await findCategory(category);
      if (!categoryDoc) return res.status(400).json({ success: false, message: 'Category not found' });

      const normalizedIngredients = Array.isArray(ingredients)
        ? ingredients.join(', ')
        : (ingredients || '');

      let parsedBenefits = keyBenefits;
      if (typeof keyBenefits === 'string') {
        try { parsedBenefits = JSON.parse(keyBenefits); } catch (e) { parsedBenefits = keyBenefits.split(',').map(s => s.trim()); }
      }

      let parsedHighlights = highlights;
      if (typeof highlights === 'string') {
        try { parsedHighlights = JSON.parse(highlights); } catch (e) { parsedHighlights = highlights.split(',').map(s => s.trim()); }
      }

      let imagesArr = req.body.images ? (Array.isArray(req.body.images) ? req.body.images : [req.body.images]) : (imgVal ? [imgVal] : []);
      imagesArr = imagesArr.map(img => processBase64Image(img));

      const product = await Product.create({
        name,
        slug: generateSlug(name),
        category: categoryDoc._id,
        price,
        originalPrice: originalPrice || undefined,
        stock: stock !== undefined ? stock : (countInStock !== undefined ? countInStock : 0),
        description,
        ingredients: normalizedIngredients,
        visibility: visibility === undefined ? true : (visibility === true || visibility === 'true' || visibility === 'visible'),
        image: imgVal,
        images: imagesArr,
        productLink: productLink || '',
        keyBenefits: parsedBenefits || [],
        highlights: parsedHighlights || [],
        brand: brand || '',
        sku: sku || '',
        shelfLife: shelfLife || '',
        madeIn: madeIn || ''
      });

      const populatedProduct = await Product.findById(product._id).populate('category', 'name slug');

      res.status(201).json({ success: true, data: { product: formatProduct(populatedProduct) } });
    } catch (error) {
      console.error('Create product error:', error);
      res.status(500).json({ success: false, message: 'Error creating product: ' + error.message });
    }
  });
};

router.post('/admin/add-product', protect, adminOnly, handleAddProduct);
router.post('/', protect, adminOnly, handleAddProduct);

// PUT Update product
const handleUpdateProduct = async (req, res) => {
  productUpload(req, res, async (uploadErr) => {
    if (uploadErr) {
      console.error('Product upload error:', uploadErr);
      return res.status(400).json({ success: false, message: uploadErr.message });
    }

    try {
      const {
        name, category, price, originalPrice, stock, countInStock,
        description, visibility, productLink,
        keyBenefits, highlights, brand, sku, shelfLife, madeIn, ingredients
      } = req.body;

      const product = await Product.findById(req.params.id);
      if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

      let categoryId = product.category;
      if (category) {
        const categoryDoc = await findCategory(category);
        if (categoryDoc) categoryId = categoryDoc._id;
      }

      const normalizedIngredients = Array.isArray(ingredients)
        ? ingredients.join(', ')
        : (ingredients !== undefined ? ingredients : product.ingredients);

      const uploadedFile = req.files?.imageFile?.[0] || req.files?.image?.[0] || req.files?.file?.[0] || req.files?.productImage?.[0];

      let imgVal = req.body.image !== undefined ? req.body.image : product.image;
      if (uploadedFile) {
        imgVal = `/uploads/products/${uploadedFile.filename}`;
      } else if (imgVal) {
        imgVal = processBase64Image(imgVal);
      }

      let parsedBenefits = keyBenefits;
      if (typeof keyBenefits === 'string') {
        try { parsedBenefits = JSON.parse(keyBenefits); } catch (e) { parsedBenefits = keyBenefits.split(',').map(s => s.trim()); }
      }

      let parsedHighlights = highlights;
      if (typeof highlights === 'string') {
        try { parsedHighlights = JSON.parse(highlights); } catch (e) { parsedHighlights = highlights.split(',').map(s => s.trim()); }
      }

      let imagesArr = req.body.images ? (Array.isArray(req.body.images) ? req.body.images : [req.body.images]) : (imgVal ? [imgVal] : product.images);
      imagesArr = imagesArr.map(img => processBase64Image(img));

      const updateData = {
        name: name || product.name,
        category: categoryId,
        price: price !== undefined ? price : product.price,
        originalPrice: originalPrice !== undefined ? originalPrice : product.originalPrice,
        stock: stock !== undefined ? stock : (countInStock !== undefined ? countInStock : product.stock),
        description: description || product.description,
        ingredients: normalizedIngredients,
        visibility: visibility !== undefined ? (visibility === true || visibility === 'true' || visibility === 'visible') : product.visibility,
        image: imgVal,
        images: imagesArr,
        productLink: productLink !== undefined ? productLink : product.productLink,
        keyBenefits: parsedBenefits !== undefined ? parsedBenefits : product.keyBenefits,
        highlights: parsedHighlights !== undefined ? parsedHighlights : product.highlights,
        brand: brand !== undefined ? brand : product.brand,
        sku: sku !== undefined ? sku : product.sku,
        shelfLife: shelfLife !== undefined ? shelfLife : product.shelfLife,
        madeIn: madeIn !== undefined ? madeIn : product.madeIn
      };
      if (name && name !== product.name) {
        updateData.slug = generateSlug(name);
      }

      const updated = await Product.findByIdAndUpdate(
        req.params.id,
        updateData,
        { new: true, runValidators: false }
      ).populate('category');

      res.json({ success: true, data: { product: formatProduct(updated) } });
    } catch (error) {
      console.error('Update product error:', error);
      res.status(500).json({ success: false, message: 'Error updating product: ' + error.message });
    }
  });
};

router.put('/admin/update-product/:id', protect, adminOnly, handleUpdateProduct);
router.put('/update-product/:id', protect, adminOnly, handleUpdateProduct);
router.put('/:id', protect, adminOnly, handleUpdateProduct);
router.put('/admin/:id', protect, adminOnly, handleUpdateProduct);

// PATCH Toggle Visibility
const handleToggleVisibility = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    if (req.body.visibility !== undefined) {
      product.visibility = (req.body.visibility === true || req.body.visibility === 'true' || req.body.visibility === 'visible');
    } else {
      product.visibility = !product.visibility;
    }

    await product.save();

    const populatedProduct = await Product.findById(product._id).populate('category', 'name slug');

    res.json({ success: true, data: { product: formatProduct(populatedProduct) } });
  } catch (error) {
    console.error('Toggle visibility error:', error);
    res.status(500).json({ success: false, message: 'Error toggling visibility: ' + error.message });
  }
};

router.patch('/admin/toggle-visibility/:id', protect, adminOnly, handleToggleVisibility);
router.patch('/:id/visibility', protect, adminOnly, handleToggleVisibility);
router.patch('/:id', protect, adminOnly, handleToggleVisibility);

// DELETE Product
const handleDeleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Product deleted' });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ success: false, message: 'Error deleting product: ' + error.message });
  }
};

router.delete('/admin/delete-product/:id', protect, adminOnly, handleDeleteProduct);
router.delete('/:id', protect, adminOnly, handleDeleteProduct);

// POST Extract product data from URL
const handleExtractUrl = async (req, res) => {
  try {
    const { productUrl } = req.body;
    if (!productUrl) return res.status(400).json({ success: false, message: 'Product URL is required' });

    const axios = require('axios');
    const response = await axios.get(productUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
      timeout: 10000
    });

    const html = response.data;
    const getMeta = (prop) => {
      const match = html.match(new RegExp(`<meta[^>]*property=["']og:${prop}["'][^>]*content=["']([^"']+)["']`, 'i')) ||
                    html.match(new RegExp(`<meta[^>]*content=["']([^"']+)["'][^>]*property=["']og:${prop}["']`, 'i')) ||
                    html.match(new RegExp(`<meta[^>]*name=["']${prop}["'][^>]*content=["']([^"']+)["']`, 'i'));
      return match ? match[1] : null;
    };

    const title = getMeta('title') || (html.match(/<title>([^<]+)<\/title>/i)?.[1]?.trim() ?? '');
    const description = getMeta('description') || '';
    const image = getMeta('image') || '';

    res.json({
      success: true,
      data: {
        name: title,
        description: description,
        image: image,
        productLink: productUrl
      }
    });
  } catch (error) {
    console.error('Extract URL error:', error);
    res.status(500).json({ success: false, message: 'Failed to extract product data: ' + error.message });
  }
};

router.post('/admin/extract-url', protect, adminOnly, handleExtractUrl);
router.post('/extract-url', protect, adminOnly, handleExtractUrl);

module.exports = router;
