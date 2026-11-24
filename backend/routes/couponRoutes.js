const express = require('express');
const { protect, adminOnly } = require('../middleware/auth');
const Coupon = require('../models/Coupon');

const router = express.Router();

// GET all coupons (Publicly accessible for both apps)
router.get('/admin/list', async (req, res) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.json({ success: true, data: { coupons } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching coupons' });
  }
});

// Apply protection for admin operations
router.use(protect);
router.use(adminOnly);

// POST Create coupon
router.post('/admin/add-coupon', async (req, res) => {
  try {
    const { code, discountType, discountValue, minOrderAmount, validUntil, usageLimit, title } = req.body;

    const existing = await Coupon.findOne({ code: code.toUpperCase() });
    if (existing) return res.status(400).json({ success: false, message: 'Coupon code already exists' });

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountType,
      discountAmount: discountValue,
      minOrderAmount: minOrderAmount || 0,
      expiryDate: validUntil,
      usageLimit: usageLimit || 1000,
      description: title
    });

    res.status(201).json({ success: true, data: { coupon } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating coupon: ' + error.message });
  }
});

// PUT Update coupon
router.put('/update/:id', async (req, res) => {
  try {
    const { title, discountValue, minOrderAmount, validUntil, usageLimit } = req.body;

    const updateData = {};
    if (title) updateData.description = title;
    if (discountValue !== undefined) updateData.discountAmount = discountValue;
    if (minOrderAmount !== undefined) updateData.minOrderAmount = minOrderAmount;
    if (validUntil) updateData.expiryDate = validUntil;
    if (usageLimit !== undefined) updateData.usageLimit = usageLimit;

    const updated = await Coupon.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!updated) return res.status(404).json({ success: false, message: 'Coupon not found' });
    res.json({ success: true, data: { coupon: updated } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating coupon' });
  }
});

// DELETE Coupon
router.delete('/:id', async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });
    res.json({ message: 'Coupon removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting coupon' });
  }
});

// PATCH Toggle Status
router.patch('/toggle/:id', async (req, res) => {
    try {
      const coupon = await Coupon.findById(req.params.id);
      if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });

      coupon.isActive = !coupon.isActive;
      await coupon.save();

      res.json({
        success: true,
        message: `Coupon is now ${coupon.isActive ? 'Active' : 'Inactive'}`,
        isActive: coupon.isActive
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Error toggling coupon status' });
    }
  });

module.exports = router;
