import * as functions from "firebase-functions";
import { auth, db } from "../lib/firebaseAdmin";
import {
  createConsentToken,
  sendConsentEmail,
  isUnderCoppaAge,
} from "../lib/coppaUtils";
import { parsePayload, ParentalConsentSchema } from "../lib/validators";
import { httpError, ErrorCode, safeCallable } from "../lib/errors";
import { FieldValue } from "firebase-admin/firestore";

/**
 * HTTPS Callable: initiate the parental consent flow for an under-13 user.
 *
 * Expected payload: { childUid: string, parentEmail: string }
 *
 * Flow:
 *   1. Verify the caller is authenticated and is the child (or an admin).
 *   2. Confirm the child account is actually a minor.
 *   3. Generate a consent token (stored in Firestore with expiry).
 *   4. Send an email to the parent with approve/deny links.
 *   5. Persist the parent email on the child's user doc.
 */
export const parentalConsent = functions.https.onCall(
  safeCallable(async (data: unknown, context) => {
    if (!context.auth) {
      throw httpError(ErrorCode.UNAUTHENTICATED, "Must be signed in.");
    }

    const { childUid, parentEmail } = parsePayload(
      ParentalConsentSchema,
      data
    );

    // Callers may only initiate consent for their own account
    if (context.auth.uid !== childUid) {
      throw httpError(
        ErrorCode.PERMISSION_DENIED,
        "You may only initiate consent for your own account."
      );
    }

    // ── Verify the account is a minor ────────────────────────────────────────
    let userRecord;
    try {
      userRecord = await auth.getUser(childUid);
    } catch {
      throw httpError(ErrorCode.NOT_FOUND, "User account not found.");
    }

    const claims = userRecord.customClaims ?? {};
    const age = typeof claims["age"] === "number" ? (claims["age"] as number) : undefined;

    if (age !== undefined && !isUnderCoppaAge(age)) {
      throw httpError(
        ErrorCode.FAILED_PRECONDITION,
        "Parental consent is only required for users under 13."
      );
    }

    // ── Check if already approved ────────────────────────────────────────────
    const userSnap = await db.collection("users").doc(childUid).get();
    if (!userSnap.exists) {
      throw httpError(ErrorCode.NOT_FOUND, "User document not found.");
    }
    const userData = userSnap.data()!;
    if (userData.parentApproved === true) {
      throw httpError(
        ErrorCode.ALREADY_EXISTS,
        "This account already has parental approval."
      );
    }

    // ── Rate-limit: max 3 consent emails per 24 hours ────────────────────────
    const recentTokens = await db
      .collection("consentTokens")
      .where("childUid", "==", childUid)
      .where("used", "==", false)
      .where(
        "createdAt",
        ">=",
        new Date(Date.now() - 24 * 60 * 60 * 1000)
      )
      .get();

    if (recentTokens.size >= 3) {
      throw httpError(
        ErrorCode.FAILED_PRECONDITION,
        "Too many consent requests. Please try again in 24 hours."
      );
    }

    // ── Generate token & send email ──────────────────────────────────────────
    const token = await createConsentToken(childUid, parentEmail);

    const childName =
      userRecord.displayName ?? userData.profile?.displayName ?? "your child";

    await sendConsentEmail(parentEmail, childName, token);

    // ── Persist parent email on user doc (for display in app) ────────────────
    await db.collection("users").doc(childUid).update({
      parentEmail: parentEmail.toLowerCase(),
      consentRequestedAt: FieldValue.serverTimestamp(),
    });

    functions.logger.info("Parental consent email sent", {
      childUid,
      parentEmail,
    });

    return { success: true, message: "Consent email sent to parent." };
  })
);
