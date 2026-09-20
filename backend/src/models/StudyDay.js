const mongoose = require("mongoose");

const studyDaySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    date: {
      type: String,
      required: true,
    },

    plannedTopics: {
      type: Number,
      default: 0,
      min: 0,
    },

    completedTopics: {
      type: Number,
      default: 0,
      min: 0,
    },

    skippedTopics: {
      type: Number,
      default: 0,
      min: 0,
    },

    performance: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    subjectIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Subject",
      },
    ],
  },
  {
    timestamps: true,
  }
);

studyDaySchema.index(
  {
    userId: 1,
    date: 1,
  },
  {
    unique: true,
  }
);

module.exports =
  mongoose.model(
    "StudyDay",
    studyDaySchema
  );