const express = require('express');
const { protect, adminOnly } = require('../middleware/auth');
const Coupon = require('../models/Coupon');

const router = express.Router();

// Apply protection
router.use(protect);

// GET all coupons (Admin only usually, or protected)
router.get('/', async (req, res) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.json({ success: true, data: { coupons } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching coupons' });
  }
});

// Admin only operations
router.use(adminOnly);

// POST Create coupon
router.post('/admin/add-coupon', async (req, res) => {
  try {
    const { code, discountType, discountAmount, minOrderAmount, expiryDate, usageLimit, description } = req.body;

    const existing = await Coupon.findOne({ code: code.toUpperCase() });
    if (existing) return res.status(400).json({ success: false, message: 'Coupon code already exists' });

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountType,
      discountAmount,
      minOrderAmount: minOrderAmount || 0,
      expiryDate,
      usageLimit: usageLimit || 1000,
      description
    });

    res.status(201).json({ success: true, data: { coupon } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating coupon: ' + error.message });
  }
});

// PUT Update coupon
router.put('/admin/update-coupon/:id', async (req, res) => {
  try {
    const updated = await Coupon.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updated) return res.status(404).json({ success: false, message: 'Coupon not found' });
    res.json({ success: true, data: { coupon: updated } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating coupon' });
  }
});

// DELETE Coupon
router.delete('/admin/delete-coupon/:id', async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });
    res.json({ success: true, message: 'Coupon deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting coupon' });
  }
});

// PATCH Toggle Status
router.patch('/admin/toggle-status/:id', async (req, res) => {
    try {
      const coupon = await Coupon.findById(req.params.id);
      if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });

      coupon.isActive = !coupon.isActive;
      await coupon.save();

      res.json({ success: true, data: { coupon } });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Error toggling coupon status' });
    }
  });

module.exports = router;
