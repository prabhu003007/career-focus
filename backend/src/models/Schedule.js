const mongoose = require("mongoose");

const assignmentSchema = new mongoose.Schema(
  {
    date: {
      type: String,
      required: true,
    },

    topicId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Topic",
      required: true,
    },

    subjectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subject",
      required: true,
    },

    status: {
      type: String,
      enum: ["planned", "completed", "skipped", "missed"],
      default: "planned",
    },

    skipCount: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const scheduleSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },

    startDate: {
      type: String,
      required: true,
    },

    deadline: {
      type: String,
      required: true,
    },

    assignments: {
      type: [assignmentSchema],
      default: [],
    },

    aiReasoning: {
      type: String,
      default: "",
    },

    version: {
      type: Number,
      default: 1,
    },

    generatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Schedule", scheduleSchema);