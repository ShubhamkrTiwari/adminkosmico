const express = require('express');
const mongoose = require('mongoose');
const { protect, adminOnly } = require('../middleware/auth');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');

const router = express.Router();

// All routes are protected and admin-only
router.use(protect);
router.use(adminOnly);

// GET /api/admin/dashboard - Get dashboard statistics
router.get('/dashboard', async (req, res) => {
  try {
    const dbConnected = mongoose.connection.readyState === 1;

    if (!dbConnected) {
      return res.status(503).json({
        success: false,
        message: 'Database not connected'
      });
    }

    // Daily Stats Logic
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Run all queries in parallel for better performance
    const [
      totalRevenue,
      totalOrders,
      totalUsers,
      totalNotifications,
      statsToday,
      statsYesterday,
      recentOrders,
      lowStockProducts,
      salesData
    ] = await Promise.all([
      Order.aggregate([
        { $match: { status: 'delivered', paymentStatus: 'completed' } },
        { $group: { _id: null, total: { $sum: '$total' } } }
      ]),
      Order.countDocuments({ status: { $ne: 'cancelled' } }),
      User.countDocuments({ isAdmin: false }),
      mongoose.model('Notification').countDocuments(),
      Order.aggregate([
        {
          $match: {
            createdAt: { $gte: today, $lt: tomorrow },
            status: { $ne: 'cancelled' }
          }
        },
        {
          $group: {
            _id: null,
            count: { $sum: 1 },
            revenue: { $sum: { $cond: [{ $eq: ["$status", "delivered"] }, "$total", 0] } }
          }
        }
      ]),
      Order.aggregate([
        {
          $match: {
            createdAt: { $gte: yesterday, $lt: today },
            status: { $ne: 'cancelled' }
          }
        },
        {
          $group: {
            _id: null,
            count: { $sum: 1 },
            revenue: { $sum: { $cond: [{ $eq: ["$status", "delivered"] }, "$total", 0] } }
          }
        }
      ]),
      Order.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('user', 'name email')
        .select('user total createdAt status paymentStatus'),
      Product.find({ stock: { $lt: 10 } })
        .sort({ stock: 1 })
        .limit(5)
        .populate('category', 'name')
        .select('name stock category'),
      Order.aggregate([
        {
          $match: {
            status: 'delivered',
            createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
          }
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            total: { $sum: '$total' },
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } }
      ])
    ]);

    res.status(200).json({
      success: true,
      data: {
        stats: {
          totalRevenue: totalRevenue[0]?.total || 0,
          totalOrders,
          totalUsers,
          totalNotifications,
          ordersToday: statsToday[0]?.count || 0,
          revenueToday: statsToday[0]?.revenue || 0,
          ordersYesterday: statsYesterday[0]?.count || 0,
          revenueYesterday: statsYesterday[0]?.revenue || 0
        },
        recentOrders,
        lowStockProducts,
        salesData
      }
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard data'
    });
  }
});

module.exports = router;
