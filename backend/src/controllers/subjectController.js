const Subject =
  require("../models/Subject");

const Topic =
  require("../models/Topic");

const StudySchedule =
  require("../models/StudySchedule");

const StudyDay =
  require("../models/StudyDay");

const User =
  require("../models/User");

const getSubjects = async (
  req,
  res
) => {
  try {
    const user =
      await User.findById(
        req.userId
      );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const subjects =
      await Subject.find({
        userId: req.userId,
      }).sort({
        createdAt: 1,
      });

    const currentYear =
      user.academicYear;

    const result =
      subjects.map(
        (subject) => {
          const data =
            subject.toObject();

          /*
           * Only expose marks belonging
           * to the current academic year.
           *
           * Previous-year marks remain
           * safely stored in examHistory.
           */
          if (
            data.exams?.academicYear !==
            currentYear
          ) {
            data.exams = {
              assess1: null,
              assess2: null,
              endSem: null,
              academicYear:
                currentYear,
            };
          }

          return data;
        }
      );

    res.json({
      success: true,
      academicYear: currentYear,
      subjects: result,
    });
  } catch (error) {
    console.error(
      "Get subjects error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Failed to fetch subjects",
    });
  }
};

const createSubject = async (
  req,
  res
) => {
  try {
    const {
      name,
      code,
      description,
    } = req.body;

    if (!name?.trim()) {
      return res.status(400).json({
        success: false,
        message:
          "Subject name is required",
      });
    }

    const user =
      await User.findById(
        req.userId
      );

    const subject =
      await Subject.create({
        userId: req.userId,
        name: name.trim(),
        code:
          code?.trim() || "",
        description:
          description?.trim() || "",
        exams: {
          assess1: null,
          assess2: null,
          endSem: null,
          academicYear:
            user?.academicYear || 1,
        },
      });

    res.status(201).json({
      success: true,
      message:
        "Subject created successfully",
      subject,
    });
  } catch (error) {
    console.error(
      "Create subject error:",
      error
    );

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message:
          "Subject already exists",
      });
    }

    res.status(500).json({
      success: false,
      message:
        "Failed to create subject",
    });
  }
};

const updateSubject = async (
  req,
  res
) => {
  try {
    const { id } = req.params;

    const {
      name,
      code,
      description,
      exams,
    } = req.body;

    const user =
      await User.findById(
        req.userId
      );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const subject =
      await Subject.findOne({
        _id: id,
        userId: req.userId,
      });

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: "Subject not found",
      });
    }

    if (name !== undefined) {
      subject.name =
        name.trim();
    }

    if (code !== undefined) {
      subject.code =
        code.trim();
    }

    if (description !== undefined) {
      subject.description =
        description.trim();
    }

    if (exams !== undefined) {
      subject.exams = {
        assess1:
          exams.assess1 ??
          null,

        assess2:
          exams.assess2 ??
          null,

        endSem:
          exams.endSem ??
          null,

        academicYear:
          user.academicYear,
      };
    }

    await subject.save();

    let promoted = false;
    let nextYear =
      user.academicYear;

    /*
     * Automatic progression:
     *
     * Every active subject must have
     * an End Sem mark for the current
     * academic year.
     */
    if (
      exams !== undefined &&
      exams.endSem !== undefined &&
      exams.endSem !== null &&
      user.academicYear < 4
    ) {
      const subjects =
        await Subject.find({
          userId: req.userId,
        });

      const allSubjectsCompleted =
        subjects.length > 0 &&
        subjects.every(
          (item) =>
            item.exams?.academicYear ===
              user.academicYear &&
            item.exams?.endSem !==
              null &&
            item.exams?.endSem !==
              undefined
        );

      if (allSubjectsCompleted) {
        const completedYear =
          user.academicYear;

        nextYear =
          completedYear + 1;

        /*
         * Archive the completed
         * academic year's marks.
         */
        for (
          const item of subjects
        ) {
          item.examHistory.push({
            academicYear:
              completedYear,

            assess1:
              item.exams.assess1,

            assess2:
              item.exams.assess2,

            endSem:
              item.exams.endSem,
          });

          item.exams = {
            assess1: null,
            assess2: null,
            endSem: null,
            academicYear:
              nextYear,
          };

          await item.save();
        }

        user.academicYear =
          nextYear;

        await user.save();

        promoted = true;
      }
    }

    const responseSubject =
      subject.toObject();

    if (promoted) {
      responseSubject.exams = {
        assess1: null,
        assess2: null,
        endSem: null,
        academicYear:
          nextYear,
      };
    }

    res.json({
      success: true,
      message: promoted
        ? `End Sem cycle completed. Academic year advanced to ${nextYear}.`
        : "Subject updated successfully",

      promoted,
      academicYear:
        nextYear,

      subject:
        responseSubject,
    });
  } catch (error) {
    console.error(
      "Update subject error:",
      error
    );

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message:
          "Subject already exists",
      });
    }

    res.status(500).json({
      success: false,
      message:
        "Failed to update subject",
    });
  }
};

const deleteSubject = async (
  req,
  res
) => {
  try {
    const { id } = req.params;

    const subject =
      await Subject.findOneAndDelete({
        _id: id,
        userId: req.userId,
      });

    if (!subject) {
      return res.status(404).json({
        success: false,
        message:
          "Subject not found",
      });
    }

    const topicResult =
      await Topic.deleteMany({
        userId: req.userId,
        subjectId: id,
      });

    await StudySchedule.updateMany(
      {
        userId: req.userId,
      },
      {
        $pull: {
          assignments: {
            subjectId: id,
          },
        },
      }
    );

    await StudyDay.updateMany(
      {
        userId: req.userId,
      },
      {
        $pull: {
          subjectIds: id,
        },
      }
    );

    await StudyDay.deleteMany({
      userId: req.userId,
      subjectIds: {
        $size: 0,
      },
    });

    res.json({
      success: true,
      message:
        "Subject deleted successfully",
      deletedTopicCount:
        topicResult.deletedCount,
    });
  } catch (error) {
    console.error(
      "Delete subject error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Failed to delete subject",
    });
  }
};

module.exports = {
  getSubjects,
  createSubject,
  updateSubject,
  deleteSubject,
};