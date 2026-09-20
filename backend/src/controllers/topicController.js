const Topic = require("../models/Topic");
const Subject = require("../models/Subject");
const Unit = require("../models/Unit");
const StudySchedule = require("../models/StudySchedule");

// =========================================================
// GET TOPICS BY SUBJECT
// =========================================================

const getTopicsBySubject = async (
  req,
  res
) => {
  try {
    const { subjectId } = req.params;

    const subject = await Subject.findOne({
      _id: subjectId,
      userId: req.userId,
    });

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: "Subject not found",
      });
    }

    const topics = await Topic.find({
      userId: req.userId,
      subjectId,
    }).sort({
      createdAt: 1,
    });

    res.json({
      success: true,
      topics,
    });
  } catch (error) {
    console.error(
      "Get topics error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to fetch topics",
    });
  }
};

// =========================================================
// GET TOPICS BY UNIT
// =========================================================

const getTopicsByUnit = async (
  req,
  res
) => {
  try {
    const { unitId } = req.params;

    const unit = await Unit.findOne({
      _id: unitId,
      userId: req.userId,
    });

    if (!unit) {
      return res.status(404).json({
        success: false,
        message: "Unit not found",
      });
    }

    const topics = await Topic.find({
      userId: req.userId,
      subjectId: unit.subjectId,
      unitId: unit._id,
    }).sort({
      createdAt: 1,
    });

    res.json({
      success: true,
      topics,
    });
  } catch (error) {
    console.error(
      "Get unit topics error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Failed to fetch unit topics",
    });
  }
};

// =========================================================
// CREATE TOPIC
// =========================================================

const createTopic = async (
  req,
  res
) => {
  try {
    const {
      subjectId,
      unitId,
      name,
    } = req.body;

    if (!subjectId) {
      return res.status(400).json({
        success: false,
        message: "Subject ID is required",
      });
    }

    if (!unitId) {
      return res.status(400).json({
        success: false,
        message: "Unit ID is required",
      });
    }

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Topic name is required",
      });
    }

    const unit = await Unit.findOne({
      _id: unitId,
      subjectId,
      userId: req.userId,
    });

    if (!unit) {
      return res.status(404).json({
        success: false,
        message:
          "Unit not found for this subject",
      });
    }

    const topic = await Topic.create({
      userId: req.userId,
      subjectId,
      unitId,
      name: name.trim(),
    });

    res.status(201).json({
      success: true,
      message:
        "Topic created successfully",
      topic,
    });
  } catch (error) {
    console.error(
      "Create topic error:",
      error
    );

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message:
          "Topic already exists in this unit",
      });
    }

    res.status(500).json({
      success: false,
      message:
        "Failed to create topic",
    });
  }
};

// =========================================================
// UPDATE TOPIC
// =========================================================

const updateTopic = async (
  req,
  res
) => {
  try {
    const { id } = req.params;

    const {
      name,
      completed,
    } = req.body;

    const topic = await Topic.findOne({
      _id: id,
      userId: req.userId,
    });

    if (!topic) {
      return res.status(404).json({
        success: false,
        message: "Topic not found",
      });
    }

    if (name !== undefined) {
      if (!name.trim()) {
        return res.status(400).json({
          success: false,
          message:
            "Topic name cannot be empty",
        });
      }

      topic.name = name.trim();
    }

    if (completed !== undefined) {
      topic.completed =
        Boolean(completed);

      topic.completedAt =
        topic.completed
          ? new Date()
          : null;
    }

    await topic.save();

    res.json({
      success: true,
      message:
        "Topic updated successfully",
      topic,
    });
  } catch (error) {
    console.error(
      "Update topic error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Failed to update topic",
    });
  }
};

// =========================================================
// DELETE TOPIC
//
// IMPORTANT:
// Deleting a topic must also remove it from the
// user's active study plan.
//
// This prevents:
//   Topic deleted
//        ↓
//   stale schedule assignment
//        ↓
//   deleted topic appearing again in Schedule
// =========================================================

const deleteTopic = async (
  req,
  res
) => {
  try {
    const { id } = req.params;

    // -------------------------------------------------------
    // Find first so we can verify ownership and retain
    // the topic ID before removing schedule references.
    // -------------------------------------------------------

    const topic = await Topic.findOne({
      _id: id,
      userId: req.userId,
    });

    if (!topic) {
      return res.status(404).json({
        success: false,
        message: "Topic not found",
      });
    }

    // -------------------------------------------------------
    // Delete the actual topic.
    // -------------------------------------------------------

    await Topic.deleteOne({
      _id: topic._id,
      userId: req.userId,
    });

    // -------------------------------------------------------
    // Clean the user's study schedule.
    //
    // 1. Remove the topic from configured subject plans.
    // 2. Remove every schedule assignment for this topic.
    //
    // The userId condition guarantees that one user's
    // deletion cannot modify another user's schedule.
    // -------------------------------------------------------

    const schedule = await StudySchedule.findOne({
      userId: req.userId,
    });

    if (schedule) {
      const topicIdString =
        topic._id.toString();

      // -----------------------------------------------------
      // Remove topic from subject plan topicIds.
      // -----------------------------------------------------

      for (const subjectPlan of schedule.subjects) {
        if (!Array.isArray(subjectPlan.units)) {
          continue;
        }

        for (const unitPlan of subjectPlan.units) {
          if (!Array.isArray(unitPlan.topicIds)) {
            continue;
          }

          unitPlan.topicIds =
            unitPlan.topicIds.filter(
              (topicId) =>
                topicId?.toString() !==
                topicIdString
            );
        }
      }

      // -----------------------------------------------------
      // Remove all schedule assignments belonging to topic.
      //
      // This removes:
      // - today's assignment
      // - future planned assignments
      // - old completed/skipped assignment records
      //
      // The deleted topic should no longer exist anywhere
      // inside the active study schedule.
      // -----------------------------------------------------

      schedule.assignments =
        schedule.assignments.filter(
          (assignment) =>
            assignment.topicId?.toString() !==
            topicIdString
        );

      // -----------------------------------------------------
      // Remove empty unit plans from each subject.
      // -----------------------------------------------------

      for (const subjectPlan of schedule.subjects) {
        if (!Array.isArray(subjectPlan.units)) {
          continue;
        }

        subjectPlan.units =
          subjectPlan.units.filter(
            (unitPlan) =>
              Array.isArray(
                unitPlan.topicIds
              ) &&
              unitPlan.topicIds.length > 0
          );
      }

      // -----------------------------------------------------
      // Remove empty subject plans.
      // -----------------------------------------------------

      schedule.subjects =
        schedule.subjects.filter(
          (subjectPlan) =>
            Array.isArray(
              subjectPlan.units
            ) &&
            subjectPlan.units.length > 0
        );

      // -----------------------------------------------------
      // Save cleaned schedule.
      // -----------------------------------------------------

      schedule.version =
        (schedule.version || 1) + 1;

      await schedule.save();
    }

    res.json({
      success: true,
      message:
        "Topic deleted successfully",
    });
  } catch (error) {
    console.error(
      "Delete topic error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Failed to delete topic",
    });
  }
};

// =========================================================
// EXPORTS
// =========================================================

module.exports = {
  getTopicsBySubject,
  getTopicsByUnit,
  createTopic,
  updateTopic,
  deleteTopic,
};