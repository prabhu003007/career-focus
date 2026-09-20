const mongoose = require("mongoose");

const StudySchedule = require("../models/StudySchedule");
const StudyDay = require("../models/StudyDay");
const Subject = require("../models/Subject");
const Unit = require("../models/Unit");
const Topic = require("../models/Topic");

const {
  generateScheduleProposal,
} = require("../services/llmService");

/*
 * =========================================================
 * CONSTANTS
 * =========================================================
 */

const NORMAL_DAILY_CAPACITY = 10;

/*
 * =========================================================
 * DATE HELPERS
 * =========================================================
 *
 * All schedule dates are stored as YYYY-MM-DD strings.
 *
 * We deliberately use UTC date construction so that the
 * backend does not accidentally shift dates because of the
 * server's local timezone.
 */

const DATE_PATTERN =
  /^\d{4}-\d{2}-\d{2}$/;

const pad = (value) =>
  String(value).padStart(2, "0");

const formatDate = (date) => {
  return [
    date.getUTCFullYear(),
    pad(date.getUTCMonth() + 1),
    pad(date.getUTCDate()),
  ].join("-");
};

const parseDate = (value) => {
  if (
    typeof value !== "string" ||
    !DATE_PATTERN.test(value)
  ) {
    return null;
  }

  const [year, month, day] =
    value.split("-").map(Number);

  const date = new Date(
    Date.UTC(
      year,
      month - 1,
      day
    )
  );

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  return date;
};

const todayDateString = () => {
  const now = new Date();

  return formatDate(
    new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate()
      )
    )
  );
};

const addDays = (
  date,
  amount
) => {
  const result =
    new Date(date.getTime());

  result.setUTCDate(
    result.getUTCDate() + amount
  );

  return result;
};

const isSunday = (date) =>
  date.getUTCDay() === 0;

const isStudyDay = (date) =>
  !isSunday(date);

const getDateRange = (
  start,
  end
) => {
  const dates = [];

  if (!start || !end) {
    return dates;
  }

  let current =
    new Date(start.getTime());

  while (
    current.getTime() <=
    end.getTime()
  ) {
    if (isStudyDay(current)) {
      dates.push(
        formatDate(current)
      );
    }

    current = addDays(
      current,
      1
    );
  }

  return dates;
};

/*
 * =========================================================
 * OBJECT ID
 * =========================================================
 */

const isValidObjectId = (
  value
) => {
  return mongoose.Types.ObjectId.isValid(
    value
  );
};

/*
 * =========================================================
 * PERFORMANCE
 * =========================================================
 *
 * Empty marks are unavailable, not zero.
 */

const calculatePerformance = (
  subject
) => {
  const values = [];

  const marks = [
    subject.exams?.assess1,
    subject.exams?.assess2,
    subject.exams?.endSem,
  ];

  for (
    const mark of marks
  ) {
    if (
      mark !== null &&
      mark !== undefined &&
      Number.isFinite(
        Number(mark)
      )
    ) {
      values.push(
        Number(mark)
      );
    }
  }

  if (values.length === 0) {
    return null;
  }

  return (
    values.reduce(
      (sum, value) =>
        sum + value,
      0
    ) / values.length
  );
};

/*
 * =========================================================
 * SUBJECT DATE MAP
 * =========================================================
 */

const buildSubjectDateMap = (
  subjectPlans
) => {
  const map = new Map();

  for (
    const subject of subjectPlans
  ) {
    map.set(
      String(
        subject.subjectId
      ),
      {
        startDate:
          subject.startDate,

        deadline:
          subject.deadline,
      }
    );
  }

  return map;
};

/*
 * =========================================================
 * ASSIGNMENT HELPERS
 * =========================================================
 */

const getActiveAssignments = (
  schedule
) => {
  return schedule.assignments.filter(
    (assignment) =>
      assignment.status ===
      "planned"
  );
};

const getActiveTopicIds = (
  schedule
) => {
  return new Set(
    getActiveAssignments(
      schedule
    ).map(
      (assignment) =>
        String(
          assignment.topicId
        )
    )
  );
};

/*
 * =========================================================
 * STUDY DAYS REBUILD
 * =========================================================
 *
 * StudyDay is a derived collection.
 *
 * The schedule itself remains the source of truth.
 */

const rebuildStudyDays = async (
  schedule
) => {
  const userId =
    schedule.userId;

  await StudyDay.deleteMany({
    userId,
  });

  const dateMap = new Map();

  for (
    const assignment of
      schedule.assignments
  ) {
    if (
      !assignment.date
    ) {
      continue;
    }

    if (
      !dateMap.has(
        assignment.date
      )
    ) {
      dateMap.set(
        assignment.date,
        {
          planned: 0,
          completed: 0,
          skipped: 0,
          subjectIds:
            new Set(),
        }
      );
    }

    const day =
      dateMap.get(
        assignment.date
      );

    const status =
      assignment.status;

    if (
      status ===
      "planned"
    ) {
      day.planned++;
    }

    if (
      status ===
      "completed"
    ) {
      day.completed++;
    }

    if (
      status ===
      "skipped"
    ) {
      day.skipped++;
    }

    if (
      assignment.subjectId
    ) {
      day.subjectIds.add(
        String(
          assignment.subjectId
        )
      );
    }
  }

  const documents = [];

  for (
    const [
      date,
      data,
    ] of dateMap.entries()
  ) {
    const total =
      data.planned +
      data.completed +
      data.skipped;

    const performance =
      total > 0
        ? Math.round(
            (data.completed /
              total) *
              100
          )
        : 0;

    documents.push({
      userId,
      date,
      plannedTopics:
        data.planned,
      completedTopics:
        data.completed,
      skippedTopics:
        data.skipped,
      performance,
      subjectIds:
        Array.from(
          data.subjectIds
        ),
    });
  }

  if (
    documents.length > 0
  ) {
    await StudyDay.insertMany(
      documents
    );
  }
};

/*
 * =========================================================
 * ENRICH SCHEDULE
 * =========================================================
 *
 * Flutter receives topic/unit/subject names without having
 * to perform additional requests for every assignment.
 */

