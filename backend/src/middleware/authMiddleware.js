const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    console.log(
      "[AUTH] Request:",
      req.method,
      req.originalUrl
    );

    console.log(
      "[AUTH] Authorization header present:",
      Boolean(authHeader)
    );

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "Authentication token required",
      });
    }

    if (!authHeader.startsWith("Bearer ")) {
      console.log(
        "[AUTH] Invalid authorization format"
      );

      return res.status(401).json({
        success: false,
        message: "Authentication token required",
      });
    }

    const token = authHeader.substring(7).trim();

    console.log(
      "[AUTH] Token received:",
      Boolean(token),
      "Length:",
      token.length
    );

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authentication token required",
      });
    }

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    console.log(
      "[AUTH] Token verified successfully"
    );

    console.log(
      "[AUTH] User ID:",
      decoded.userId
    );

    req.userId = decoded.userId;

    next();
  } catch (error) {
    console.error(
      "[AUTH] JWT verification failed"
    );

    console.error(
      "[AUTH] Error name:",
      error.name
    );

    console.error(
      "[AUTH] Error message:",
      error.message
    );

    return res.status(401).json({
      success: false,
      message: "Invalid or expired authentication token",
    });
  }
};

module.exports = authMiddleware;