const mongoose = require("mongoose");

const examHistorySchema =
  new mongoose.Schema(
    {
      academicYear: {
        type: Number,
        required: true,
        min: 1,
        max: 4,
      },

      assess1: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      assess2: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      endSem: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      recordedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      _id: false,
    }
  );

const examSchema =
  new mongoose.Schema(
    {
      assess1: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      assess2: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      endSem: {
        type: Number,
        min: 0,
        max: 100,
        default: null,
      },

      academicYear: {
        type: Number,
        min: 1,
        max: 4,
        default: 1,
      },
    },
    {
      _id: false,
    }
  );

const subjectSchema =
  new mongoose.Schema(
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
        index: true,
      },

      name: {
        type: String,
        required: true,
        trim: true,
      },

      code: {
        type: String,
        trim: true,
        default: "",
      },

      description: {
        type: String,
        trim: true,
        default: "",
      },

      exams: {
        type: examSchema,
        default: () => ({
          assess1: null,
          assess2: null,
          endSem: null,
          academicYear: 1,
        }),
      },

      examHistory: {
        type: [examHistorySchema],
        default: [],
      },
    },
    {
      timestamps: true,
    }
  );

subjectSchema.index(
  {
    userId: 1,
    name: 1,
  },
  {
    unique: true,
  }
);

module.exports =
  mongoose.model(
    "Subject",
    subjectSchema
  );