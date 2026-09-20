const express = require("express");

const {
  generateSchedule,
  getSchedule,
  completeScheduledTopic,
  skipRemainingTopics,
} = require("../controllers/scheduleController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

/*
 * Every schedule endpoint requires an authenticated user.
 */
router.use(authMiddleware);

/*
 * GET
 * /api/schedule
 *
 * Returns the user's current active study plan.
 */
router.get(
  "/",
  getSchedule
);

/*
 * POST
 * /api/schedule/generate
 *
 * Creates or merges a study plan.
 */
router.post(
  "/generate",
  generateSchedule
);

/*
 * POST
 * /api/schedule/complete
 *
 * Marks one scheduled topic as completed.
 *
 * IMPORTANT:
 * This does NOT reschedule anything.
 */
router.post(
  "/complete",
  completeScheduledTopic
);

/*
 * POST
 * /api/schedule/skip-remaining
 *
 * Called only after the user chooses SKIP at the
 * end of the day.
 *
 * This triggers rescheduling.
 */
router.post(
  "/skip-remaining",
  skipRemainingTopics
);

module.exports = router;