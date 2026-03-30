import * as functions from "firebase-functions";
import { auth, db } from "../lib/firebaseAdmin";
import {
  verifyConsentToken,
  consumeConsentToken,
} from "../lib/coppaUtils";
import { parsePayload, ParentApprovalSchema } from "../lib/validators";
import { httpError, ErrorCode, safeCallable } from "../lib/errors";
import { FieldValue } from "firebase-admin/firestore";

/**
 * HTTPS Callable: parent approves or denies a child account.
 *
 * Expected payload: { token: string, action: "approve" | "deny" }
 *
 * This function is called:
 *   - From the parent portal web page (opened via the email link).
 *   - The caller may be unauthenticated (parent may not have an app account).
 *
 * Flow (approve):
 *   1. Verify and consume the consent token.
 *   2. Set parentApproved: true on the child's Firestore user doc.
 *   3. Set custom claims: { isMinor: true, parentApproved: true, parentUid? }.
 *   4. Link parent UID if the caller is authenticated.
 *
 * Flow (deny):
 *   1. Verify and consume the consent token.
 *   2. Delete the child's Auth account (triggers onUserDelete cleanup).
 */
export const parentApproval = functions.https.onCall(
  safeCallable(async (data: unknown, context) => {
    const { token, action } = parsePayload(ParentApprovalSchema, data);

    // ── Verify token ─────────────────────────────────────────────────────────
    let consentData;
    try {
      consentData = await verifyConsentToken(token);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Invalid consent token.";
      throw httpError(ErrorCode.INVALID_ARGUMENT, msg);
    }

    const { childUid, parentEmail } = consentData;

    // Verify child account still exists
    let childRecord;
    try {
      childRecord = await auth.getUser(childUid);
    } catch {
      // Account was deleted while the token was pending — consume & bail
      await consumeConsentToken(token);
      throw httpError(ErrorCode.NOT_FOUND, "Child account no longer exists.");
    }

    // Mark token as used (idempotency guard)
    await consumeConsentToken(token);

    // ── Branch on action ─────────────────────────────────────────────────────

    if (action === "deny") {
      functions.logger.info("Parent denied child account — deleting", {
        childUid,
        parentEmail,
      });

      // Delete the Auth user — onUserDelete trigger handles Firestore + Storage
      await auth.deleteUser(childUid);

      return {
        success: true,
        action: "deny",
        message: "The child account has been deleted.",
      };
    }

    // ── Approve ──────────────────────────────────────────────────────────────

    const existingClaims = childRecord.customClaims ?? {};
    const parentUid = context.auth?.uid ?? null;

    // Update custom claims
    await auth.setCustomUserClaims(childUid, {
      ...existingClaims,
      isMinor: true,
      parentApproved: true,
      ...(parentUid ? { parentUid } : {}),
    });

    // Update Firestore user doc
    const updatePayload: Record<string, unknown> = {
      parentApproved: true,
      parentEmail: parentEmail.toLowerCase(),
      consentApprovedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (parentUid) {
      updatePayload.parentUid = parentUid;
    }

    await db.collection("users").doc(childUid).update(updatePayload);

    // If the parent is authenticated and doesn't have their own user doc yet,
    // note this link in the parent's doc so they can see their children's data.
    if (parentUid) {
      await db
        .collection("users")
        .doc(parentUid)
        .set(
          {
            linkedChildren: FieldValue.arrayUnion(childUid),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    }

    functions.logger.info("Parent approved child account", {
      childUid,
      parentUid,
      parentEmail,
    });

    return {
      success: true,
      action: "approve",
      message: "Parental consent granted. The account is now active.",
    };
  })
);
