const Subject = require("../models/Subject");
const Topic = require("../models/Topic");
const StudySchedule = require("../models/StudySchedule");
const StudyDay = require("../models/StudyDay");

const {
  getAcademicInsight,
} = require("../services/llmService");

const getAcademicCopilot = async (req, res) => {
  try {
    const userId = req.userId;

    const question =
      req.body.question?.trim();

    if (!question) {
      return res.status(400).json({
        success: false,
        message:
          "Academic question is required.",
      });
    }

    if (question.length > 1200) {
      return res.status(400).json({
        success: false,
        message:
          "Question is too long.",
      });
    }

    const [
      subjects,
      topics,
      schedule,
      studyDays,
    ] = await Promise.all([
      Subject.find({ userId })
        .sort({ createdAt: 1 })
        .lean(),

      Topic.find({ userId })
        .sort({ createdAt: 1 })
        .lean(),

      StudySchedule.findOne({ userId })
        .sort({ generatedAt: -1 })
        .lean(),

      StudyDay.find({ userId })
        .sort({ date: 1 })
        .lean(),
    ]);

    const result =
      await getAcademicInsight({
        question,
        subjects,
        topics,
        schedule,
        progress: studyDays.map(
          (day) => ({
            date: day.date,
            planned: day.plannedTopics,
            completed:
              day.completedTopics,
            skipped:
              day.skippedTopics,
            percentage:
              day.performance,
          }),
        ),
      });

    return res.status(200).json({
      success: true,
      answer: result.answer,
      aiAvailable:
        result.aiAvailable,
      model: result.model ?? null,
    });
  } catch (error) {
    console.error(
      "Academic Copilot error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        "Academic Copilot could not process the request.",
    });
  }
};

module.exports = {
  getAcademicCopilot,
};