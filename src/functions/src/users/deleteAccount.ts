import * as functions from "firebase-functions";
import { auth, db, storage } from "../lib/firebaseAdmin";
import { parsePayload, DeleteAccountSchema } from "../lib/validators";
import { httpError, ErrorCode, safeCallable } from "../lib/errors";
import { FieldValue } from "firebase-admin/firestore";

/**
 * HTTPS Callable: GDPR / COPPA-compliant account deletion.
 *
 * Supports two deletion modes:
 *   a) Self-deletion — authenticated user deletes their own account.
 *   b) Parent-deletion — authenticated parent deletes a linked child account.
 *
 * Expected payload: { targetUid: string, confirmation: "DELETE MY ACCOUNT" }
 *
 * Steps:
 *   1. Authorise the caller.
 *   2. Delete all Firestore sub-collections and root doc.
 *   3. Delete all Storage files under users/{targetUid}/.
 *   4. Delete the Firebase Auth user (also triggers onUserDelete, which
 *      handles any remaining cleanup).
 *
 * NOTE: We perform explicit cleanup here rather than relying solely on
 * onUserDelete so the callable can surface errors to the client before
 * the Auth deletion is irreversible.
 */
export const deleteAccount = functions.https.onCall(
  safeCallable(async (data: unknown, context) => {
    if (!context.auth) {
      throw httpError(ErrorCode.UNAUTHENTICATED, "Must be signed in.");
    }

    const callerUid = context.auth.uid;
    const { targetUid } = parsePayload(DeleteAccountSchema, data);

    // ── Authorisation ─────────────────────────────────────────────────────────
    const isSelfDelete = callerUid === targetUid;

    if (!isSelfDelete) {
      // Check if caller is a linked parent of the target child
      const targetSnap = await db.collection("users").doc(targetUid).get();
      if (!targetSnap.exists) {
        throw httpError(ErrorCode.NOT_FOUND, "Target user not found.");
      }
      const targetData = targetSnap.data()!;
      const isLinkedParent = targetData.parentUid === callerUid;

      if (!isLinkedParent) {
        throw httpError(
          ErrorCode.PERMISSION_DENIED,
          "You do not have permission to delete this account."
        );
      }
    }

    functions.logger.info("deleteAccount initiated", {
      callerUid,
      targetUid,
      isSelfDelete,
    });

    // ── 1. Delete Firestore data ───────────────────────────────────────────────
    await deleteFirestoreData(targetUid);

    // ── 2. Delete Storage files ───────────────────────────────────────────────
    await deleteStorageData(targetUid);

    // ── 3. Remove child reference from parent doc (if applicable) ─────────────
    await unlinkFromParent(targetUid);

    // ── 4. Delete Firebase Auth user ──────────────────────────────────────────
    // This also triggers the onUserDelete Cloud Function for any residual cleanup.
    try {
      await auth.deleteUser(targetUid);
    } catch (err: unknown) {
      const code = (err as { code?: string }).code;
      if (code !== "auth/user-not-found") {
        throw httpError(
          ErrorCode.INTERNAL,
          "Failed to delete auth user.",
          err
        );
      }
    }

    functions.logger.info("deleteAccount complete", { targetUid });

    return { success: true, message: "Account and all associated data deleted." };
  })
);

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function deleteFirestoreData(uid: string): Promise<void> {
  const userRef = db.collection("users").doc(uid);

  // Delete sub-collections first
  await Promise.all([
    deleteCollection(userRef.collection("sessions")),
    deleteCollection(userRef.collection("stats")),
  ]);

  // Invalidate consent tokens
  const tokens = await db
    .collection("consentTokens")
    .where("childUid", "==", uid)
    .get();
  if (!tokens.empty) {
    const batch = db.batch();
    tokens.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  // Delete root doc last
  await userRef.delete();
}

async function deleteCollection(
  ref: FirebaseFirestore.CollectionReference
): Promise<void> {
  let snap = await ref.limit(500).get();
  while (!snap.empty) {
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    if (snap.size < 500) break;
    snap = await ref.limit(500).get();
  }
}

async function deleteStorageData(uid: string): Promise<void> {
  const bucket = storage.bucket();
  const [files] = await bucket.getFiles({ prefix: `users/${uid}/` });
  if (files.length === 0) return;

  const BATCH = 100;
  for (let i = 0; i < files.length; i += BATCH) {
    await Promise.all(files.slice(i, i + BATCH).map((f) => f.delete()));
  }
  functions.logger.info("Storage files deleted", { uid, count: files.length });
}

async function unlinkFromParent(childUid: string): Promise<void> {
  // Find the parent who has this child linked
  const parentSnap = await db
    .collection("users")
    .where("linkedChildren", "array-contains", childUid)
    .limit(1)
    .get();

  if (parentSnap.empty) return;

  await parentSnap.docs[0].ref.update({
    linkedChildren: FieldValue.arrayRemove(childUid),
    updatedAt: FieldValue.serverTimestamp(),
  });
}
