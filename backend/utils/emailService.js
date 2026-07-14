const nodemailer = require('nodemailer');

// Create transporter if email credentials are configured
let transporter = null;

if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
}

const sendOTPEmail = async (email, otp) => {
  if (transporter) {
    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || 'noreply@kosmicowellness.com',
        to: email,
        subject: 'Kosmico Wellness - Verify Your Email',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2d5a27;">Welcome to Kosmico Wellness</h2>
            <p>Your verification code is:</p>
            <div style="background: #f5f5f5; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; margin: 20px 0;">
              ${otp}
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
          </div>
        `
      };
      
      await transporter.sendMail(mailOptions);
      return { success: true, message: 'Email sent successfully' };
    } catch (error) {
      console.error('Email sending error:', error);
      return { success: false, message: 'Failed to send email' };
    }
  } else {
    // Development/mock mode - log OTP to console
    console.log('========================================');
    console.log('EMAIL SERVICE NOT CONFIGURED');
    console.log('OTP for', email, ':', otp);
    console.log('========================================');
    return { success: true, message: 'OTP logged (mock mode)' };
  }
};

module.exports = { sendOTPEmail };
