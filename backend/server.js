require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads')); // Serve uploaded files

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/kosmico-wellness');
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

connectDB();

// Routes
app.use('/api/admin', require('./routes/authRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/admin/products', require('./routes/productRoutes'));
app.use('/api/products', require('./routes/productRoutes')); // Added to support /api/products/...
app.use('/api/admin/categories', require('./routes/categoryRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes')); // Added to support /api/categories/...
app.use('/api/admin/orders', require('./routes/orderRoutes'));
app.use('/api/admin/users', require('./routes/userRoutes'));
app.use('/api/admin/notifications', require('./routes/notificationRoutes'));
app.use('/api/admin/payments', require('./routes/paymentRoutes'));
app.use('/api/admin/updates', require('./routes/updateRoutes'));
app.use('/api/admin/maintenance', require('./routes/maintenanceRoutes'));
app.use('/api/admin/coupons', require('./routes/couponRoutes'));
app.use('/api/coupons', require('./routes/couponRoutes')); // Public access
app.use('/api/admin/upload', require('./routes/uploadRoutes')); // Add this line

// Health check
app.get('/api/health', (req, res) => {
  const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  res.json({ 
    status: 'ok', 
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
