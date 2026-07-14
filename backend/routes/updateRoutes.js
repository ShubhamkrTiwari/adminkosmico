const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const AppUpdate = require('../models/AppUpdate');

const router = express.Router();

router.use(protect);
router.use(adminOnly);

// GET /api/admin/updates - Get all app updates
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status || '';
    const type = req.query.type || '';

    const query = {};
    if (status) {
      query.publishStatus = status;
    }
    if (type) {
      query.type = type;
    }

    const updates = await AppUpdate.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await AppUpdate.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        updates,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get updates error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching updates'
    });
  }
});

// GET /api/admin/updates/:id - Get single update
router.get('/:id', async (req, res) => {
  try {
    const update = await AppUpdate.findById(req.params.id);
    
    if (!update) {
      return res.status(404).json({
        success: false,
        message: 'Update not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { update }
    });
  } catch (error) {
    console.error('Get update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching update'
    });
  }
});

// POST /api/admin/updates - Create new update
router.post('/', [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('version').trim().notEmpty().withMessage('Version is required'),
  body('type').isIn(['feature', 'fix', 'patch', 'maintenance']).withMessage('Invalid type'),
  body('notes').trim().notEmpty().withMessage('Notes are required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { title, version, type, notes, publishStatus } = req.body;

    const update = await AppUpdate.create({
      title,
      version,
      type,
      notes,
      publishStatus: publishStatus || 'draft',
      publishedAt: publishStatus === 'published' ? new Date() : null
    });

    res.status(201).json({
      success: true,
      message: 'Update created successfully',
      data: { update }
    });
  } catch (error) {
    console.error('Create update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating update'
    });
  }
});

// PUT /api/admin/updates/:id - Update update
router.put('/:id', async (req, res) => {
  try {
    const update = await AppUpdate.findById(req.params.id);
    
    if (!update) {
      return res.status(404).json({
        success: false,
        message: 'Update not found'
      });
    }

    const { title, version, type, notes, publishStatus } = req.body;

    // If publishing for the first time, set publishedAt
    const updateData = { title, version, type, notes, publishStatus };
    if (publishStatus === 'published' && !update.publishedAt) {
      updateData.publishedAt = new Date();
    }

    const updatedUpdate = await AppUpdate.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Update updated successfully',
      data: { update: updatedUpdate }
    });
  } catch (error) {
    console.error('Update update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating update'
    });
  }
});

// DELETE /api/admin/updates/:id - Delete update
router.delete('/:id', async (req, res) => {
  try {
    const update = await AppUpdate.findByIdAndDelete(req.params.id);
    
    if (!update) {
      return res.status(404).json({
        success: false,
        message: 'Update not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Update deleted successfully'
    });
  } catch (error) {
    console.error('Delete update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting update'
    });
  }
});

module.exports = router;
