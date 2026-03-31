import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as crypto from "crypto";

// nodemailer loaded dynamically to avoid declaration file issues in strict mode
// eslint-disable-next-line @typescript-eslint/no-var-requires
const nodemailer = require("nodemailer") as typeof import("nodemailer");

const db = admin.firestore();

const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;
const TOKEN_TTL_MS = 48 * 60 * 60 * 1000;

export const parentalConsent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const uid = request.auth.uid;
  const parentEmail = (request.data.parentEmail as string)?.trim().toLowerCase();

  if (!parentEmail || !parentEmail.includes("@")) {
    throw new HttpsError("invalid-argument", "Valid parent email required.");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User not found.");
  }

  const userData = userDoc.data()!;
  const now = Date.now();
  const requests = (userData.consentRequests as number[]) ?? [];
  const recent = requests.filter((t) => now - t < RATE_LIMIT_WINDOW_MS);

  if (recent.length >= RATE_LIMIT_MAX) {
    throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");
  }

  const token = crypto.randomBytes(32).toString("hex");
  const expiresAt = new Date(now + TOKEN_TTL_MS);

  await db.collection("users").doc(uid).update({
    consentToken: token,
    consentTokenExpiresAt: expiresAt,
    consentParentEmail: parentEmail,
    consentRequests: [...recent, now],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await sendConsentEmail({
    parentEmail,
    childName: (userData.displayName as string) ?? "your child",
    token,
    uid,
  });

  logger.info("parentalConsent: sent", { uid, domain: parentEmail.split("@")[1] });
  return { success: true };
});

export const parentApproval = onCall(async (request) => {
  const token = request.data.token as string;
  const uid = request.data.uid as string;

  if (!token || !uid) {
    throw new HttpsError("invalid-argument", "Token and UID required.");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) throw new HttpsError("not-found", "User not found.");

  const userData = userDoc.data()!;
  const storedToken = userData.consentToken as string;
  const expiresAt = (userData.consentTokenExpiresAt as admin.firestore.Timestamp)?.toDate();

  if (!storedToken || storedToken !== token) {
    throw new HttpsError("invalid-argument", "Invalid consent token.");
  }
  if (!expiresAt || expiresAt < new Date()) {
    throw new HttpsError("deadline-exceeded", "Token expired.");
  }

  await db.collection("users").doc(uid).update({
    parentApproved: true,
    consentToken: admin.firestore.FieldValue.delete(),
    consentTokenExpiresAt: admin.firestore.FieldValue.delete(),
    consentParentEmail: admin.firestore.FieldValue.delete(),
    parentApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info("parentApproval: approved", { uid });
  return { success: true };
});

async function sendConsentEmail(opts: {
  parentEmail: string;
  childName: string;
  token: string;
  uid: string;
}) {
  const { parentEmail, childName, token, uid } = opts;

  // Email credentials set via: firebase functions:secrets:set EMAIL_USER EMAIL_PASS
  const emailUser = process.env.EMAIL_USER;
  const emailPass = process.env.EMAIL_PASS;

  if (!emailUser || !emailPass) {
    logger.warn("sendConsentEmail: creds not set, skipping", { uid });
    return;
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user: emailUser, pass: emailPass },
  });

  const approvalUrl = `https://laxshot-app-d44c9.web.app/consent?uid=${uid}&token=${token}`;

  await transporter.sendMail({
    from: `"LaxShot" <${emailUser}>`,
    to: parentEmail,
    subject: "Parent Permission Required for LaxShot",
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2 style="color:#1a73e8">LaxShot — Parent Permission</h2>
        <p><strong>${childName}</strong> wants to use LaxShot, a lacrosse training app.
           Because ${childName} is under 13, we need your permission first.</p>
        <a href="${approvalUrl}"
           style="display:inline-block;background:#1a73e8;color:white;
                  padding:12px 24px;border-radius:6px;text-decoration:none;
                  font-weight:bold;margin:16px 0">
          Approve ${childName}'s Account
        </a>
        <p style="color:#666;font-size:13px">Link expires in 48 hours.</p>
      </div>`,
  });
}
