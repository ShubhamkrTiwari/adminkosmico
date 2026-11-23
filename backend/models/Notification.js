const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true
  },
  message: {
    type: String,
    required: [true, 'Message is required'],
    trim: true
  },
  image: {
    type: String,
    default: ''
  },
  icon: {
    type: String,
    default: '🔔'
  },
  type: {
    type: String,
    default: 'general'
  },
  category: {
    type: String,
    default: 'General'
  },
  audience: {
    type: String,
    default: 'all'
  },
  user: {
    type: String,
    default: ''
  },
  scheduledAt: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    default: 'sent'
  },
  sentAt: {
    type: Date,
    default: Date.now
  },
  deliveryStats: {
    total: { type: Number, default: 0 },
    delivered: { type: Number, default: 0 },
    failed: { type: Number, default: 0 }
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Notification', notificationSchema);
