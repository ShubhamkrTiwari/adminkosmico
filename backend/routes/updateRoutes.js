const express = require('express');
const { body, validationResult } = require('express-validator');
const { protect, adminOnly } = require('../middleware/auth');
const AppUpdate = require('../models/AppUpdate');
const AppConfig = require('../models/AppConfig');

const router = express.Router();

// --- PUBLIC ROUTES (for client user apps to check for updates) ---
router.get('/check', async (req, res) => {
  try {
    const clientVersion = req.query.version; // e.g., "1.0.0"
    const platform = (req.query.platform || 'android').toLowerCase();

    // Check AppConfig toggle for this platform (fall back to android if platform not found)
    let config = await AppConfig.findOne({ platform });
    if (!config) {
      config = await AppConfig.findOne({ platform: 'android' });
    }

    const isActive = config ? (config.is_active !== undefined ? config.is_active : config.show_update_message) : false;

    if (config && isActive === false) {
      return res.json({
        success: true,
        update_required: false,
        isUpdateAvailable: false,
        updateAvailable: false,
        update: null
      });
    }

    const latestUpdate = await AppUpdate.findOne({
      publishStatus: 'published'
    }).sort({ createdAt: -1 });

    if (!latestUpdate || latestUpdate.isUpdateAvailable === false || (config && isActive === false)) {
      return res.json({
        success: true,
        update_required: false,
        isUpdateAvailable: false,
        updateAvailable: false,
        update: null
      });
    }

    let updateNeeded = true;
    if (clientVersion) {
      updateNeeded = compareVersions(latestUpdate.version, clientVersion) > 0;
    }

    const shouldUpdate = updateNeeded && latestUpdate.isUpdateAvailable;

    if (!shouldUpdate) {
      return res.json({
        success: true,
        update_required: false,
        isUpdateAvailable: false,
        updateAvailable: false,
        update: null
      });
    }

    res.json({
      success: true,
      update_required: true,
      isUpdateAvailable: true,
      updateAvailable: true,
      message: latestUpdate.releaseNotes || latestUpdate.notes || 'A new version of the app is available. Please update.',
      playstore_url: latestUpdate.playStoreUrl || (config ? config.playstore_url : 'https://play.google.com/store/apps/details?id=com.kosmico.wellness'),
      update: {
        isUpdateAvailable: latestUpdate.isUpdateAvailable,
        title: latestUpdate.title,
        version: latestUpdate.version,
        type: latestUpdate.type,
        releaseNotes: latestUpdate.releaseNotes || latestUpdate.notes,
        playStoreUrl: latestUpdate.playStoreUrl || (config ? config.playstore_url : 'https://play.google.com/store/apps/details?id=com.kosmico.wellness'),
        publishedAt: latestUpdate.publishedAt || latestUpdate.createdAt
      }
    });
  } catch (error) {
    console.error('Check update error:', error);
    res.status(500).json({ success: false, message: 'Error checking update' });
  }
});

function compareVersions(v1, v2) {
  const parts1 = v1.replace(/^v/, '').split('.').map(Number);
  const parts2 = v2.replace(/^v/, '').split('.').map(Number);

  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const num1 = parts1[i] || 0;
    const num2 = parts2[i] || 0;
    if (num1 > num2) return 1;
    if (num1 < num2) return -1;
  }
  return 0;
}

// --- PROTECTED ADMIN ROUTES ---
router.use(protect);
router.use(adminOnly);

// GET /api/admin/updates - Get current active app update
router.get('/', async (req, res) => {
  try {
    const update = await AppUpdate.findOne().sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      update: update || null
    });
  } catch (error) {
    console.error('Get update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching update'
    });
  }
});

// GET /api/admin/updates/:id - Get single update
router.get('/:id', async (req, res) => {
  try {
    const update = await AppUpdate.findById(req.params.id);
    res.status(200).json({
      success: true,
      update: update || null
    });
  } catch (error) {
    console.error('Get update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching update'
    });
  }
});

