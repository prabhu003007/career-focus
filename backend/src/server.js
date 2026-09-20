const dns = require("dns");

dns.setDefaultResultOrder("ipv4first");

const express = require("express");
const cors = require("cors");

require("dotenv").config();

const connectDatabase =
  require("./config/database");

const authRoutes =
  require("./routes/authRoutes");

const subjectRoutes =
  require("./routes/subjectRoutes");

const topicRoutes =
  require("./routes/topicRoutes");

const scheduleRoutes =
  require("./routes/scheduleRoutes");

const progressRoutes =
  require("./routes/progressRoutes");

const aiRoutes =
  require("./routes/aiRoutes");

const profileRoutes =
  require("./routes/profileRoutes");

const unitRoutes =
  require("./routes/unitRoutes");

const app = express();

// ============================================================
// GLOBAL MIDDLEWARE
// ============================================================

app.use(
  cors({
    origin: true,
    credentials: true,
  })
);

// Parse JSON request bodies.
// This is required for POST/PUT requests such as /api/units.
app.use(
  express.json({
    limit: "1mb",
  })
);

// Parse URL-encoded request bodies.
app.use(
  express.urlencoded({
    extended: true,
  })
);

// ============================================================
// API ROUTES
// ============================================================

app.use(
  "/api/auth",
  authRoutes
);

app.use(
  "/api/profile",
  profileRoutes
);

app.use(
  "/api/subjects",
  subjectRoutes
);

app.use(
  "/api/topics",
  topicRoutes
);

app.use(
  "/api/units",
  unitRoutes
);

app.use(
  "/api/schedule",
  scheduleRoutes
);

app.use(
  "/api/progress",
  progressRoutes
);

app.use(
  "/api/ai",
  aiRoutes
);

// ============================================================
// HEALTH CHECK
// ============================================================

app.get(
  "/api/health",
  (req, res) => {
    res.status(200).json({
      success: true,
      application: "Career Focus",
      message: "Career Focus API is running",
    });
  }
);

// ============================================================
// 404 HANDLER
// ============================================================

app.use(
  (req, res) => {
    res.status(404).json({
      success: false,
      message: "API endpoint not found",
    });
  }
);

// ============================================================
// GLOBAL ERROR HANDLER
// ============================================================

app.use(
  (
    error,
    req,
    res,
    next
  ) => {
    console.error(
      "Unhandled server error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
);

// ============================================================
// SERVER START
// ============================================================

const PORT =
  process.env.PORT || 5000;

const startServer =
  async () => {
    try {
      await connectDatabase();

      app.listen(
        PORT,
        "0.0.0.0",
        () => {
          console.log(
            `Career Focus API running on port ${PORT}`
          );
        }
      );
    } catch (error) {
      console.error(
        "Server startup failed:",
        error
      );

      process.exit(1);
    }
  };

startServer();