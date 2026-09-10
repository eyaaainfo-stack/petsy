// services/emailService.js
const nodemailer = require('nodemailer');

// ============================================================================
// emailService
// ============================================================================
// 🔵 ZID (kifma tlab: "el mails elli nestamlhom mch virtuelle") - email
// 7a9i9i (SMTP standard) - ye5dem b Gmail (App Password) WELA Brevo/
// SendGrid/ay provider SMTP okhor, nafs el config (EMAIL_HOST/EMAIL_PORT/
// EMAIL_USER/EMAIL_PASS/EMAIL_FROM fel .env - chraht fel .env.example).
//
// 🔵 "gracefully" ki mafamech config: lowkan el .env mazal ma tzadetch
// (EMAIL_HOST/USER/PASS), ma nertimouch l'app kollha (forgot-password
// lezmou ye5dem, 7ata b'mode "dev" - console.log el code bark, kifma
// kan 9bal) - GHIR lowkan el config MAWJOUDA, njarbou nb3thou b'sa7i7.
// ============================================================================
let transporter = null;

function getTransporter() {
  if (transporter) return transporter;
  const { EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS } = process.env;
  if (!EMAIL_HOST || !EMAIL_USER || !EMAIL_PASS) return null;

  transporter = nodemailer.createTransport({
    host: EMAIL_HOST,
    port: Number(EMAIL_PORT) || 587,
    // 🔵 465 = SSL (secure: true) - 587 (w el ba9i) = STARTTLS (secure: false).
    secure: Number(EMAIL_PORT) === 465,
    auth: { user: EMAIL_USER, pass: EMAIL_PASS },
  });
  return transporter;
}

/**
 * Ib3ath email 7a9i9i (wela log fel terminal lowkan mafamech config
 * SMTP fel .env - mode "dev fallback").
 * @returns {Promise<boolean>} true lowkan tba3thet 7a9i9atan (wela mch
 *   metlouba l'sending 7a9i9i - dev fallback rajja3 false bch el caller
 *   ynajjam ychayer/yban fel logs, lakin ma yertim-ch el flow).
 */
async function sendEmail({ to, subject, text, html }) {
  const t = getTransporter();
  if (!t) {
    console.log(
      `📧 [EMAIL] mafamech config SMTP fel .env (EMAIL_HOST/EMAIL_USER/EMAIL_PASS) - email l "${to}" MA TBAATHECH. ` +
        `Contenu (dev fallback): ${text}`
    );
    return false;
  }
  try {
    await t.sendMail({
      from: process.env.EMAIL_FROM || `"Petsy" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
      html,
    });
    console.log(`✅ [EMAIL] Mba3atha l "${to}" - subject: "${subject}"`);
    return true;
  } catch (error) {
    // 🔵 ma nertimouch l'appelant (throw) - forgot-password lezmou
    // yekmel ye5dem (el code déjà m7ott fel base, verifyPasswordResetCode
    // ynajjam ye5dem) 7ata lowkan l'email provider "down" wa9tia -
    // el user ynajjam ychouf el code fel terminal (dev) wela y3awad.
    console.error(`❌ [EMAIL] Fechel el ib3ath l "${to}":`, error.message);
    return false;
  }
}

module.exports = { sendEmail };