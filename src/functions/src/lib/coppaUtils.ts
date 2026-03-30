import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import { v4 as uuidv4 } from "uuid";
import { db } from "./firebaseAdmin";
import { FieldValue } from "firebase-admin/firestore";

// ─── Constants ───────────────────────────────────────────────────────────────

export const COPPA_AGE_THRESHOLD = 13;
/** Consent tokens expire after 7 days */
const TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

// ─── Age helpers ─────────────────────────────────────────────────────────────

/**
 * Returns true if the given age is below the COPPA threshold (< 13).
 */
export function isUnderCoppaAge(age: number): boolean {
  return age < COPPA_AGE_THRESHOLD;
}

/**
 * Extracts age from a Firebase Auth UserRecord if the app stored it in
 * custom claims. Falls back to undefined if not present.
 */
export function getAgeFromClaims(
  customClaims: Record<string, unknown> | undefined
): number | undefined {
  if (!customClaims) return undefined;
  const age = customClaims["age"];
  return typeof age === "number" ? age : undefined;
}

// ─── Mailer ──────────────────────────────────────────────────────────────────

function createTransport() {
  const cfg = functions.config();
  // Expects: firebase functions:config:set smtp.host smtp.port smtp.user smtp.pass
  return nodemailer.createTransport({
    host: cfg.smtp?.host ?? "smtp.gmail.com",
    port: Number(cfg.smtp?.port ?? 587),
    secure: false,
    auth: {
      user: cfg.smtp?.user,
      pass: cfg.smtp?.pass,
    },
  });
}

// ─── Consent token lifecycle ─────────────────────────────────────────────────

export interface ConsentToken {
  token: string;
  childUid: string;
  parentEmail: string;
  createdAt: FirebaseFirestore.FieldValue;
  expiresAt: Date;
  used: boolean;
}

/**
 * Generates a UUID-based consent token, stores it in Firestore, and returns it.
 */
export async function createConsentToken(
  childUid: string,
  parentEmail: string
): Promise<string> {
  const token = uuidv4();
  const expiresAt = new Date(Date.now() + TOKEN_TTL_MS);

  await db.collection("consentTokens").doc(token).set({
    token,
    childUid,
    parentEmail: parentEmail.toLowerCase(),
    createdAt: FieldValue.serverTimestamp(),
    expiresAt,
    used: false,
  } satisfies Omit<ConsentToken, "createdAt"> & { createdAt: FirebaseFirestore.FieldValue });

  return token;
}

/**
 * Reads and validates a consent token from Firestore.
 * Returns the token doc if valid, throws if expired / not found / already used.
 */
export async function verifyConsentToken(token: string): Promise<ConsentToken> {
  const snap = await db.collection("consentTokens").doc(token).get();

  if (!snap.exists) {
    throw new Error("Consent token not found.");
  }

  const data = snap.data() as ConsentToken & { expiresAt: { toDate: () => Date } };

  if (data.used) {
    throw new Error("Consent token has already been used.");
  }

  const expiresAt =
    data.expiresAt instanceof Date
      ? data.expiresAt
      : (data.expiresAt as { toDate(): Date }).toDate();

  if (expiresAt < new Date()) {
    throw new Error("Consent token has expired.");
  }

  return { ...data, expiresAt };
}

/**
 * Marks a consent token as used so it cannot be replayed.
 */
export async function consumeConsentToken(token: string): Promise<void> {
  await db.collection("consentTokens").doc(token).update({ used: true });
}

// ─── Email sending ───────────────────────────────────────────────────────────

/**
 * Sends a parental consent email with an approval/denial link.
 *
 * The deep link opens the LaxShot parent portal web page which calls the
 * parentApproval Cloud Function.
 */
export async function sendConsentEmail(
  parentEmail: string,
  childDisplayName: string,
  token: string
): Promise<void> {
  const cfg = functions.config();
  const baseUrl =
    cfg.app?.consent_url ?? "https://laxshot.app/parent-consent";

  const approveUrl = `${baseUrl}?token=${token}&action=approve`;
  const denyUrl = `${baseUrl}?token=${token}&action=deny`;

  const transport = createTransport();
  const fromAddress = cfg.smtp?.from ?? '"LaxShot" <noreply@laxshot.app>';

  await transport.sendMail({
    from: fromAddress,
    to: parentEmail,
    subject: `Action Required: Parental Consent for ${childDisplayName}'s LaxShot Account`,
    html: `
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>LaxShot Parental Consent</title></head>
<body style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;color:#333">
  <h1 style="color:#1a73e8">LaxShot — Parental Consent Required</h1>
  <p>Hello,</p>
  <p>
    Your child, <strong>${childDisplayName}</strong>, has created an account on
    <strong>LaxShot</strong>, a youth lacrosse analysis app. Because they are under
    13 years old, we are required by the Children's Online Privacy Protection Act
    (COPPA) to obtain your consent before allowing them to use the app.
  </p>
  <h2>What data we collect</h2>
  <ul>
    <li>Player profile: name, age, position, team name</li>
    <li>Training session data: shot/save statistics and scores (on-device analysis)</li>
    <li>Optional: short video clips uploaded by the player for analysis (stored securely)</li>
  </ul>
  <p>We do <strong>not</strong> sell or share your child's data with third parties.</p>
  <h2>Your choices</h2>
  <p>
    <a href="${approveUrl}"
       style="display:inline-block;background:#1a73e8;color:#fff;padding:12px 24px;
              border-radius:4px;text-decoration:none;font-weight:bold;margin-right:12px">
      ✅ Approve Account
    </a>
    <a href="${denyUrl}"
       style="display:inline-block;background:#d32f2f;color:#fff;padding:12px 24px;
              border-radius:4px;text-decoration:none;font-weight:bold">
      ❌ Deny &amp; Delete Account
    </a>
  </p>
  <p style="font-size:12px;color:#666;margin-top:24px">
    This link expires in 7 days. If you did not expect this email, you can safely
    ignore it — the account will remain inactive until approved.
    <br>Questions? Contact us at <a href="mailto:privacy@laxshot.app">privacy@laxshot.app</a>
  </p>
</body>
</html>`,
    text: `
LaxShot — Parental Consent Required

Your child "${childDisplayName}" has created a LaxShot account. Because they are under 13, COPPA requires your consent.

What we collect: player profile, training session stats, optional video clips.
We do NOT sell or share your child's data.

To approve: ${approveUrl}
To deny & delete: ${denyUrl}

This link expires in 7 days.
Questions? privacy@laxshot.app
`,
  });
}
