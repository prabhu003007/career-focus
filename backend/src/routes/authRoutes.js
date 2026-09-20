const express = require("express");

const {
  sendVerification,
  verifyEmail,
  createPin,
  login,
  sendPinReset,
  verifyPinReset,
  resetPin,
} = require("../controllers/authController");

const authMiddleware = require("../middleware/authMiddleware");
const User = require("../models/User");

const router = express.Router();

// Registration
router.post("/send-verification", sendVerification);
router.post("/verify-email", verifyEmail);
router.post("/create-pin", createPin);

// Login
router.post("/login", login);

// Forgot PIN
router.post("/send-pin-reset", sendPinReset);
router.post("/verify-pin-reset", verifyPinReset);
router.post("/reset-pin", resetPin);

// Protected profile
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select(
      "-pinHash"
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        email: user.email,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error("Get profile error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to retrieve user",
    });
  }
});

module.exports = router;