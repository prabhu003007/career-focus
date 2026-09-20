const express = require("express");

const authMiddleware =
  require("../middleware/authMiddleware");

const {
  getAcademicCopilot,
} = require("../controllers/aiController");

const router = express.Router();

router.post(
  "/copilot",
  authMiddleware,
  getAcademicCopilot
);

module.exports = router;