// POST /api/admin/updates - Create new update or toggle isUpdateAvailable
router.post('/', async (req, res) => {
  try {
    const { title, version, type, notes, releaseNotes, playStoreUrl, isUpdateAvailable, publishStatus } = req.body;

    // If it's a toggle request (only isUpdateAvailable is provided without title/version)
    if (!title && !version && isUpdateAvailable !== undefined) {
      let update = await AppUpdate.findOne().sort({ createdAt: -1 });
      if (!update) {
        return res.status(404).json({
          success: false,
          message: 'Update not found'
        });
      }
      update.isUpdateAvailable = isUpdateAvailable;
      await update.save();
      return res.status(200).json({
        success: true,
        message: 'Update status updated successfully',
        update
      });
    }

    if (!title || !version || !type) {
      return res.status(400).json({
        success: false,
        message: 'Title, version, and type are required'
      });
    }

    // Remove old updates so only one active update exists
    await AppUpdate.deleteMany({});

    const update = await AppUpdate.create({
      title,
      version,
      type,
      notes: notes || releaseNotes || '',
      releaseNotes: releaseNotes || notes || '',
      playStoreUrl: playStoreUrl || 'https://play.google.com/store/apps/details?id=com.kosmico.wellness',
      isUpdateAvailable: isUpdateAvailable !== undefined ? isUpdateAvailable : true,
      publishStatus: publishStatus || 'published',
      publishedAt: new Date()
    });

    res.status(201).json({
      success: true,
      message: `App update v${version} published successfully`,
      update: {
        isUpdateAvailable: update.isUpdateAvailable,
        title: update.title,
        version: update.version,
        type: update.type,
        releaseNotes: update.releaseNotes || update.notes,
        playStoreUrl: update.playStoreUrl,
        publishedAt: update.publishedAt
      }
    });
  } catch (error) {
    console.error('Create/toggle update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing update'
    });
  }
});

// PUT /api/admin/updates - Update latest update (no ID required)
router.put('/', async (req, res) => {
  try {
    const update = await AppUpdate.findOne().sort({ createdAt: -1 });
    if (!update) {
      return res.status(404).json({
        success: false,
        message: 'Update not found'
      });
    }

    const { title, version, type, notes, releaseNotes, playStoreUrl, isUpdateAvailable, publishStatus } = req.body;

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (version !== undefined) updateData.version = version;
    if (type !== undefined) updateData.type = type;
    if (notes !== undefined) updateData.notes = notes;
    if (releaseNotes !== undefined) updateData.releaseNotes = releaseNotes;
    if (playStoreUrl !== undefined) updateData.playStoreUrl = playStoreUrl;
    if (isUpdateAvailable !== undefined) updateData.isUpdateAvailable = isUpdateAvailable;
    if (publishStatus !== undefined) updateData.publishStatus = publishStatus;

    if (publishStatus === 'published' && !update.publishedAt) {
      updateData.publishedAt = new Date();
    }

    const updatedUpdate = await AppUpdate.findByIdAndUpdate(
      update._id,
      updateData,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Update updated successfully',
      update: updatedUpdate
    });
  } catch (error) {
    console.error('Update update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating update'
    });
  }
});

// PUT /api/admin/updates/:id - Update update status / details
router.put('/:id', async (req, res) => {
  try {
    let update;
    if (req.params.id && req.params.id !== 'undefined') {
      update = await AppUpdate.findById(req.params.id);
    }
    if (!update) {
      update = await AppUpdate.findOne().sort({ createdAt: -1 });
    }

    if (!update) {
      return res.status(404).json({
        success: false,
        message: 'Update not found'
      });
    }

    const { title, version, type, notes, releaseNotes, playStoreUrl, isUpdateAvailable, publishStatus } = req.body;

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (version !== undefined) updateData.version = version;
    if (type !== undefined) updateData.type = type;
    if (notes !== undefined) updateData.notes = notes;
    if (releaseNotes !== undefined) updateData.releaseNotes = releaseNotes;
    if (playStoreUrl !== undefined) updateData.playStoreUrl = playStoreUrl;
    if (isUpdateAvailable !== undefined) updateData.isUpdateAvailable = isUpdateAvailable;
    if (publishStatus !== undefined) updateData.publishStatus = publishStatus;

    if (publishStatus === 'published' && !update.publishedAt) {
      updateData.publishedAt = new Date();
    }

    const updatedUpdate = await AppUpdate.findByIdAndUpdate(
      update._id,
      updateData,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Update updated successfully',
      update: updatedUpdate
    });
  } catch (error) {
    console.error('Update update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating update'
    });
  }
});

// DELETE /api/admin/updates - Remove active update
router.delete('/', async (req, res) => {
  try {
    await AppUpdate.deleteMany({});
    res.status(200).json({
      success: true,
      message: 'Active app update has been removed successfully'
    });
  } catch (error) {
    console.error('Delete update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting update'
    });
  }
});

// DELETE /api/admin/updates/:id - Remove update by id
router.delete('/:id', async (req, res) => {
  try {
    if (req.params.id && req.params.id !== 'undefined') {
      await AppUpdate.findByIdAndDelete(req.params.id);
    }
    await AppUpdate.deleteMany({});
    res.status(200).json({
      success: true,
      message: 'Active app update is removed successfully'
    });
  } catch (error) {
    console.error('Delete update error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting update'
    });
  }
});

module.exports = router;
