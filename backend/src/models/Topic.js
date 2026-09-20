const mongoose = require("mongoose");

const topicSchema = new mongoose.Schema(
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

    unitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Unit",
      required: true,
      index: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    completed: {
      type: Boolean,
      default: false,
    },

    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

/*
 * A topic name must be unique inside
 * the same user's subject + unit.
 */
topicSchema.index(
  {
    userId: 1,
    subjectId: 1,
    unitId: 1,
    name: 1,
  },
  {
    unique: true,
  }
);

module.exports =
  mongoose.model(
    "Topic",
    topicSchema
  );