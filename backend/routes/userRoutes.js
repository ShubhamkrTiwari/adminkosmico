const express = require('express');
const { protect, adminOnly } = require('../middleware/auth');
const User = require('../models/User');
const Order = require('../models/Order');

const router = express.Router();

router.use(protect);
router.use(adminOnly);

// GET /api/admin/users - Get all users/admins
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    const status = req.query.status || '';
    const role = req.query.role || ''; // 'admin' or 'user'
    const sortBy = req.query.sortBy || 'createdAt';
    const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;

    const query = {};

    if (role === 'admin') {
      query.isAdmin = true;
    } else if (role === 'user') {
      query.isAdmin = false;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }

    if (status) {
      query.accountStatus = status;
    }

    const users = await User.find(query)
      .select('-password -otp')
      .sort({ [sortBy]: sortOrder })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        users,
        pagination: { page, limit, total, pages: Math.ceil(total / limit) }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, message: 'Error fetching users' });
  }
});

// GET /api/admin/users/:id - Get single user
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password -otp');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const orders = await Order.find({ user: req.params.id }).sort({ createdAt: -1 }).limit(10);
    const orderCount = await Order.countDocuments({ user: req.params.id });
    const totalSpend = await Order.aggregate([
      { $match: { user: user._id, paymentStatus: 'completed', status: { $ne: 'cancelled' } } },
      { $group: { _id: null, total: { $sum: '$total' } } }
    ]);

    res.status(200).json({
      success: true,
      data: {
        user,
        orders,
        stats: { orderCount, totalSpend: totalSpend[0]?.total || 0 }
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching user' });
  }
});

// PUT /api/admin/users/:id - Update user/admin details
router.put('/:id', async (req, res) => {
  try {
    const { name, email, phone, isAdmin, accountStatus } = req.body;
    const user = await User.findById(req.params.id);
    
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    // Update fields
    if (name) user.name = name;
    if (email) user.email = email;
    if (phone) user.phone = phone;
    if (isAdmin !== undefined) user.isAdmin = isAdmin;
    if (accountStatus) user.accountStatus = accountStatus;

    await user.save();

    res.status(200).json({
      success: true,
      message: 'User updated successfully',
      data: { user: user.toJSON() }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ success: false, message: 'Error updating user' });
  }
});

// PUT /api/admin/users/:id/status - Update status (Legacy/Short-hand)
router.put('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const user = await User.findByIdAndUpdate(req.params.id, { accountStatus: status }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.status(200).json({ success: true, message: 'Status updated', data: { user } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating status' });
  }
});

// DELETE /api/admin/users/:id - Delete user/admin
router.delete('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    // Prevent self-deletion
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ success: false, message: 'Cannot delete your own account' });
    }

    await User.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting user' });
  }
});

module.exports = router;
