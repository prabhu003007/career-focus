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
      enum: ["planned", "completed", "skipped"],
      default: "planned",
    },

    skippedFromDate: {
      type: String,
      default: null,
    },

    skipCount: {
      type: Number,
      default: 0,
    },

    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    _id: false,
  }
);

const aiRecommendationSchema =
  new mongoose.Schema(
    {
      topicId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Topic",
        required: true,
      },

      priority: {
        type: Number,
        min: 0,
        max: 100,
        required: true,
      },

      reason: {
        type: String,
        default: "",
      },
    },
    {
      _id: false,
    }
  );

const studyScheduleSchema =
  new mongoose.Schema(
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
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

      aiRecommendations: {
        type: [aiRecommendationSchema],
        default: [],
      },

      planningSource: {
        type: String,
        enum: [
          "llm+adaptive",
          "adaptive-fallback",
        ],
        default: "adaptive-fallback",
      },

      generatedAt: {
        type: Date,
        default: Date.now,
      },

      version: {
        type: Number,
        default: 1,
      },
    },
    {
      timestamps: true,
    }
  );

studyScheduleSchema.index({
  userId: 1,
  generatedAt: -1,
});

module.exports =
  mongoose.model(
    "StudySchedule",
    studyScheduleSchema
  );