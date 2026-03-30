import * as functions from "firebase-functions";
import { db, storage } from "../lib/firebaseAdmin";

/**
 * Fires whenever a Firebase Auth user is deleted.
 *
 * Performs a cascading cleanup:
 *   1. Delete all Firestore subcollections (sessions, stats, profile, settings).
 *   2. Delete the root user document.
 *   3. Delete all files in Cloud Storage under users/{uid}/.
 *   4. Invalidate any pending consent tokens belonging to the user.
 */
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;
  functions.logger.info("onUserDelete triggered — starting cleanup", { uid });

  await Promise.all([
    deleteFirestoreData(uid),
    deleteStorageData(uid),
    invalidateConsentTokens(uid),
  ]);

  functions.logger.info("onUserDelete cleanup complete", { uid });
});

// ─── Firestore cleanup ────────────────────────────────────────────────────────

async function deleteFirestoreData(uid: string): Promise<void> {
  const userRef = db.collection("users").doc(uid);

  // Delete sub-collections in parallel
  await Promise.all([
    deleteCollection(userRef.collection("sessions")),
    deleteCollection(userRef.collection("stats")),
  ]);

  // Delete root user document (profile and settings are nested maps, not subcollections)
  await userRef.delete();

  functions.logger.info("Firestore data deleted", { uid });
}

/**
 * Batch-deletes all documents in a collection reference.
 * Processes up to 500 docs per batch (Firestore batch limit).
 */
async function deleteCollection(
  collRef: FirebaseFirestore.CollectionReference
): Promise<void> {
  let snapshot = await collRef.limit(500).get();

  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    if (snapshot.size < 500) break;
    snapshot = await collRef.limit(500).get();
  }
}

// ─── Storage cleanup ─────────────────────────────────────────────────────────

async function deleteStorageData(uid: string): Promise<void> {
  const bucket = storage.bucket();
  const prefix = `users/${uid}/`;

  try {
    const [files] = await bucket.getFiles({ prefix });

    if (files.length === 0) {
      functions.logger.info("No storage files to delete", { uid });
      return;
    }

    // Delete in parallel batches of 100 to avoid overwhelming the API
    const BATCH_SIZE = 100;
    for (let i = 0; i < files.length; i += BATCH_SIZE) {
      await Promise.all(files.slice(i, i + BATCH_SIZE).map((f) => f.delete()));
    }

    functions.logger.info("Storage files deleted", { uid, count: files.length });
  } catch (err) {
    // Log but don't throw — storage cleanup failure should not block auth deletion
    functions.logger.error("Failed to delete storage files", { uid, err });
  }
}

// ─── Consent token cleanup ────────────────────────────────────────────────────

async function invalidateConsentTokens(uid: string): Promise<void> {
  const snapshot = await db
    .collection("consentTokens")
    .where("childUid", "==", uid)
    .get();

  if (snapshot.empty) return;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  functions.logger.info("Consent tokens invalidated", {
    uid,
    count: snapshot.size,
  });
}
