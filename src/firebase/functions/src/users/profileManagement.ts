import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();
const auth = admin.auth();

export const createProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const uid = request.auth.uid;
  const data = request.data as {
    displayName: string;
    email: string;
    dateOfBirth: string;
    position: string;
  };

  const { displayName, email, dateOfBirth, position } = data;

  if (!displayName || !email || !dateOfBirth) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const dob = new Date(dateOfBirth);
  if (isNaN(dob.getTime())) {
    throw new HttpsError("invalid-argument", "Invalid date of birth.");
  }

  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  if (
    now.getMonth() < dob.getMonth() ||
    (now.getMonth() === dob.getMonth() && now.getDate() < dob.getDate())
  ) age--;

  if (age < 6) throw new HttpsError("failed-precondition", "Minimum age is 6.");

  const isMinor = age < 13;
  const profileData = {
    uid,
    displayName,
    email,
    dateOfBirth: admin.firestore.Timestamp.fromDate(dob),
    position,
    isMinor,
    parentApproved: !isMinor,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const existing = await db.collection("users").doc(uid).get();
  if (existing.exists) {
    await db.collection("users").doc(uid).update(profileData);
  } else {
    await db.collection("users").doc(uid).set({
      ...profileData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await auth.updateUser(uid, { displayName });

  logger.info("createProfile: done", { uid, isMinor });
  return { success: true, isMinor };
});

export const deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const uid = request.auth.uid;

  for (const col of ["sessions", "stats"]) {
    const snap = await db.collection(col).where("uid", "==", uid).get();
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  await db.collection("users").doc(uid).delete();
  await auth.deleteUser(uid);

  logger.info("deleteAccount: done", { uid });
  return { success: true };
});
