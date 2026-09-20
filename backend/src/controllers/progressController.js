const Subject = require("../models/Subject");
const Topic = require("../models/Topic");
const StudyDay = require("../models/StudyDay");

const formatDate = (value) => {
  const date = new Date(value);

  const year = date.getFullYear();

  const month = String(
    date.getMonth() + 1
  ).padStart(2, "0");

  const day = String(
    date.getDate()
  ).padStart(2, "0");

  return `${year}-${month}-${day}`;
};

const percentage = (
  completed,
  planned
) => {
  if (!planned || planned <= 0) {
    return 0;
  }

  return Math.round(
    (completed / planned) * 100
  );
};

const getProgress = async (
  req,
  res
) => {
  try {
    const userId = req.userId;

    const [
      subjects,
      topics,
      studyDays,
    ] = await Promise.all([
      Subject.find({
        userId,
      })
        .sort({
          createdAt: 1,
        })
        .lean(),

      Topic.find({
        userId,
      })
        .sort({
          createdAt: 1,
        })
        .lean(),

      StudyDay.find({
        userId,
      })
        .sort({
          date: 1,
        })
        .lean(),
    ]);

    /*
     * ================================================
     * DAILY PERFORMANCE
     * ================================================
     */

    const dailyProgress =
      studyDays.map(
        (day) => ({
          type: "daily",

          date: day.date,

          planned:
            day.plannedTopics,

          completed:
            day.completedTopics,

          skipped:
            day.skippedTopics,

          percentage:
            day.performance,
        })
      );

    /*
     * Always give today's point if the user
     * has not started today's plan yet.
     */

    const today =
      formatDate(new Date());

    const hasToday =
      dailyProgress.some(
        (item) =>
          item.date === today
      );

    if (!hasToday) {
      dailyProgress.push({
        type: "daily",
        date: today,
        planned: 0,
        completed: 0,
        skipped: 0,
        percentage: 0,
      });
    }

    /*
     * ================================================
     * EXAM PERFORMANCE
     * ================================================
     */

    const examProgress =
      subjects.map(
        (subject) => ({
          type: "exam",

          date: formatDate(
            subject.updatedAt ||
              subject.createdAt ||
              new Date()
          ),

          subject:
            subject.name,

          assess1:
            subject.exams?.assess1 ??
            null,

          assess2:
            subject.exams?.assess2 ??
            null,

          endSem:
            subject.exams?.endSem ??
            null,
        })
      );

    /*
     * ================================================
     * SUBJECT IMPROVEMENT
     * ================================================
     */

    const subjectProgress = [];

    for (
      const subject of subjects
    ) {
      const subjectTopics =
        topics.filter(
          (topic) =>
            String(
              topic.subjectId
            ) ===
            String(
              subject._id
            )
        );

      const total =
        subjectTopics.length;

      if (total === 0) {
        subjectProgress.push({
          type: "subject",
          date: today,
          subject:
            subject.name,
          percentage: 0,
        });

        continue;
      }

      const completed =
        subjectTopics.filter(
          (topic) =>
            topic.completed ===
            true
        ).length;

      subjectProgress.push({
        type: "subject",
        date: today,
        subject:
          subject.name,
        percentage:
          percentage(
            completed,
            total
          ),
      });
    }

    /*
     * ================================================
     * RESPONSE
     * ================================================
     */

    return res.status(200).json({
      success: true,

      progress: [
        ...dailyProgress,
        ...examProgress,
        ...subjectProgress,
      ],

      summary: {
        dailyPerformance:
          dailyProgress,

        examPerformance:
          examProgress,

        subjectImprovement:
          subjectProgress,
      },
    });
  } catch (error) {
    console.error(
      "Get progress error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "Failed to load progress",
    });
  }
};

module.exports = {
  getProgress,
};