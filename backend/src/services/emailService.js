const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_APP_PASSWORD,
  },
});

const sendVerificationCode = async (email, code, purpose) => {
  const subject =
    purpose === "EMAIL_VERIFICATION"
      ? "Career Focus - Verify Your Email"
      : "Career Focus - Reset Your PIN";

  const message =
    purpose === "EMAIL_VERIFICATION"
      ? `Your Career Focus verification code is: ${code}`
      : `Your Career Focus PIN reset code is: ${code}`;

  await transporter.sendMail({
    from: `"Career Focus" <${process.env.EMAIL_USER}>`,
    to: email,
    subject,
    text: message,
  });
};

module.exports = {
  sendVerificationCode,
};