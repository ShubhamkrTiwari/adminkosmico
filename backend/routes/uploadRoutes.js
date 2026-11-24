const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { protect, adminOnly } = require('../middleware/auth');

const os = require('os');

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    try {
      const uploadDir = path.join(process.cwd(), 'uploads', 'products');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }
      cb(null, uploadDir);
    } catch (dirErr) {
      console.error('Directory creation fallback error:', dirErr);
      const tempDir = os.tmpdir();
      cb(null, tempDir);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'product-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|webp/;
    const mimetype = filetypes.test(file.mimetype);
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Only images (jpg, jpeg, png, webp) are allowed!'));
  }
});

const handleUpload = (req, res) => {
  const uploadMiddleware = upload.fields([
    { name: 'image', maxCount: 1 },
    { name: 'imageFile', maxCount: 1 },
    { name: 'file', maxCount: 1 },
    { name: 'productImage', maxCount: 1 }
  ]);

  uploadMiddleware(req, res, (err) => {
    if (err) {
      console.error('Multer / Upload error:', err);
      return res.status(400).json({ success: false, message: err.message || 'Upload error' });
    }

    const file = req.files?.image?.[0] || req.files?.imageFile?.[0] || req.files?.file?.[0] || req.files?.productImage?.[0] || req.file;

    if (!file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    const imageUrl = `/uploads/products/${file.filename}`;
    res.status(200).json({
      success: true,
      message: 'Image uploaded successfully',
      url: imageUrl,
      imageUrl: imageUrl
    });
  });
};

router.post('/product-image', protect, adminOnly, handleUpload);
router.post('/admin/product-image', protect, adminOnly, handleUpload);
router.post('/', protect, adminOnly, handleUpload);

module.exports = router;
