const express = require("express");

const {
  getUnitsBySubject,
  createUnit,
  updateUnit,
  deleteUnit,
} = require("../controllers/unitController");

const authMiddleware =
  require("../middleware/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

router.get(
  "/subject/:subjectId",
  getUnitsBySubject
);

router.post(
  "/",
  createUnit
);

router.put(
  "/:id",
  updateUnit
);

router.delete(
  "/:id",
  deleteUnit
);

module.exports = router;