const enrichSchedule = async (
  schedule
) => {
  const raw =
    schedule.toObject
      ? schedule.toObject()
      : schedule;

  const topicIds = [
    ...new Set(
      (raw.assignments || [])
        .map(
          (item) =>
            String(
              item.topicId
            )
        )
    ),
  ];

  const subjectIds = [
    ...new Set(
      [
        ...(raw.assignments ||
          []).map(
          (item) =>
            String(
              item.subjectId
            )
        ),
        ...(raw.subjects ||
          []).map(
          (item) =>
            String(
              item.subjectId
            )
        ),
      ]
    ),
  ];

  const unitIds = [
    ...new Set(
      (raw.assignments || [])
        .map(
          (item) =>
            item.unitId
              ? String(
                  item.unitId
                )
              : null
        )
        .filter(Boolean)
    ),
  ];

  const [
    topics,
    subjects,
    units,
  ] = await Promise.all([
    topicIds.length > 0
      ? Topic.find({
          _id: {
            $in: topicIds,
          },
          userId:
            raw.userId,
        }).lean()
      : [],

    subjectIds.length > 0
      ? Subject.find({
          _id: {
            $in: subjectIds,
          },
          userId:
            raw.userId,
        }).lean()
      : [],

    unitIds.length > 0
      ? Unit.find({
          _id: {
            $in: unitIds,
          },
          userId:
            raw.userId,
        }).lean()
      : [],
  ]);

  const topicMap =
    new Map(
      topics.map(
        (topic) => [
          String(
            topic._id
          ),
          topic,
        ]
      )
    );

  const subjectMap =
    new Map(
      subjects.map(
        (subject) => [
          String(
            subject._id
          ),
          subject,
        ]
      )
    );

  const unitMap =
    new Map(
      units.map(
        (unit) => [
          String(
            unit._id
          ),
          unit,
        ]
      )
    );

  const enrichedAssignments =
    (raw.assignments || [])
      .map(
        (assignment) => {
          const topic =
            topicMap.get(
              String(
                assignment.topicId
              )
            );

          const subject =
            subjectMap.get(
              String(
                assignment.subjectId
              )
            );

          const unit =
            assignment.unitId
              ? unitMap.get(
                  String(
                    assignment.unitId
                  )
                )
              : null;

          return {
            ...assignment,

            topicName:
              topic?.name ||
              "",

            subjectName:
              subject?.name ||
              "",

            unitName:
              unit?.name ||
              "",

            unitNumber:
              unit?.unitNumber ??
              null,
          };
        }
      );

  /*
   * Subject plan enrichment.
   */
  const enrichedSubjects =
    (raw.subjects || [])
      .map(
        (subjectPlan) => {
          const subject =
            subjectMap.get(
              String(
                subjectPlan.subjectId
              )
            );

          return {
            ...subjectPlan,

            subjectName:
              subject?.name ||
              "",

            code:
              subject?.code ||
              "",
          };
        }
      );

  /*
   * Active schedule grouped by date.
   *
   * Completed/skipped historical records are intentionally
   * excluded from the active date representation.
   */
  const activeAssignments =
    enrichedAssignments.filter(
      (item) =>
        item.status ===
        "planned"
    );

  const dateMap = new Map();

  for (
    const assignment of
      activeAssignments
  ) {
    if (
      !dateMap.has(
        assignment.date
      )
    ) {
      dateMap.set(
        assignment.date,
        []
      );
    }

    dateMap
      .get(assignment.date)
      .push(
        assignment
      );
  }

  const dates =
    Array.from(
      dateMap.entries()
    )
      .sort(
        ([dateA], [dateB]) =>
          dateA.localeCompare(
            dateB
          )
      )
      .map(
        ([
          date,
          assignments,
        ]) => ({
          date,

          assignments:
            assignments.sort(
              (a, b) => {
                const unitA =
                  Number(
                    a.unitNumber ??
                      999
                  );

                const unitB =
                  Number(
                    b.unitNumber ??
                      999
                  );

                if (
                  unitA !==
                  unitB
                ) {
                  return (
                    unitA -
                    unitB
                  );
                }

                return (
                  String(
                    a.topicName
                  ).localeCompare(
                    String(
                      b.topicName
                    )
                  )
                );
              }
            ),
        })
      );

  return {
    ...raw,

    subjects:
      enrichedSubjects,

    assignments:
      enrichedAssignments,

    activeAssignments,

    dates,
  };
};

/*
 * =========================================================
 * VALIDATE SUBJECT PLANS
 * =========================================================
 */

const validateSubjectPlans = async ({
  userId,
  requestedSubjects,
}) => {
  if (
    !Array.isArray(
      requestedSubjects
    ) ||
    requestedSubjects.length ===
      0
  ) {
    throw new Error(
      "At least one subject must be configured."
    );
  }

  const today =
    parseDate(
      todayDateString()
    );

  const seenSubjects =
    new Set();

  const normalizedPlans = [];

  for (
    const requested of
      requestedSubjects
  ) {
    if (
      !requested ||
      !requested.subjectId
    ) {
      throw new Error(
        "Every subject configuration requires a subjectId."
      );
    }

    const subjectId =
      String(
        requested.subjectId
      );

    if (
      !isValidObjectId(
        subjectId
      )
    ) {
      throw new Error(
        "Invalid subject ID."
      );
    }

    if (
      seenSubjects.has(
        subjectId
      )
    ) {
      throw new Error(
        "A subject cannot be configured more than once."
      );
    }

    seenSubjects.add(
      subjectId
    );

    const subject =
      await Subject.findOne({
        _id: subjectId,
        userId,
      }).lean();

    if (!subject) {
      throw new Error(
        "Subject not found or does not belong to the current user."
      );
    }

    const start =
      parseDate(
        requested.startDate
      );

    const deadline =
      parseDate(
        requested.deadline
      );

    if (!start) {
      throw new Error(
        `Invalid start date for ${subject.name}.`
      );
    }

    if (!deadline) {
      throw new Error(
        `Invalid deadline for ${subject.name}.`
      );
    }

    if (
      start.getTime() <
      today.getTime()
    ) {
      throw new Error(
        `Start date for ${subject.name} cannot be before today.`
      );
    }

    if (
      deadline.getTime() <
      start.getTime()
    ) {
      throw new Error(
        `Deadline for ${subject.name} cannot be before its start date.`
      );
    }

    if (
      Array.isArray(
        requested.units
      ) === false
    ) {
      throw new Error(
        `Unit selection is missing for ${subject.name}.`
      );
    }

    normalizedPlans.push({
      subjectId,
      name:
        subject.name,
      code:
        subject.code || "",
      exams:
        subject.exams || {},
      startDate:
        formatDate(start),
      deadline:
        formatDate(deadline),
      units:
        requested.units,
    });
  }

  return normalizedPlans;
};

/*
 * =========================================================
 * VALIDATE SELECTED TOPICS
 * =========================================================
 *
 * This is one of the most important safety layers.
 *
 * The client cannot simply submit a topicId and claim it
 * belongs to a selected subject/unit.
 */

const resolveSelectedTopics = async ({
  userId,
  subjectPlans,
}) => {
  const resolvedTopics = [];

  const selectedTopicIds =
    new Set();

  for (
    const subjectPlan of
      subjectPlans
  ) {
    const subjectId =
      String(
        subjectPlan.subjectId
      );

    const unitSelections =
      Array.isArray(
        subjectPlan.units
      )
        ? subjectPlan.units
        : [];

    const selectedUnitIds =
      new Set();

    for (
      const unitSelection of
        unitSelections
    ) {
      if (
        !unitSelection ||
        !unitSelection.unitId
      ) {
        continue;
      }

      const unitId =
        String(
          unitSelection.unitId
        );

      if (
        !isValidObjectId(
          unitId
        )
      ) {
        throw new Error(
          `Invalid unit ID for ${subjectPlan.name}.`
        );
      }

      if (
        selectedUnitIds.has(
          unitId
        )
      ) {
        throw new Error(
          `Unit ${unitId} was selected more than once.`
        );
      }

      selectedUnitIds.add(
        unitId
      );

      const unit =
        await Unit.findOne({
          _id: unitId,
          userId,
          subjectId,
        }).lean();

      if (!unit) {
        throw new Error(
          `Selected unit does not belong to ${subjectPlan.name}.`
        );
      }

      const topicIds =
        Array.isArray(
          unitSelection.topicIds
        )
          ? unitSelection.topicIds
          : [];

      /*
       * Empty topic selection is allowed.
       * This lets the user enter a unit and leave it
       * without selecting topics.
       */
      for (
        const rawTopicId of
          topicIds
      ) {
        const topicId =
          String(
            rawTopicId
          );

        if (
          !isValidObjectId(
            topicId
          )
        ) {
          throw new Error(
            `Invalid topic ID in ${unit.name}.`
          );
        }

        if (
          selectedTopicIds.has(
            topicId
          )
        ) {
          throw new Error(
            "The same topic cannot be selected more than once."
          );
        }

        const topic =
          await Topic.findOne({
            _id: topicId,
            userId,
            subjectId,
            unitId,
          }).lean();

        if (!topic) {
          throw new Error(
            `Selected topic does not belong to the selected unit.`
          );
        }

        /*
         * Completed topics must never enter the active planner.
         */
        if (
          topic.completed
        ) {
          throw new Error(
            `Completed topic "${topic.name}" cannot be added to the active study plan.`
          );
        }

        selectedTopicIds.add(
          topicId
        );

        const performance =
          calculatePerformance(
            subjectPlan
          );

        resolvedTopics.push({
          topicId,

          name:
            topic.name,

          subjectId,

          subjectName:
            subjectPlan.name,

          unitId,

          unitNumber:
            unit.unitNumber,

          unitName:
            unit.name,

          subjectStartDate:
            subjectPlan.startDate,

          subjectDeadline:
            subjectPlan.deadline,

          subjectPerformance:
            performance,

          skipCount: 0,
        });
      }
    }
  }

  return {
    topics:
      resolvedTopics,

    selectedTopicIds,
  };
};

