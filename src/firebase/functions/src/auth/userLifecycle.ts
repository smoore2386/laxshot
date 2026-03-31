import * as admin from "firebase-admin";
import { auth } from "firebase-functions/v1";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

export const onUserCreate = auth.user().onCreate(async (user) => {
  const ref = db.collection("users").doc(user.uid);
  const existing = await ref.get();
  if (existing.exists) return;

  await ref.set({
    uid: user.uid,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoURL: user.photoURL ?? null,
    isMinor: false,
    parentApproved: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info("onUserCreate: seeded user doc", { uid: user.uid });
});

export const onUserDelete = auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const batch = db.batch();

  batch.delete(db.collection("users").doc(uid));

  const sessions = await db.collection("sessions").where("uid", "==", uid).get();
  sessions.docs.forEach((doc) => batch.delete(doc.ref));

  const stats = await db.collection("stats").where("uid", "==", uid).get();
  stats.docs.forEach((doc) => batch.delete(doc.ref));

  await batch.commit();

  logger.info("onUserDelete: cascaded deletion", {
    uid,
    sessionsDeleted: sessions.size,
    statsDeleted: stats.size,
  });
});
