const express = require("express");

const {
  getProgress,
} = require("../controllers/progressController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

/*
 * Every progress request must belong to
 * the authenticated user.
 */
router.use(authMiddleware);

/*
 * GET /api/progress
 */
router.get("/", getProgress);

module.exports = router;