/*
 * =========================================================
 * AVAILABLE DATES
 * =========================================================
 */

const buildAvailableDatesForTopics = (
  topics
) => {
  const dateSet =
    new Set();

  for (
    const topic of topics
  ) {
    const start =
      parseDate(
        topic.subjectStartDate
      );

    const deadline =
      parseDate(
        topic.subjectDeadline
      );

    if (
      !start ||
      !deadline
    ) {
      continue;
    }

    for (
      const date of
        getDateRange(
          start,
          deadline
        )
    ) {
      dateSet.add(date);
    }
  }

  return Array.from(
    dateSet
  ).sort();
};

/*
 * =========================================================
 * CHECK DATE IS INSIDE SUBJECT RANGE
 * =========================================================
 */

const isDateAllowedForTopic = (
  topic,
  date
) => {
  const start =
    parseDate(
      topic.subjectStartDate
    );

  const deadline =
    parseDate(
      topic.subjectDeadline
    );

  const target =
    parseDate(date);

  if (
    !start ||
    !deadline ||
    !target
  ) {
    return false;
  }

  return (
    target.getTime() >=
      start.getTime() &&
    target.getTime() <=
      deadline.getTime() &&
    isStudyDay(target)
  );
};

/*
 * =========================================================
 * DETERMINISTIC SCHEDULER
 * =========================================================
 *
 * Used as:
 *
 * 1. Fallback if model unavailable.
 * 2. Repair engine when model misses topics.
 * 3. Guaranteed-safe final allocation.
 *
 * The algorithm prefers:
 *
 * - deadline pressure
 * - lower-performing subjects
 * - unit progression
 * - balanced daily load
 */

const deterministicSchedule = ({
  topics,
  allowOverCapacity,
  existingLoad,
}) => {
  const assignments = [];

  const load =
    new Map(
      existingLoad
        ? existingLoad
        : []
    );

  /*
   * Sort by:
   *
   * 1. earliest deadline
   * 2. weaker subject
   * 3. earlier unit
   * 4. topic name
   */
  const ordered =
    [...topics].sort(
      (a, b) => {
        const deadlineA =
          a.subjectDeadline;

        const deadlineB =
          b.subjectDeadline;

        if (
          deadlineA !==
          deadlineB
        ) {
          return deadlineA.localeCompare(
            deadlineB
          );
        }

        const performanceA =
          a.subjectPerformance ===
          null
            ? 50
            : a.subjectPerformance;

        const performanceB =
          b.subjectPerformance ===
          null
            ? 50
            : b.subjectPerformance;

        if (
          performanceA !==
          performanceB
        ) {
          return (
            performanceA -
            performanceB
          );
        }

        const unitA =
          Number(
            a.unitNumber || 999
          );

        const unitB =
          Number(
            b.unitNumber || 999
          );

        if (
          unitA !==
          unitB
        ) {
          return unitA - unitB;
        }

        return a.name.localeCompare(
          b.name
        );
      }
    );

  const allDates =
    buildAvailableDatesForTopics(
      ordered
    );

  for (
    const topic of ordered
  ) {
    const validDates =
      allDates.filter(
        (date) =>
          isDateAllowedForTopic(
            topic,
            date
          )
      );

    if (
      validDates.length === 0
    ) {
      continue;
    }

    /*
     * Choose the date with the smallest load,
     * while preferring earlier dates as deadline pressure
     * increases.
     */
    let selectedDate =
      null;

    let selectedScore =
      Infinity;

    const deadline =
      parseDate(
        topic.subjectDeadline
      );

    for (
      const date of validDates
    ) {
      const target =
        parseDate(date);

      const currentLoad =
        load.get(date) || 0;

      const daysLeft =
        Math.max(
          1,
          Math.floor(
            (
              deadline.getTime() -
              target.getTime()
            ) /
              86400000
          ) + 1
        );

      /*
       * Deadline pressure increases as the deadline
       * approaches.
       */
      const pressure =
        1 / daysLeft;

      /*
       * Earlier dates get a small preference.
       */
      const chronologicalBias =
        allDates.indexOf(date) *
        0.0001;

      /*
       * Load dominates normal distribution.
       */
      let score =
        currentLoad * 10 +
        chronologicalBias -
        pressure * 5;

      /*
       * Never exceed 10 during normal scheduling.
       */
      if (
        !allowOverCapacity &&
        currentLoad >=
          NORMAL_DAILY_CAPACITY
      ) {
        continue;
      }

      /*
       * If over-capacity scheduling is allowed,
       * only use it when necessary. The score makes
       * earlier deadline dates attractive.
       */
      if (
        allowOverCapacity &&
        currentLoad >=
          NORMAL_DAILY_CAPACITY
      ) {
        score +=
          25 +
          currentLoad * 2;
      }

      if (
        score <
        selectedScore
      ) {
        selectedScore =
          score;

        selectedDate =
          date;
      }
    }

    if (!selectedDate) {
      continue;
    }

    assignments.push({
      topicId:
        String(
          topic.topicId
        ),

      date:
        selectedDate,
    });

    load.set(
      selectedDate,
      (load.get(
        selectedDate
      ) || 0) + 1
    );
  }

  return {
    assignments,
    load,
  };
};

/*
 * =========================================================
 * VALIDATE MODEL ASSIGNMENTS
 * =========================================================
 */

