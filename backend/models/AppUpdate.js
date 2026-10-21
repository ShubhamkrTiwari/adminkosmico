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
    required: [true, 'Type is required']
  },
  notes: {
    type: String,
    trim: true
  },
  releaseNotes: {
    type: String,
    trim: true
  },
  playStoreUrl: {
    type: String,
    trim: true
  },
  isUpdateAvailable: {
    type: Boolean,
    default: true
  },
  publishStatus: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'published'
  },
  publishedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('AppUpdate', appUpdateSchema);
