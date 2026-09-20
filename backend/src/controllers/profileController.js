const User = require("../models/User");

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(
      req.userId
    ).select("-pinHash");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      profile: {
        id: user._id,
        email: user.email,
        emailVerified: user.emailVerified,

        name: user.name,
        collegeName: user.collegeName,
        degree: user.degree,
        course: user.course,

        academicYear:
          user.academicYear,

        profileCompleted:
          user.profileCompleted,

        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error(
      "Get profile error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to retrieve profile",
    });
  }
};

const updateProfile = async (
  req,
  res
) => {
  try {
    const {
      name,
      collegeName,
      degree,
      course,
      academicYear,
    } = req.body;

    if (
      !name?.trim() ||
      !collegeName?.trim() ||
      !degree?.trim() ||
      !course?.trim()
    ) {
      return res.status(400).json({
        success: false,
        message:
          "All academic profile fields are required",
      });
    }

    const year =
      Number(academicYear);

    if (
      !Number.isInteger(year) ||
      year < 1 ||
      year > 4
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Academic year must be between 1 and 4",
      });
    }

    const user =
      await User.findByIdAndUpdate(
        req.userId,
        {
          name: name.trim(),
          collegeName:
            collegeName.trim(),
          degree: degree.trim(),
          course: course.trim(),
          academicYear: year,
          profileCompleted: true,
        },
        {
          new: true,
          runValidators: true,
        }
      ).select("-pinHash");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      message:
        "Academic profile saved successfully",
      profile: {
        id: user._id,
        email: user.email,
        name: user.name,
        collegeName:
          user.collegeName,
        degree: user.degree,
        course: user.course,
        academicYear:
          user.academicYear,
        profileCompleted:
          user.profileCompleted,
      },
    });
  } catch (error) {
    console.error(
      "Update profile error:",
      error
    );

    res.status(500).json({
      success: false,
      message:
        "Unable to update profile",
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
};