const validateAssignments = ({
  assignments,
  topics,
  existingAssignments,
  allowOverCapacity,
}) => {
  const topicMap =
    new Map(
      topics.map(
        (topic) => [
          String(
            topic.topicId
          ),
          topic,
        ]
      )
    );

  const seen =
    new Set();

  const load =
    new Map();

  for (
    const assignment of
      existingAssignments || []
  ) {
    if (
      assignment.status ===
      "planned"
    ) {
      const date =
        String(
          assignment.date
        );

      load.set(
        date,
        (load.get(date) || 0) +
          1
      );
    }
  }

  const valid = [];

  for (
    const assignment of
      assignments || []
  ) {
    const topicId =
      String(
        assignment.topicId
      );

    const date =
      String(
        assignment.date
      );

    const topic =
      topicMap.get(
        topicId
      );

    if (!topic) {
      continue;
    }

    if (
      seen.has(topicId)
    ) {
      continue;
    }

    if (
      !isDateAllowedForTopic(
        topic,
        date
      )
    ) {
      continue;
    }

    /*
     * Do not duplicate an already-active topic.
     */
    const alreadyActive =
      (
        existingAssignments ||
        []
      ).some(
        (item) =>
          item.status ===
            "planned" &&
          String(
            item.topicId
          ) === topicId
      );

    if (
      alreadyActive
    ) {
      continue;
    }

    const currentLoad =
      load.get(date) || 0;

    if (
      !allowOverCapacity &&
      currentLoad >=
        NORMAL_DAILY_CAPACITY
    ) {
      continue;
    }

    seen.add(topicId);

    valid.push({
      topicId,
      date,
    });

    load.set(
      date,
      currentLoad + 1
    );
  }

  return {
    valid,
    assignedTopicIds:
      seen,
    load,
  };
};

/*
 * =========================================================
 * REPAIR SCHEDULE
 * =========================================================
 *
 * Anything the model missed is assigned deterministically.
 */

const repairAssignments = ({
  topics,
  validated,
  allowOverCapacity,
}) => {
  const missing =
    topics.filter(
      (topic) =>
        !validated.assignedTopicIds.has(
          String(
            topic.topicId
          )
        )
    );

  if (
    missing.length === 0
  ) {
    return validated.valid;
  }

  const fallback =
    deterministicSchedule({
      topics: missing,
      allowOverCapacity,
      existingLoad:
        Array.from(
          validated.load.entries()
        ),
    });

  return [
    ...validated.valid,
    ...fallback.assignments,
  ];
};

/*
 * =========================================================
 * DEADLINE FEASIBILITY
 * =========================================================
 *
 * Determines which topics cannot fit within their own
 * subject deadline under the normal 10/day capacity.
 */

const findDeadlinePressureSubjects = ({
  topics,
}) => {
  const grouped =
    new Map();

  for (
    const topic of topics
  ) {
    const subjectId =
      String(
        topic.subjectId
      );

    if (
      !grouped.has(
        subjectId
      )
    ) {
      grouped.set(
        subjectId,
        {
          subjectId,
          subjectName:
            topic.subjectName,
          startDate:
            topic.subjectStartDate,
          deadline:
            topic.subjectDeadline,
          topics: [],
        }
      );
    }

    grouped
      .get(subjectId)
      .topics.push(topic);
  }

  const pressured =
    [];

  for (
    const subject of
      grouped.values()
  ) {
    const dates =
      getDateRange(
        parseDate(
          subject.startDate
        ),
        parseDate(
          subject.deadline
        )
      );

    const capacity =
      dates.length *
      NORMAL_DAILY_CAPACITY;

    if (
      subject.topics.length >
      capacity
    ) {
      pressured.push({
        ...subject,

        topicCount:
          subject.topics.length,

        availableStudyDays:
          dates.length,

        normalCapacity:
          capacity,

        excess:
          subject.topics.length -
          capacity,
      });
    }
  }

  return pressured;
};

/*
 * =========================================================
 * GENERATE SCHEDULE
 * =========================================================
 */

