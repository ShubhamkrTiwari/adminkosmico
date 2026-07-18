const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const Category = require('../models/Category');

const router = express.Router();

router.use(protect);
router.use(adminOnly);

// GET /api/admin/categories - Get all categories
router.get('/', async (req, res) => {
  try {
    const categoriesCount = await Category.countDocuments();
    console.log(`[DEBUG] Total categories in DB: ${categoriesCount}`);

    const categories = await Category.find().sort({ name: 1 });
    res.status(200).json({ success: true, data: { categories } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching categories' });
  }
});

// GET /api/admin/categories/:id - Get single category
router.get('/:id', async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    res.status(200).json({ success: true, data: { category } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching category' });
  }
});

// POST /api/admin/categories - Create category
router.post('/', [
  body('name').trim().notEmpty().withMessage('Category name is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ success: false, errors: errors.array() });

    const { name, icon, image, description, visibility } = req.body;

    const existingCategory = await Category.findOne({ name });
    if (existingCategory) return res.status(400).json({ success: false, message: 'Category already exists' });

    let categoryVisibility = 'visible';
    if (visibility !== undefined) {
      categoryVisibility = typeof visibility === 'boolean' ? (visibility ? 'visible' : 'hidden') : visibility;
    }

    const category = await Category.create({
      name,
      icon: icon || '',
      image: image || '',
      description: description || '',
      visibility: categoryVisibility
    });

    res.status(201).json({ success: true, message: 'Category created', data: { category } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating category' });
  }
});

// PUT /api/admin/categories/:id - Update category
router.put('/:id', async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });

    const { name, icon, image, description, visibility } = req.body;

    if (visibility !== undefined) {
      category.visibility = typeof visibility === 'boolean' ? (visibility ? 'visible' : 'hidden') : visibility;
    }
    if (name) category.name = name;
    if (icon !== undefined) category.icon = icon;
    if (image !== undefined) category.image = image;
    if (description !== undefined) category.description = description;

    await category.save();
    res.status(200).json({ success: true, message: 'Category updated', data: { category } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating category' });
  }
});

// DELETE /api/admin/categories/:id - Delete category
router.delete('/:id', async (req, res) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    res.status(200).json({ success: true, message: 'Category deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting category' });
  }
});

module.exports = router;
