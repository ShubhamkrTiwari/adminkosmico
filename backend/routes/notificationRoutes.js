const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const Notification = require('../models/Notification');
const User = require('../models/User');

const router = express.Router();

router.use(protect);
router.use(adminOnly);

// GET /api/admin/notifications - Get all notifications
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status || '';

    const query = {};
    if (status) {
      query.status = status;
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Notification.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        notifications,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notifications'
    });
  }
});

// GET /api/admin/notifications/:id - Get single notification
router.get('/:id', async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { notification }
    });
  } catch (error) {
    console.error('Get notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notification'
    });
  }
});

// POST /api/admin/notifications - Create new notification
router.post('/', [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('message').trim().notEmpty().withMessage('Message is required')
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

    const { title, message, image, audience, scheduledAt, status } = req.body;

    // Calculate target audience count
    let targetCount = 0;
    if (audience === 'all') {
      targetCount = await User.countDocuments();
    } else if (audience === 'users') {
      targetCount = await User.countDocuments({ isAdmin: false });
    } else if (audience === 'admins') {
      targetCount = await User.countDocuments({ isAdmin: true });
    }

    const notification = await Notification.create({
      title,
      message,
      image: image || '',
      audience: audience || 'all',
      scheduledAt: scheduledAt || new Date(),
      status: status || 'draft',
      deliveryStats: {
        total: targetCount,
        delivered: 0,
        failed: 0
      }
    });

    res.status(201).json({
      success: true,
      message: 'Notification created successfully',
      data: { notification }
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating notification'
    });
  }
});

// PUT /api/admin/notifications/:id - Update notification
router.put('/:id', async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    const { title, message, image, audience, scheduledAt, status } = req.body;

    const updatedNotification = await Notification.findByIdAndUpdate(
      req.params.id,
      { title, message, image, audience, scheduledAt, status },
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Notification updated successfully',
      data: { notification: updatedNotification }
    });
  } catch (error) {
    console.error('Update notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating notification'
    });
  }
});

// DELETE /api/admin/notifications/:id - Delete notification
router.delete('/:id', async (req, res) => {
  try {
    const notification = await Notification.findByIdAndDelete(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting notification'
    });
  }
});

// POST /api/admin/notifications/:id/send - Send notification
router.post('/:id/send', async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    if (notification.status === 'sent') {
      return res.status(400).json({
        success: false,
        message: 'Notification already sent'
      });
    }

    // Note: This is a database-backed notification system
    // In production, integrate with actual push service (FCM, OneSignal, etc.)
    notification.status = 'sent';
    notification.sentAt = new Date();
    notification.deliveryStats.delivered = notification.deliveryStats.total;
    await notification.save();

    res.status(200).json({
      success: true,
      message: 'Notification sent successfully (database-backed)',
      data: { notification }
    });
  } catch (error) {
    console.error('Send notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending notification'
    });
  }
});

module.exports = router;