const generateSchedule =
  async (req, res) => {
    try {
      const userId =
        req.userId;

      const {
        subjects:
          requestedSubjects,
        allowOverCapacity =
          false,
      } = req.body || {};

      /*
       * -----------------------------------------------------
       * BASIC REQUEST VALIDATION
       * -----------------------------------------------------
       */

      const subjectPlans =
        await validateSubjectPlans({
          userId,
          requestedSubjects,
        });

      /*
       * -----------------------------------------------------
       * RESOLVE TOPICS
       * -----------------------------------------------------
       */

      const {
        topics,
        selectedTopicIds,
      } =
        await resolveSelectedTopics({
          userId,
          subjectPlans,
        });

      if (
        selectedTopicIds.size ===
        0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "No topics selected.",
        });
      }

      /*
       * -----------------------------------------------------
       * EXISTING ACTIVE PLAN
       * -----------------------------------------------------
       */

      const existingSchedule =
        await StudySchedule.findOne({
          userId,
        });

      const existingActive =
        existingSchedule
          ? getActiveAssignments(
              existingSchedule
            )
          : [];

      /*
       * User requested merge behavior.
       *
       * Existing active topics are preserved unless the
       * newly generated plan explicitly replaces their
       * assignment through a future rescheduling operation.
       *
       * For initial generation, duplicate selected active
       * topics are ignored safely.
       */

      const existingTopicIds =
        new Set(
          existingActive.map(
            (item) =>
              String(
                item.topicId
              )
          )
        );

      const newTopics =
        topics.filter(
          (topic) =>
            !existingTopicIds.has(
              String(
                topic.topicId
              )
            )
        );

      /*
       * If all selected topics are already active, return the
       * current schedule instead of duplicating assignments.
       */
      if (
        newTopics.length ===
        0
      ) {
        const enriched =
          await enrichSchedule(
            existingSchedule
          );

        return res.status(200).json({
          success: true,
          message:
            "The selected topics are already present in the active study plan.",
          schedule:
            enriched,
        });
      }

      /*
       * -----------------------------------------------------
       * DEADLINE PRESSURE
       * -----------------------------------------------------
       */

      const pressuredSubjects =
        findDeadlinePressureSubjects({
          topics:
            newTopics,
        });

      /*
       * If the normal capacity is insufficient and the user
       * has not explicitly allowed exceeding 10/day, stop
       * here and ask Flutter to display:
       *
       * LEAVE IT / SCHEDULE IT
       *
       * This prevents silent overloading.
       */

      if (
        pressuredSubjects.length >
          0 &&
        !Boolean(
          allowOverCapacity
        )
      ) {
        return res.status(409).json({
          success: false,

          code:
            "DEADLINE_PRESSURE",

          message:
            "The deadline is approaching and the remaining topics require additional scheduling capacity.",

          pressure:
            pressuredSubjects.map(
              (item) => ({
                subjectId:
                  item.subjectId,

                subjectName:
                  item.subjectName,

                deadline:
                  item.deadline,

                topicCount:
                  item.topicCount,

                availableStudyDays:
                  item.availableStudyDays,

                normalCapacity:
                  item.normalCapacity,

                excess:
                  item.excess,
              })
            ),
        });
      }

      /*
       * -----------------------------------------------------
       * AVAILABLE DATES
       * -----------------------------------------------------
       */

      const availableDates =
        buildAvailableDatesForTopics(
          newTopics
        );

      if (
        availableDates.length ===
        0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "No valid Monday-Saturday study dates are available for the selected topics.",
        });
      }

      /*
       * -----------------------------------------------------
       * LLM
       * -----------------------------------------------------
       */

      const previousAssignments =
        existingActive.map(
          (assignment) => ({
            date:
              assignment.date,

            topicId:
              String(
                assignment.topicId
              ),

            subjectId:
              String(
                assignment.subjectId
              ),

            unitId:
              assignment.unitId
                ? String(
                    assignment.unitId
                  )
                : null,
          })
        );

      const llmProposal =
        await generateScheduleProposal({
          subjects:
            subjectPlans,

          topics:
            newTopics,

          availableDates,

          dailyNormalCapacity:
            NORMAL_DAILY_CAPACITY,

          previousAssignments,

          mode:
            "initial",
        });

      /*
       * -----------------------------------------------------
       * VALIDATE MODEL OUTPUT
       * -----------------------------------------------------
       */

      const validation =
        validateAssignments({
          assignments:
            llmProposal.assignments,

          topics:
            newTopics,

          existingAssignments:
            existingActive,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      /*
       * -----------------------------------------------------
       * REPAIR MISSED TOPICS
       * -----------------------------------------------------
       */

      const finalAssignments =
        repairAssignments({
          topics:
            newTopics,

          validated:
            validation,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      /*
       * -----------------------------------------------------
       * FINAL SAFETY VALIDATION
       * -----------------------------------------------------
       */

      const finalValidation =
        validateAssignments({
          assignments:
            finalAssignments,

          topics:
            newTopics,

          existingAssignments:
            existingActive,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      /*
       * -----------------------------------------------------
       * DETERMINE UNRESOLVED TOPICS
       * -----------------------------------------------------
       */

      const unresolved =
        newTopics.filter(
          (topic) =>
            !finalValidation.assignedTopicIds.has(
              String(
                topic.topicId
              )
            )
        );

      /*
       * Normally this should only happen when a topic has no
       * valid study date.
       */
      const assignmentDocuments =
        finalValidation.valid.map(
          (assignment) => {
            const topic =
              newTopics.find(
                (item) =>
                  String(
                    item.topicId
                  ) ===
                  String(
                    assignment.topicId
                  )
              );

            return {
              date:
                assignment.date,

              topicId:
                assignment.topicId,

              unitId:
                topic.unitId,

              subjectId:
                topic.subjectId,

              status:
                "planned",

              skippedFromDate:
                null,

              skipCount:
                0,

              completedAt:
                null,
            };
          }
        );

      /*
       * -----------------------------------------------------
       * SAVE / MERGE
       * -----------------------------------------------------
       */

      let schedule =
        existingSchedule;

      if (!schedule) {
        schedule =
          new StudySchedule({
            userId,
            subjects:
              subjectPlans,
            assignments:
              assignmentDocuments,
            reasoning:
              llmProposal.strategy,
            planningSource:
              llmProposal.llmAvailable
                ? "llm"
                : "adaptive-fallback",
            version: 1,
            generatedAt:
              new Date(),
          });
      } else {
        /*
         * Merge the newly configured subjects.
         *
         * Existing subject configurations are replaced only
         * for subjects explicitly configured in this request.
         */
        const configuredSubjectIds =
          new Set(
            subjectPlans.map(
              (subject) =>
                String(
                  subject.subjectId
                )
            )
          );

        const retainedSubjectPlans =
          schedule.subjects.filter(
            (subject) =>
              !configuredSubjectIds.has(
                String(
                  subject.subjectId
                )
              )
          );

        schedule.subjects = [
          ...retainedSubjectPlans,
          ...subjectPlans,
        ];

        schedule.assignments.push(
          ...assignmentDocuments
        );

        schedule.reasoning =
          llmProposal.strategy;

        schedule.planningSource =
          llmProposal.llmAvailable
            ? "llm+repair"
            : "adaptive-fallback";

        schedule.version =
          Number(
            schedule.version ||
              1
          ) + 1;

        schedule.generatedAt =
          new Date();
      }

      await schedule.save();

      await rebuildStudyDays(
        schedule
      );

      const enriched =
        await enrichSchedule(
          schedule
        );

      return res.status(201).json({
        success: true,

        message:
          unresolved.length > 0
            ? "Study plan generated. Some topics could not be scheduled within the available constraints."
            : "Study plan generated successfully.",

        unresolvedTopics:
          unresolved.map(
            (topic) => ({
              topicId:
                topic.topicId,

              name:
                topic.name,

              subjectId:
                topic.subjectId,

              subjectName:
                topic.subjectName,

              deadline:
                topic.subjectDeadline,
            })
          ),

        schedule:
          enriched,
      });
    } catch (error) {
      console.error(
        "Generate schedule error:",
        error
      );

      const message =
        error?.message ||
        "Failed to generate study schedule.";

      return res.status(400).json({
        success: false,
        message,
      });
    }
  };
/*
 * =========================================================
 * SANITIZE STORED SCHEDULE
 * =========================================================
 *
 * Removes stale schedule records caused by topics/units/
 * subjects being deleted after a schedule was generated.
 *
 * The database remains the source of truth.
 *
 * Rules:
 * - Deleted topic -> remove assignment
 * - Deleted unit -> remove assignment
 * - Deleted subject -> remove assignment
 * - Ownership mismatch -> remove assignment
 * - Completed topic with planned assignment -> remove
 * - Deleted topic inside subject plan -> remove topicId
 */

const sanitizeStoredSchedule = async (
  schedule
) => {
  if (!schedule) {
    return {
      changed: false,
      removedAssignments: 0,
      removedTopicReferences: 0,
    };
  }

  const userId =
    schedule.userId;

  const rawAssignments =
    Array.isArray(
      schedule.assignments
    )
      ? schedule.assignments
      : [];

  const rawSubjects =
    Array.isArray(
      schedule.subjects
    )
      ? schedule.subjects
      : [];

  /*
   * -------------------------------------------------------
   * COLLECT IDS
   * -------------------------------------------------------
   */

  const topicIds = [
    ...new Set(
      rawAssignments
        .map(
          (assignment) =>
            assignment.topicId
              ? String(
                  assignment.topicId
                )
              : null
        )
        .filter(Boolean)
    ),
  ];

  const assignmentUnitIds = [
    ...new Set(
      rawAssignments
        .map(
          (assignment) =>
            assignment.unitId
              ? String(
                  assignment.unitId
                )
              : null
        )
        .filter(Boolean)
    ),
  ];

  const assignmentSubjectIds = [
    ...new Set(
      rawAssignments
        .map(
          (assignment) =>
            assignment.subjectId
              ? String(
                  assignment.subjectId
                )
              : null
        )
        .filter(Boolean)
    ),
  ];

  const planSubjectIds = rawSubjects.map(
    (subjectPlan) =>
      String(
        subjectPlan.subjectId
      )
  );

  const planUnitIds = rawSubjects.flatMap(
    (subjectPlan) =>
      Array.isArray(
        subjectPlan.units
      )
        ? subjectPlan.units
            .map(
              (unitPlan) =>
                unitPlan?.unitId
                  ? String(
                      unitPlan.unitId
                    )
                  : null
            )
            .filter(Boolean)
        : []
  );

  const allTopicIds = [
    ...new Set(
      topicIds
    ),
  ];

  const allUnitIds = [
    ...new Set([
      ...assignmentUnitIds,
      ...planUnitIds,
    ]),
  ];

  const allSubjectIds = [
    ...new Set([
      ...assignmentSubjectIds,
      ...planSubjectIds,
    ]),
  ];

  /*
   * -------------------------------------------------------
   * LOAD CURRENT USER DATA
   * -------------------------------------------------------
   */

  const [
    topics,
    units,
    subjects,
  ] = await Promise.all([
    allTopicIds.length > 0
      ? Topic.find({
          _id: {
            $in:
              allTopicIds,
          },
          userId,
        }).lean()
      : [],

    allUnitIds.length > 0
      ? Unit.find({
          _id: {
            $in:
              allUnitIds,
          },
          userId,
        }).lean()
      : [],

    allSubjectIds.length > 0
      ? Subject.find({
          _id: {
            $in:
              allSubjectIds,
          },
          userId,
        }).lean()
      : [],
  ]);

  const topicMap =
    new Map(
      topics.map(
        (topic) => [
          String(
            topic._id
          ),
          topic,
        ]
      )
    );

  const unitMap =
    new Map(
      units.map(
        (unit) => [
          String(
            unit._id
          ),
          unit,
        ]
      )
    );

  const subjectMap =
    new Map(
      subjects.map(
        (subject) => [
          String(
            subject._id
          ),
          subject,
        ]
      )
    );

  /*
   * -------------------------------------------------------
   * CLEAN ASSIGNMENTS
   * -------------------------------------------------------
   */

  let removedAssignments = 0;

  const cleanedAssignments =
    rawAssignments.filter(
      (assignment) => {
        const topicId =
          assignment.topicId
            ? String(
                assignment.topicId
              )
            : null;

        const unitId =
          assignment.unitId
            ? String(
                assignment.unitId
              )
            : null;

        const subjectId =
          assignment.subjectId
            ? String(
                assignment.subjectId
              )
            : null;

        /*
         * Missing references.
         */
        if (
          !topicId ||
          !unitId ||
          !subjectId
        ) {
          removedAssignments++;
          return false;
        }

        const topic =
          topicMap.get(
            topicId
          );

        const unit =
          unitMap.get(
            unitId
          );

        const subject =
          subjectMap.get(
            subjectId
          );

        /*
         * Deleted document.
         */
        if (
          !topic ||
          !unit ||
          !subject
        ) {
          removedAssignments++;
          return false;
        }

        /*
         * Relationship validation.
         */
        if (
          String(
            topic.userId
          ) !==
          String(userId)
        ) {
          removedAssignments++;
          return false;
        }

        if (
          String(
            unit.userId
          ) !==
          String(userId)
        ) {
          removedAssignments++;
          return false;
        }

        if (
          String(
            subject.userId
          ) !==
          String(userId)
        ) {
          removedAssignments++;
          return false;
        }

        if (
          String(
            topic.subjectId
          ) !== subjectId
        ) {
          removedAssignments++;
          return false;
        }

        if (
          String(
            topic.unitId
          ) !== unitId
        ) {
          removedAssignments++;
          return false;
        }

        if (
          String(
            unit.subjectId
          ) !== subjectId
        ) {
          removedAssignments++;
          return false;
        }

        /*
         * A completed topic must never remain as an active
         * planned assignment.
         */
        if (
          assignment.status ===
            "planned" &&
          topic.completed ===
            true
        ) {
          removedAssignments++;
          return false;
        }

        return true;
      }
    );

  /*
   * -------------------------------------------------------
   * CLEAN SUBJECT PLAN TOPIC REFERENCES
   * -------------------------------------------------------
   */

  let removedTopicReferences = 0;

  for (
    const subjectPlan of
      rawSubjects
  ) {
    const subjectId =
      String(
        subjectPlan.subjectId
      );

    /*
     * If the subject itself was deleted, its entire plan
     * should disappear.
     */
    if (
      !subjectMap.has(
        subjectId
      )
    ) {
      subjectPlan.units = [];
      continue;
    }

    if (
      !Array.isArray(
        subjectPlan.units
      )
    ) {
      subjectPlan.units = [];
      continue;
    }

    for (
      const unitPlan of
        subjectPlan.units
    ) {
      if (
        !Array.isArray(
          unitPlan.topicIds
        )
      ) {
        unitPlan.topicIds = [];
        continue;
      }

      const cleanedTopicIds =
        [];

      for (
        const rawTopicId of
          unitPlan.topicIds
      ) {
        const topicId =
          String(
            rawTopicId
          );

        const topic =
          topicMap.get(
            topicId
          );

        const unit =
          unitMap.get(
            String(
              unitPlan.unitId
            )
          );

        /*
         * Remove deleted/mismatched topics.
         */
        if (
          !topic ||
          !unit ||
          String(
            topic.userId
          ) !==
            String(userId) ||
          String(
            topic.subjectId
          ) !== subjectId ||
          String(
            topic.unitId
          ) !==
            String(
              unitPlan.unitId
            )
        ) {
          removedTopicReferences++;
          continue;
        }

        /*
         * Completed topics should not be part of the active
         * planner's topic references.
         */
        if (
          topic.completed ===
          true
        ) {
          removedTopicReferences++;
          continue;
        }

        cleanedTopicIds.push(
          topicId
        );
      }

      unitPlan.topicIds =
        cleanedTopicIds;
    }
  }

  /*
   * Remove subject plans that point to subjects which no
   * longer exist.
   */
  const cleanedSubjectPlans =
    rawSubjects.filter(
      (subjectPlan) =>
        subjectMap.has(
          String(
            subjectPlan.subjectId
          )
        )
    );

  /*
   * -------------------------------------------------------
   * DETERMINE WHETHER DATABASE CHANGED
   * -------------------------------------------------------
   */

  const assignmentsChanged =
    cleanedAssignments.length !==
    rawAssignments.length;

  const subjectsChanged =
    cleanedSubjectPlans.length !==
    rawSubjects.length;

  const topicReferencesChanged =
    removedTopicReferences >
    0;

  const changed =
    assignmentsChanged ||
    subjectsChanged ||
    topicReferencesChanged;

  if (!changed) {
    return {
      changed: false,
      removedAssignments: 0,
      removedTopicReferences: 0,
    };
  }

  /*
   * -------------------------------------------------------
   * SAVE CLEANED SCHEDULE
   * -------------------------------------------------------
   */

  schedule.assignments =
    cleanedAssignments;

  schedule.subjects =
    cleanedSubjectPlans;

  schedule.version =
    Number(
      schedule.version || 1
    ) + 1;

  await schedule.save();

  /*
   * StudyDay is derived from assignments, so rebuild it
   * whenever stale records were removed.
   */
  await rebuildStudyDays(
    schedule
  );

  console.log(
    `[SCHEDULE CLEANUP] Removed ${removedAssignments} stale assignment(s) and ${removedTopicReferences} stale topic reference(s) for user ${userId}.`
  );

  return {
    changed: true,
    removedAssignments,
    removedTopicReferences,
  };
};

/*
 * =========================================================
 * GET CURRENT SCHEDULE
 * =========================================================
 */

const getSchedule =
  async (req, res) => {
    try {
      let schedule =
        await StudySchedule.findOne({
          userId: req.userId,
        });

      if (!schedule) {
        return res.status(200).json({
          success: true,
          schedule: null,
        });
      }

      /*
       * Remove stale assignments whose topics, units,
       * or subjects no longer exist.
       */
      const assignments =
        Array.isArray(schedule.assignments)
          ? schedule.assignments
          : [];

      const topicIds = [
        ...new Set(
          assignments
            .map((item) =>
              item.topicId
                ? String(item.topicId)
                : null
            )
            .filter(Boolean)
        ),
      ];

      const unitIds = [
        ...new Set(
          assignments
            .map((item) =>
              item.unitId
                ? String(item.unitId)
                : null
            )
            .filter(Boolean)
        ),
      ];

      const subjectIds = [
        ...new Set(
          assignments
            .map((item) =>
              item.subjectId
                ? String(item.subjectId)
                : null
            )
            .filter(Boolean)
        ),
      ];

      const [
        topics,
        units,
        subjects,
      ] = await Promise.all([
        topicIds.length > 0
          ? Topic.find({
              _id: {
                $in: topicIds,
              },
              userId: req.userId,
            }).lean()
          : [],

        unitIds.length > 0
          ? Unit.find({
              _id: {
                $in: unitIds,
              },
              userId: req.userId,
            }).lean()
          : [],

        subjectIds.length > 0
          ? Subject.find({
              _id: {
                $in: subjectIds,
              },
              userId: req.userId,
            }).lean()
          : [],
      ]);

      const topicMap =
        new Map(
          topics.map((topic) => [
            String(topic._id),
            topic,
          ])
        );

      const unitMap =
        new Map(
          units.map((unit) => [
            String(unit._id),
            unit,
          ])
        );

      const subjectMap =
        new Map(
          subjects.map((subject) => [
            String(subject._id),
            subject,
          ])
        );

      const beforeCount =
        schedule.assignments.length;

      schedule.assignments =
        schedule.assignments.filter(
          (assignment) => {
            const topicId =
              assignment.topicId
                ? String(
                    assignment.topicId
                  )
                : null;

            const unitId =
              assignment.unitId
                ? String(
                    assignment.unitId
                  )
                : null;

            const subjectId =
              assignment.subjectId
                ? String(
                    assignment.subjectId
                  )
                : null;

            if (
              !topicId ||
              !unitId ||
              !subjectId
            ) {
              return false;
            }

            const topic =
              topicMap.get(
                topicId
              );

            const unit =
              unitMap.get(
                unitId
              );

            const subject =
              subjectMap.get(
                subjectId
              );

            /*
             * Deleted topic/unit/subject.
             */
            if (
              !topic ||
              !unit ||
              !subject
            ) {
              return false;
            }

            /*
             * Verify the relationships.
             */
            if (
              String(
                topic.subjectId
              ) !== subjectId
            ) {
              return false;
            }

            if (
              String(
                topic.unitId
              ) !== unitId
            ) {
              return false;
            }

            if (
              String(
                unit.subjectId
              ) !== subjectId
            ) {
              return false;
            }

            /*
             * Completed topics cannot remain active.
             */
            if (
              assignment.status ===
                "planned" &&
              topic.completed === true
            ) {
              return false;
            }

            return true;
          }
        );

      /*
       * Save only if stale records were actually removed.
       */
      if (
        schedule.assignments.length !==
        beforeCount
      ) {
        schedule.version =
          Number(
            schedule.version || 1
          ) + 1;

        await schedule.save();

        await rebuildStudyDays(
          schedule
        );

        console.log(
          `[SCHEDULE CLEANUP] Removed ${
            beforeCount -
            schedule.assignments.length
          } stale assignment(s).`
        );
      }

      /*
       * Reload the authoritative database state.
       */
      schedule =
        await StudySchedule.findOne({
          userId: req.userId,
        });

      if (!schedule) {
        return res.status(200).json({
          success: true,
          schedule: null,
        });
      }

      const enriched =
        await enrichSchedule(
          schedule
        );

      return res.status(200).json({
        success: true,
        schedule: enriched,
      });
    } catch (error) {
      console.error(
        "Get schedule error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Failed to retrieve study schedule.",
      });
    }
  };

/*
 * =========================================================
 * COMPLETE SCHEDULED TOPIC
 * =========================================================
 *
 * Completion NEVER triggers rescheduling.
 */

const completeScheduledTopic =
  async (req, res) => {
    try {
      const userId =
        req.userId;

      const {
        topicId,
        date,
      } = req.body || {};

      if (
        !topicId ||
        !date
      ) {
        return res.status(400).json({
          success: false,
          message:
            "topicId and date are required.",
        });
      }

      if (
        !isValidObjectId(
          topicId
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid topic ID.",
        });
      }

      const targetDate =
        parseDate(date);

      if (
        !targetDate ||
        !isStudyDay(
          targetDate
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "The selected schedule date is invalid.",
        });
      }

      const schedule =
        await StudySchedule.findOne({
          userId,
        });

      if (!schedule) {
        return res.status(404).json({
          success: false,
          message:
            "No active study plan found.",
        });
      }

      const assignment =
        schedule.assignments.find(
          (item) =>
            String(
              item.topicId
            ) ===
              String(
                topicId
              ) &&
            item.date ===
              date &&
            item.status ===
              "planned"
        );

      if (!assignment) {
        return res.status(404).json({
          success: false,
          message:
            "Scheduled topic was not found or is already completed.",
        });
      }

      const topic =
        await Topic.findOne({
          _id:
            topicId,
          userId,
        });

      if (!topic) {
        return res.status(404).json({
          success: false,
          message:
            "Topic not found.",
        });
      }

      const completionDate =
        new Date();

      assignment.status =
        "completed";

      assignment.completedAt =
        completionDate;

      topic.completed =
        true;

      topic.completedAt =
        completionDate;

      await topic.save();

      await schedule.save();

      /*
       * Rebuild derived daily information.
       *
       * NO RESCHEDULING HERE.
       */
      await rebuildStudyDays(
        schedule
      );

      const enriched =
        await enrichSchedule(
          schedule
        );

      return res.status(200).json({
        success: true,

        message:
          "Topic completed successfully.",

        schedule:
          enriched,
      });
    } catch (error) {
      console.error(
        "Complete scheduled topic error:",
        error
      );

      return res.status(500).json({
        success: false,
        message:
          "Failed to complete topic.",
      });
    }
  };

/*
 * =========================================================
 * RESCHEDULE REMAINING TOPICS
 * =========================================================
 *
 * This endpoint is called ONLY after the user chooses SKIP.
 *
 * It recalculates remaining active topics against each
 * topic's own subject deadline.
 */

const skipRemainingTopics =
  async (req, res) => {
    try {
      const userId =
        req.userId;

      const {
        date,
        allowOverCapacity =
          false,
      } = req.body || {};

      if (!date) {
        return res.status(400).json({
          success: false,
          message:
            "date is required.",
        });
      }

      const currentDate =
        parseDate(date);

      if (
        !currentDate ||
        !isStudyDay(
          currentDate
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid study date.",
        });
      }

      const schedule =
        await StudySchedule.findOne({
          userId,
        });

      if (!schedule) {
        return res.status(404).json({
          success: false,
          message:
            "No active study plan found.",
        });
      }

      /*
       * Today's remaining active assignments.
       */
      const remaining =
        schedule.assignments.filter(
          (item) =>
            item.date ===
              date &&
            item.status ===
              "planned"
        );

      if (
        remaining.length ===
        0
      ) {
        const enriched =
          await enrichSchedule(
            schedule
          );

        return res.status(200).json({
          success: true,
          message:
            "There are no remaining topics for this date.",
          schedule:
            enriched,
        });
      }

      /*
       * Resolve remaining topics.
       */
      const topicIds =
        remaining.map(
          (item) =>
            item.topicId
        );

      const topics =
        await Topic.find({
          _id: {
            $in:
              topicIds,
          },
          userId,
          completed:
            false,
        }).lean();

      if (
        topics.length ===
        0
      ) {
        /*
         * Remove stale planned assignments if their topics
         * were completed elsewhere.
         */
        for (
          const assignment of
            remaining
        ) {
          assignment.status =
            "completed";

          assignment.completedAt =
            new Date();
        }

        await schedule.save();

        await rebuildStudyDays(
          schedule
        );

        const enriched =
          await enrichSchedule(
            schedule
          );

        return res.status(200).json({
          success: true,
          message:
            "All remaining topics were already completed.",
          schedule:
            enriched,
        });
      }

      /*
       * Subject plans are the source of each topic's deadline.
       */
      const subjectPlanMap =
        buildSubjectDateMap(
          schedule.subjects
        );

      /*
       * Resolve units.
       */
      const unitIds =
        [
          ...new Set(
            topics
              .map(
                (topic) =>
                  topic.unitId
              )
              .filter(Boolean)
              .map(String)
          ),
        ];

      const units =
        unitIds.length > 0
          ? await Unit.find({
              _id: {
                $in:
                  unitIds,
              },
              userId,
            }).lean()
          : [];

      const unitMap =
        new Map(
          units.map(
            (unit) => [
              String(
                unit._id
              ),
              unit,
            ]
          )
        );

      /*
       * Resolve subjects.
       */
      const subjectIds =
        [
          ...new Set(
            topics.map(
              (topic) =>
                String(
                  topic.subjectId
                )
            )
          ),
        ];

      const subjects =
        await Subject.find({
          _id: {
            $in:
              subjectIds,
          },
          userId,
        }).lean();

      const subjectMap =
        new Map(
          subjects.map(
            (subject) => [
              String(
                subject._id
              ),
              subject,
            ]
          )
        );

      const remainingTopics =
        topics
          .map(
            (topic) => {
              const subjectId =
                String(
                  topic.subjectId
                );

              const subject =
                subjectMap.get(
                  subjectId
                );

              const unit =
                topic.unitId
                  ? unitMap.get(
                      String(
                        topic.unitId
                      )
                    )
                  : null;

              const plan =
                subjectPlanMap.get(
                  subjectId
                );

              if (
                !subject ||
                !unit ||
                !plan
              ) {
                return null;
              }

              const oldAssignment =
                remaining.find(
                  (item) =>
                    String(
                      item.topicId
                    ) ===
                    String(
                      topic._id
                    )
                );

              return {
                topicId:
                  String(
                    topic._id
                  ),

                name:
                  topic.name,

                subjectId,

                subjectName:
                  subject.name,

                unitId:
                  String(
                    unit._id
                  ),

                unitNumber:
                  unit.unitNumber,

                unitName:
                  unit.name,

                subjectStartDate:
                  plan.startDate,

                subjectDeadline:
                  plan.deadline,

                subjectPerformance:
                  calculatePerformance(
                    subject
                  ),

                skipCount:
                  Number(
                    oldAssignment?.skipCount ||
                      0
                  ) + 1,
              };
            }
          )
          .filter(Boolean);

      if (
        remainingTopics.length ===
        0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "The remaining topics could not be resolved to their subject and unit.",
        });
      }

      /*
       * Mark today's assignments as skipped.
       *
       * Historical records remain.
       */
      for (
        const assignment of
          remaining
      ) {
        assignment.status =
          "skipped";

        assignment.skippedFromDate =
          date;

        assignment.skipCount =
          Number(
            assignment.skipCount ||
              0
          ) + 1;
      }

      /*
       * Existing future active assignments remain part of the
       * schedule and act as load context.
       */
      const futureActive =
        getActiveAssignments(
          schedule
        ).filter(
          (assignment) =>
            assignment.date >
            date
        );

      /*
       * LLM sees the current remaining work and existing
       * future workload.
       */
      const availableDates =
        buildAvailableDatesForTopics(
          remainingTopics
        ).filter(
          (candidateDate) =>
            candidateDate >
            date
        );

      /*
       * If no future dates exist, the topics remain unscheduled.
       */
      if (
        availableDates.length ===
        0
      ) {
        await schedule.save();

        await rebuildStudyDays(
          schedule
        );

        const enriched =
          await enrichSchedule(
            schedule
          );

        return res.status(200).json({
          success: true,

          message:
            "Incomplete topics are recorded as skipped because no valid future study dates remain before their deadlines.",

          schedule:
            enriched,
        });
      }

      const llmProposal =
        await generateScheduleProposal({
          subjects:
            subjects.map(
              (subject) => {
                const plan =
                  subjectPlanMap.get(
                    String(
                      subject._id
                    )
                  );

                return {
                  subjectId:
                    String(
                      subject._id
                    ),

                  name:
                    subject.name,

                  startDate:
                    plan?.startDate,

                  deadline:
                    plan?.deadline,

                  exams:
                    subject.exams ||
                    {},

                  units:
                    [],
                };
              }
            ),

          topics:
            remainingTopics,

          availableDates,

          dailyNormalCapacity:
            NORMAL_DAILY_CAPACITY,

          previousAssignments:
            futureActive.map(
              (item) => ({
                date:
                  item.date,

                topicId:
                  String(
                    item.topicId
                  ),

                subjectId:
                  String(
                    item.subjectId
                  ),

                unitId:
                  item.unitId
                    ? String(
                        item.unitId
                      )
                    : null,
              })
            ),

          mode:
            "reschedule",
        });

      /*
       * Existing future assignments are used as load.
       */
      const validation =
        validateAssignments({
          assignments:
            llmProposal.assignments,

          topics:
            remainingTopics,

          existingAssignments:
            futureActive,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      const repaired =
        repairAssignments({
          topics:
            remainingTopics,

          validated:
            validation,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      const finalValidation =
        validateAssignments({
          assignments:
            repaired,

          topics:
            remainingTopics,

          existingAssignments:
            futureActive,

          allowOverCapacity:
            Boolean(
              allowOverCapacity
            ),
        });

      /*
       * Add newly scheduled assignments.
       */
      for (
        const assignment of
          finalValidation.valid
      ) {
        const topic =
          remainingTopics.find(
            (item) =>
              String(
                item.topicId
              ) ===
              String(
                assignment.topicId
              )
          );

        if (!topic) {
          continue;
        }

        const previous =
          remaining.find(
            (item) =>
              String(
                item.topicId
              ) ===
              String(
                assignment.topicId
              )
          );

        schedule.assignments.push({
          date:
            assignment.date,

          topicId:
            assignment.topicId,

          unitId:
            topic.unitId,

          subjectId:
            topic.subjectId,

          status:
            "planned",

          skippedFromDate:
            date,

          skipCount:
            Number(
              previous?.skipCount ||
                0
            ) + 1,

          completedAt:
            null,
        });
      }

      schedule.version =
        Number(
          schedule.version ||
            1
        ) + 1;

      schedule.lastRescheduledAt =
        new Date();

      schedule.reasoning =
        llmProposal.strategy;

      schedule.planningSource =
        llmProposal.llmAvailable
          ? "llm+repair"
          : "adaptive-fallback";

      await schedule.save();

      await rebuildStudyDays(
        schedule
      );

      const enriched =
        await enrichSchedule(
          schedule
        );

      return res.status(200).json({
        success: true,

        message:
          "Incomplete topics are rescheduled to upcoming days.",

        schedule:
          enriched,
      });
    } catch (error) {
      console.error(
        "Skip remaining topics error:",
        error
      );

      return res.status(400).json({
        success: false,
        message:
          error?.message ||
          "Failed to reschedule remaining topics.",
      });
    }
  };

/*
 * =========================================================
 * EXPORTS
 * =========================================================
 */

module.exports = {
  generateSchedule,
  getSchedule,
  completeScheduledTopic,
  skipRemainingTopics,
};