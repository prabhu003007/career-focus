const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

const User = require("../models/User");
const VerificationCode = require("../models/VerificationCode");

const generateCode = () => {
  return crypto.randomInt(100000, 1000000).toString();
};

const hashCode = (code) => {
  return crypto
    .createHash("sha256")
    .update(code)
    .digest("hex");
};

const createVerificationToken = (user) => {
  return jwt.sign(
    {
      userId: user._id.toString(),
      email: user.email,
      purpose: "EMAIL_VERIFICATION",
    },
    process.env.JWT_SECRET,
    {
      expiresIn: "15m",
    }
  );
};

// ============================================================
// SEND EMAIL VERIFICATION
// ============================================================

const sendVerification = async (req, res) => {
  try {
    const email =
      req.body.email?.trim().toLowerCase();

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    let user = await User.findOne({
      email,
    });

    /*
     * IMPORTANT:
     *
     * A user without a PIN is an incomplete
     * registration, not a fully registered account.
     *
     * Therefore we allow the same email to
     * resume registration.
     */
    if (user && user.pinHash) {
      return res.status(409).json({
        success: false,
        message: "User already exists",
      });
    }

    /*
     * If an incomplete user already exists,
     * reuse that user.
     *
     * If no user exists, create a pending user.
     */
    if (!user) {
      user = await User.create({
        email,
        emailVerified: false,
        pinHash: undefined,
        profileCompleted: false,
      });
    }

    const code = generateCode();

    const codeHash = hashCode(code);

    await VerificationCode.deleteMany({
      email,
      purpose: "EMAIL_VERIFICATION",
    });

    await VerificationCode.create({
      email,
      codeHash,
      purpose: "EMAIL_VERIFICATION",
      expiresAt:
        new Date(
          Date.now() +
            10 * 60 * 1000
        ),
      attempts: 0,
    });

    /*
     * Development mode.
     *
     * Later this can use emailService.
     */
    console.log(
      `Email verification code for ${email}: ${code}`
    );

    res.json({
      success: true,
      message:
        "Verification code sent successfully",
      registrationPending:
        true,
    });
  } catch (error) {
    console.error(
      "Send verification error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to send verification code",
    });
  }
};

// ============================================================
// VERIFY EMAIL
// ============================================================

const verifyEmail = async (
  req,
  res
) => {
  try {
    const email =
      req.body.email
        ?.trim()
        .toLowerCase();

    const code =
      req.body.code?.trim();

    if (!email || !code) {
      return res.status(400).json({
        success: false,
        message:
          "Email and verification code are required",
      });
    }

    const record =
      await VerificationCode.findOne({
        email,
        purpose:
          "EMAIL_VERIFICATION",
      }).sort({
        createdAt: -1,
      });

    if (!record) {
      return res.status(400).json({
        success: false,
        message:
          "Verification code not found. Please request a new code.",
      });
    }

    if (
      record.expiresAt <
      new Date()
    ) {
      await record.deleteOne();

      return res.status(400).json({
        success: false,
        message:
          "Verification code expired. Please request a new code.",
      });
    }

    if (record.attempts >= 5) {
      await record.deleteOne();

      return res.status(429).json({
        success: false,
        message:
          "Too many attempts. Please request a new code.",
      });
    }

    record.attempts += 1;

    await record.save();

    if (
      hashCode(code) !==
      record.codeHash
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid verification code",
      });
    }

    /*
     * Find the pending account.
     */
    const user =
      await User.findOne({
        email,
      });

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          "Registration session not found. Please start again.",
      });
    }

    /*
     * Mark email as verified.
     */
    user.emailVerified = true;

    await user.save();

    /*
     * Verification codes are ONE-TIME.
     */
    await record.deleteOne();

    /*
     * Short-lived token used ONLY to
     * authorize PIN creation.
     */
    const verificationToken =
      createVerificationToken(
        user
      );

    res.json({
      success: true,
      message:
        "Email verified successfully",

      verificationToken,

      registrationState: {
        emailVerified: true,
        pinCreated:
          Boolean(user.pinHash),
        profileCompleted:
          Boolean(
            user.profileCompleted
          ),
      },
    });
  } catch (error) {
    console.error(
      "Verify email error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to verify email",
    });
  }
};

