const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true
  },
  slug: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: [true, 'Category is required']
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
  },
  originalPrice: {
    type: Number,
    min: [0, 'Original price cannot be negative']
  },
  stock: {
    type: Number,
    required: [true, 'Stock is required'],
    min: [0, 'Stock cannot be negative'],
    default: 0
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true
  },
  ingredients: {
    type: mongoose.Schema.Types.Mixed,
    default: ''
  },
  productLink: {
    type: String,
    trim: true,
    default: ''
  },
  visibility: {
    type: Boolean,
    default: true
  },
  image: {
    type: String,
    default: ''
  },
  images: [{
    type: String
  }],
  keyBenefits: [String],
  highlights: [String],
  brand: {
    type: String,
    trim: true
  },
  sku: {
    type: String,
    trim: true
  },
  shelfLife: {
    type: String,
    trim: true
  },
  madeIn: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Pre-save hook to generate unique slug
productSchema.pre('save', function(next) {
  if (this.isModified('name') || !this.slug) {
    const baseSlug = this.name.toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/-+/g, '-');
    this.slug = `${baseSlug}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  }
  next();
});

module.exports = mongoose.model('Product', productSchema);
