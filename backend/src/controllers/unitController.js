const Unit = require("../models/Unit");
const Subject = require("../models/Subject");
const Topic = require("../models/Topic");

const getUnitsBySubject = async (req, res) => {
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

    const units = await Unit.find({
      userId: req.userId,
      subjectId,
    }).sort({
      unitNumber: 1,
    });

    const result = await Promise.all(
      units.map(async (unit) => {
        const topics = await Topic.find({
          userId: req.userId,
          subjectId,
          unitId: unit._id,
        }).select(
          "completed completedAt"
        );

        const completed = topics.filter(
          (topic) => topic.completed
        ).length;

        return {
          ...unit.toObject(),
          topicCount: topics.length,
          completedCount: completed,
          remainingCount:
            topics.length - completed,
        };
      })
    );

    res.json({
      success: true,
      units: result,
    });
  } catch (error) {
    console.error(
      "Get units error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to fetch units",
    });
  }
};

const createUnit = async (req, res) => {
  try {
    const {
      subjectId,
      unitNumber,
      name,
    } = req.body;

    if (!subjectId) {
      return res.status(400).json({
        success: false,
        message: "Subject ID is required",
      });
    }

    const number = Number(unitNumber);

    if (
      !Number.isInteger(number) ||
      number < 1
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Unit number must be a positive integer",
      });
    }

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Unit name is required",
      });
    }

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

    const unit = await Unit.create({
      userId: req.userId,
      subjectId,
      unitNumber: number,
      name: name.trim(),
    });

    res.status(201).json({
      success: true,
      message: "Unit created successfully",
      unit,
    });
  } catch (error) {
    console.error(
      "Create unit error:",
      error
    );

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message:
          "A unit with this number or name already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create unit",
    });
  }
};

const updateUnit = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      unitNumber,
      name,
    } = req.body;

    const unit = await Unit.findOne({
      _id: id,
      userId: req.userId,
    });

    if (!unit) {
      return res.status(404).json({
        success: false,
        message: "Unit not found",
      });
    }

    if (unitNumber !== undefined) {
      const number = Number(unitNumber);

      if (
        !Number.isInteger(number) ||
        number < 1
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Unit number must be a positive integer",
        });
      }

      unit.unitNumber = number;
    }

    if (name !== undefined) {
      if (!name.trim()) {
        return res.status(400).json({
          success: false,
          message:
            "Unit name cannot be empty",
        });
      }

      unit.name = name.trim();
    }

    await unit.save();

    res.json({
      success: true,
      message: "Unit updated successfully",
      unit,
    });
  } catch (error) {
    console.error(
      "Update unit error:",
      error
    );

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message:
          "A unit with this number or name already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to update unit",
    });
  }
};

const deleteUnit = async (req, res) => {
  try {
    const { id } = req.params;

    const unit = await Unit.findOne({
      _id: id,
      userId: req.userId,
    });

    if (!unit) {
      return res.status(404).json({
        success: false,
        message: "Unit not found",
      });
    }

    await Topic.deleteMany({
      userId: req.userId,
      unitId: unit._id,
    });

    await Unit.deleteOne({
      _id: unit._id,
      userId: req.userId,
    });

    res.json({
      success: true,
      message:
        "Unit and its topics deleted successfully",
    });
  } catch (error) {
    console.error(
      "Delete unit error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to delete unit",
    });
  }
};

module.exports = {
  getUnitsBySubject,
  createUnit,
  updateUnit,
  deleteUnit,
};