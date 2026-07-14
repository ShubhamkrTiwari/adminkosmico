const express = require('express');
const { protect, adminOnly } = require('../middleware/auth');
const Order = require('../models/Order');

const router = express.Router();

router.use(protect);
router.use(adminOnly);

// GET /api/admin/payments - Get all payment records
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status || '';
    const method = req.query.method || '';
    const startDate = req.query.startDate || '';
    const endDate = req.query.endDate || '';
    const sortBy = req.query.sortBy || 'createdAt';
    const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;

    const query = {};
    if (status) {
      query.paymentStatus = status;
    }
    if (method) {
      query.paymentMethod = method;
    }
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate);
      }
    }

    const orders = await Order.find(query)
      .populate('user', 'name email')
      .select('user total paymentMethod paymentStatus razorpayOrderId paymentId createdAt')
      .sort({ [sortBy]: sortOrder })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Order.countDocuments(query);

    // Format as payment records
    const payments = orders.map(order => ({
      transactionId: order._id,
      customer: order.user,
      amount: order.total,
      method: order.paymentMethod,
      paymentId: order.paymentId,
      razorpayOrderId: order.razorpayOrderId,
      status: order.paymentStatus,
      date: order.createdAt
    }));

    res.status(200).json({
      success: true,
      data: {
        payments,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get payments error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching payments'
    });
  }
});

module.exports = router;
