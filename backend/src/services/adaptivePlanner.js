const calculatePerformance =
  (subject) => {
    const marks = [
      subject.exams?.assess1,
      subject.exams?.assess2,
      subject.exams?.endSem,
    ].filter(
      (mark) =>
        mark !== null &&
        mark !== undefined
    );

    if (marks.length === 0) {
      return null;
    }

    return (
      marks.reduce(
        (sum, mark) =>
          sum + Number(mark),
        0
      ) / marks.length
    );
  };

const fallbackPriority = ({
  topic,
  subject,
  remainingDays,
}) => {
  let score = 40;

  const performance =
    calculatePerformance(
      subject
    );

  /*
   * Academic performance.
   *
   * Lower performance means greater
   * priority.
   */

  if (performance !== null) {
    score +=
      (100 - performance) *
      0.55;
  }

  /*
   * Deadline pressure.
   */

  if (remainingDays <= 2) {
    score += 30;
  } else if (
    remainingDays <= 5
  ) {
    score += 20;
  } else if (
    remainingDays <= 10
  ) {
    score += 10;
  }

  /*
   * Every unfinished topic receives
   * baseline priority.
   */

  if (!topic.completed) {
    score += 10;
  }

  return Math.max(
    0,
    Math.min(
      100,
      Math.round(score)
    )
  );
};

const buildPrioritizedTopics = ({
  topics,
  subjects,
  aiPlan,
  remainingDays,
}) => {
  const subjectMap =
    new Map(
      subjects.map(
        (subject) => [
          String(subject._id),
          subject,
        ]
      )
    );

  const aiMap =
    new Map(
      (aiPlan.priorities ||
        []).map(
        (item) => [
          String(
            item.topicId
          ),
          item,
        ]
      )
    );

  return topics
    .map((topic) => {
      const subject =
        subjectMap.get(
          String(
            topic.subjectId
          )
        );

      const safeSubject =
        subject || {
          _id:
            topic.subjectId,
          name:
            "Unknown Subject",
          exams: {},
        };

      const ai =
        aiMap.get(
          String(topic._id)
        );

      const algorithmScore =
        fallbackPriority({
          topic,
          subject:
            safeSubject,
          remainingDays,
        });

      const aiScore =
        ai &&
        Number.isFinite(
          Number(ai.priority)
        )
          ? Math.max(
              0,
              Math.min(
                100,
                Number(
                  ai.priority
                )
              )
            )
          : algorithmScore;

      /*
       * AI reasoning contributes 55%.
       * Deterministic academic logic
       * contributes 45%.
       */

      const finalScore =
        Math.round(
          algorithmScore *
            0.45 +
            aiScore *
              0.55
        );

      return {
        topic,

        subject:
          safeSubject,

        subjectId:
          safeSubject._id,

        priority:
          finalScore,

        reason:
          ai?.reason ||
          "Prioritized using academic performance, unfinished work and deadline pressure.",
      };
    })
    .sort(
      (a, b) =>
        b.priority -
        a.priority
    );
};

module.exports = {
  calculatePerformance,
  fallbackPriority,
  buildPrioritizedTopics,
};