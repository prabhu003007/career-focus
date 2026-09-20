const mongoose = require("mongoose");

const unitSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    subjectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subject",
      required: true,
      index: true,
    },

    unitNumber: {
      type: Number,
      required: true,
      min: 1,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

unitSchema.index(
  {
    userId: 1,
    subjectId: 1,
    unitNumber: 1,
  },
  {
    unique: true,
  }
);

unitSchema.index(
  {
    userId: 1,
    subjectId: 1,
    name: 1,
  },
  {
    unique: true,
  }
);

module.exports = mongoose.model(
  "Unit",
  unitSchema
);