// ============================================================
// CREATE PIN
// ============================================================

const createPin = async (
  req,
  res
) => {
  try {
    const email =
      req.body.email
        ?.trim()
        .toLowerCase();

    const pin = req.body.pin;

    const verificationToken =
      req.body
        .verificationToken;

    if (
      !email ||
      !pin ||
      !verificationToken
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Email, verification token and PIN are required",
      });
    }

    if (!/^\d{4}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message:
          "PIN must contain exactly 4 digits",
      });
    }

    /*
     * Verify the email-verification
     * authorization token.
     */
    let decoded;

    try {
      decoded = jwt.verify(
        verificationToken,
        process.env.JWT_SECRET
      );
    } catch (error) {
      return res.status(401).json({
        success: false,
        message:
          "Email verification authorization expired. Please verify your email again.",
      });
    }

    if (
      decoded.purpose !==
      "EMAIL_VERIFICATION"
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid email verification authorization",
      });
    }

    if (
      decoded.email !== email
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Email does not match verification authorization",
      });
    }

    const user =
      await User.findOne({
        _id: decoded.userId,
        email,
      });

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          "Registration account not found",
      });
    }

    if (!user.emailVerified) {
      return res.status(403).json({
        success: false,
        message:
          "Email is not verified",
      });
    }

    /*
     * Do not silently overwrite an existing PIN.
     */
    if (user.pinHash) {
      return res.status(409).json({
        success: false,
        message:
          "PIN already exists. Please sign in instead.",
      });
    }

    user.pinHash =
      await bcrypt.hash(
        pin,
        12
      );

    await user.save();

    res.json({
      success: true,
      message:
        "PIN created successfully",

      registrationState: {
        emailVerified: true,
        pinCreated: true,
        profileCompleted:
          Boolean(
            user.profileCompleted
          ),
      },
    });
  } catch (error) {
    console.error(
      "Create PIN error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to create PIN",
    });
  }
};

// ============================================================
// LOGIN
// ============================================================

const login = async (
  req,
  res
) => {
  try {
    const email =
      req.body.email
        ?.trim()
        .toLowerCase();

    const pin = req.body.pin;

    if (!email || !pin) {
      return res.status(400).json({
        success: false,
        message:
          "Email and PIN are required",
      });
    }

    const user =
      await User.findOne({
        email,
      });

    /*
     * This also protects incomplete
     * registrations.
     */
    if (
      !user ||
      !user.pinHash
    ) {
      return res.status(401).json({
        success: false,
        message:
          "PIN has not been created for this account",
      });
    }

    if (!user.emailVerified) {
      return res.status(403).json({
        success: false,
        message:
          "Email is not verified",
      });
    }

    const validPin =
      await bcrypt.compare(
        pin,
        user.pinHash
      );

    if (!validPin) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid email or PIN",
      });
    }

    const token =
      jwt.sign(
        {
          userId:
            user._id.toString(),
        },
        process.env.JWT_SECRET,
        {
          expiresIn: "7d",
        }
      );

    res.json({
      success: true,
      message:
        "Login successful",

      token,

      user: {
        id: user._id,
        email: user.email,
        name: user.name || "",
        profileCompleted:
          Boolean(
            user.profileCompleted
          ),
        academicYear:
          user.academicYear || 1,
      },
    });
  } catch (error) {
    console.error(
      "Login error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to login",
    });
  }
};

// ============================================================
// PIN RESET
// ============================================================

