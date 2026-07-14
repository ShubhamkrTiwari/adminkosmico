const express = require('express');
const router = express.Router();
const { protect, adminOnly } = require('../middleware/auth');
const Settings = require('../models/Settings');

// GET /api/admin/maintenance/status
router.get('/status', async (req, res) => {
  try {
    const maintenance = await Settings.findOne({ key: 'maintenance_mode' });
    res.json({
      success: true,
      isMaintenanceMode: maintenance ? maintenance.value.isEnabled : false,
      message: maintenance ? maintenance.value.message : 'Server is under maintenance. Please try again later.'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/admin/maintenance/toggle
router.post('/toggle', protect, adminOnly, async (req, res) => {
  try {
    const { isMaintenanceMode, message } = req.body;

    await Settings.findOneAndUpdate(
      { key: 'maintenance_mode' },
      {
        value: {
          isEnabled: isMaintenanceMode,
          message: message
        }
      },
      { upsert: true, new: true }
    );

    res.json({
      success: true,
      message: 'Maintenance settings updated successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
