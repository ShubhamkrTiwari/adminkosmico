const mongoose = require('mongoose');

const appUpdateSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true
  },
  version: {
    type: String,
    required: [true, 'Version is required'],
    trim: true
  },
  type: {
    type: String,
    enum: ['feature', 'fix', 'patch', 'maintenance'],
    required: [true, 'Type is required']
  },
  notes: {
    type: String,
    required: [true, 'Notes are required'],
    trim: true
  },
  publishStatus: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'draft'
  },
  publishedAt: {
    type: Date
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('AppUpdate', appUpdateSchema);
