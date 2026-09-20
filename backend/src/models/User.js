const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },

    emailVerified: {
      type: Boolean,
      default: false,
    },

    pinHash: {
      type: String,
      required: false,
    },

    // =========================================================
    // ACADEMIC PROFILE
    // =========================================================

    name: {
      type: String,
      trim: true,
      default: "",
    },

    collegeName: {
      type: String,
      trim: true,
      default: "",
    },

    degree: {
      type: String,
      trim: true,
      default: "",
    },

    course: {
      type: String,
      trim: true,
      default: "",
    },

    academicYear: {
      type: Number,
      min: 1,
      max: 4,
      default: 1,
    },

    profileCompleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "User",
  userSchema
);