const sendPinReset = async (
  req,
  res
) => {
  try {
    const email =
      req.body.email
        ?.trim()
        .toLowerCase();

    if (!email) {
      return res.status(400).json({
        success: false,
        message:
          "Email is required",
      });
    }

    const user =
      await User.findOne({
        email,
        emailVerified: true,
      });

    if (
      !user ||
      !user.pinHash
    ) {
      return res.status(404).json({
        success: false,
        message:
          "No completed account found",
      });
    }

    const code =
      generateCode();

    const codeHash =
      hashCode(code);

    await VerificationCode.deleteMany({
      email,
      purpose: "PIN_RESET",
    });

    await VerificationCode.create({
      email,
      codeHash,
      purpose: "PIN_RESET",
      expiresAt:
        new Date(
          Date.now() +
            10 * 60 * 1000
        ),
      attempts: 0,
    });

    console.log(
      `DEV PIN RESET CODE for ${email}: ${code}`
    );

    res.json({
      success: true,
      message:
        "PIN reset code generated",
    });
  } catch (error) {
    console.error(
      "Send PIN reset error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to generate PIN reset code",
    });
  }
};

const verifyPinReset = async (
  req,
  res
) => {
  try {
    const email =
      req.body.email
        ?.trim()
        .toLowerCase();

    const code =
      req.body.code?.trim();

    if (!email || !code) {
      return res.status(400).json({
        success: false,
        message:
          "Email and verification code are required",
      });
    }

    const record =
      await VerificationCode.findOne({
        email,
        purpose: "PIN_RESET",
      }).sort({
        createdAt: -1,
      });

    if (!record) {
      return res.status(400).json({
        success: false,
        message:
          "Reset code not found",
      });
    }

    if (
      record.expiresAt <
      new Date()
    ) {
      await record.deleteOne();

      return res.status(400).json({
        success: false,
        message:
          "Reset code expired",
      });
    }

    if (record.attempts >= 5) {
      await record.deleteOne();

      return res.status(429).json({
        success: false,
        message:
          "Too many attempts",
      });
    }

    record.attempts += 1;

    await record.save();

    if (
      hashCode(code) !==
      record.codeHash
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid reset code",
      });
    }

    const user =
      await User.findOne({
        email,
        emailVerified: true,
        pinHash: {
          $exists: true,
          $ne: null,
        },
      });

    if (!user) {
      await record.deleteOne();

      return res.status(404).json({
        success: false,
        message:
          "Completed account not found",
      });
    }

    const resetToken =
      jwt.sign(
        {
          userId:
            user._id.toString(),
          email: user.email,
          purpose: "PIN_RESET",
        },
        process.env.JWT_SECRET,
        {
          expiresIn: "10m",
        }
      );

    await record.deleteOne();

    res.json({
      success: true,
      message:
        "Reset code verified successfully",
      resetToken,
    });
  } catch (error) {
    console.error(
      "Verify PIN reset error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to verify reset code",
    });
  }
};

const resetPin = async (
  req,
  res
) => {
  try {
    const resetToken =
      req.body.resetToken;

    const pin = req.body.pin;

    if (!resetToken || !pin) {
      return res.status(400).json({
        success: false,
        message:
          "Reset token and PIN are required",
      });
    }

    if (!/^\d{4}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message:
          "PIN must contain exactly 4 digits",
      });
    }

    let decoded;

    try {
      decoded = jwt.verify(
        resetToken,
        process.env.JWT_SECRET
      );
    } catch (error) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid or expired reset authorization",
      });
    }

    if (
      decoded.purpose !==
      "PIN_RESET"
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid reset authorization",
      });
    }

    const user =
      await User.findById(
        decoded.userId
      );

    if (
      !user ||
      !user.emailVerified ||
      !user.pinHash
    ) {
      return res.status(404).json({
        success: false,
        message:
          "Completed account not found",
      });
    }

    if (
      user.email !==
      decoded.email
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid reset authorization",
      });
    }

    user.pinHash =
      await bcrypt.hash(
        pin,
        12
      );

    await user.save();

    res.json({
      success: true,
      message:
        "PIN reset successfully",
    });
  } catch (error) {
    console.error(
      "Reset PIN error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to reset PIN",
    });
  }
};

module.exports = {
  sendVerification,
  verifyEmail,
  createPin,
  login,
  sendPinReset,
  verifyPinReset,
  resetPin,
};