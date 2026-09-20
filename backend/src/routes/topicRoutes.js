const express = require("express");

const {
  getTopicsBySubject,
  getTopicsByUnit,
  createTopic,
  updateTopic,
  deleteTopic,
} = require("../controllers/topicController");

const authMiddleware =
  require("../middleware/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

router.get(
  "/subject/:subjectId",
  getTopicsBySubject
);

router.get(
  "/unit/:unitId",
  getTopicsByUnit
);

router.post(
  "/",
  createTopic
);

router.put(
  "/:id",
  updateTopic
);

router.delete(
  "/:id",
  deleteTopic
);

module.exports = router;