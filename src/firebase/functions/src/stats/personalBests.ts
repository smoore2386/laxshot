import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

export const computePersonalBests = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const uid = request.auth.uid;

  const sessionsSnap = await db.collection("sessions")
    .where("uid", "==", uid)
    .where("completedAt", "!=", null)
    .get();

  if (sessionsSnap.empty) return { personalBests: {} };

  const personalBests: Record<string, number> = { overallScore: 0 };

  for (const doc of sessionsSnap.docs) {
    const data = doc.data();
    const score = (data.score as number) ?? 0;
    if (score > personalBests.overallScore) personalBests.overallScore = score;

    const breakdown = (data.breakdown as Record<string, number>) ?? {};
    for (const [cat, catScore] of Object.entries(breakdown)) {
      if (!personalBests[cat] || catScore > personalBests[cat]) {
        personalBests[cat] = catScore;
      }
    }
  }

  await db.collection("stats").doc(uid).set({
    personalBests,
    personalBestsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  logger.info("computePersonalBests: done", { uid });
  return { personalBests };
});
