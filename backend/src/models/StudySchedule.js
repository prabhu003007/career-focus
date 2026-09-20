const mongoose = require("mongoose");

/*
 * =========================================================
 * SUBJECT PLAN
 * =========================================================
 */

const subjectPlanSchema = new mongoose.Schema(
  {
    subjectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subject",
      required: true,
    },

    startDate: {
      type: String,
      required: true,
    },

    deadline: {
      type: String,
      required: true,
    },

    units: [
      {
        unitId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Unit",
          required: true,
        },

        topicIds: [
          {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Topic",
          },
        ],
      },
    ],
  },
  {
    _id: false,
  }
);

/*
 * =========================================================
 * SCHEDULE ASSIGNMENT
 * =========================================================
 */

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

    unitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Unit",
      required: true,
    },

    subjectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subject",
      required: true,
    },

    status: {
      type: String,
      enum: [
        "planned",
        "completed",
        "skipped",
      ],
      default: "planned",
    },

    skippedFromDate: {
      type: String,
      default: null,
    },

    skipCount: {
      type: Number,
      default: 0,
      min: 0,
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

/*
 * =========================================================
 * STUDY SCHEDULE
 * =========================================================
 */

const studyScheduleSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    /*
     * Each subject has its own planning window.
     */
    subjects: {
      type: [subjectPlanSchema],
      default: [],
    },

    /*
     * Active and historical assignment records.
     */
    assignments: {
      type: [assignmentSchema],
      default: [],
    },

    /*
     * Scheduling explanation.
     */
    reasoning: {
      type: String,
      default: "",
    },

    /*
     * How the schedule was produced.
     */
    planningSource: {
      type: String,
      enum: [
        "llm",
        "llm+repair",
        "adaptive-fallback",
      ],
      default: "adaptive-fallback",
    },

    version: {
      type: Number,
      default: 1,
      min: 1,
    },

    generatedAt: {
      type: Date,
      default: Date.now,
    },

    lastRescheduledAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

/*
 * Exactly ONE active study plan per user.
 */
studyScheduleSchema.index(
  {
    userId: 1,
  },
  {
    unique: true,
  }
);

/*
 * Schedule retrieval.
 */
studyScheduleSchema.index({
  userId: 1,
  generatedAt: -1,
});

/*
 * Active assignment lookup.
 */
studyScheduleSchema.index({
  userId: 1,
  "assignments.date": 1,
  "assignments.status": 1,
});

module.exports = mongoose.model(
  "StudySchedule",
  studyScheduleSchema
);