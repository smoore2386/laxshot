import * as functions from "firebase-functions";
import { db } from "../lib/firebaseAdmin";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import {
  parsePayload,
  ComputePersonalBestsSchema,
} from "../lib/validators";
import { httpError, ErrorCode, safeCallable } from "../lib/errors";

/**
 * HTTPS Callable: recompute personal bests for a user from all their sessions.
 *
 * Expected payload: { userId: string }
 *
 * Personal bests written to users/{userId}/stats/personalBests:
 * {
 *   highestScore:    { value, sessionId, date },
 *   mostShotsInSession: { value, sessionId, date },
 *   mostSavesInSession: { value, sessionId, date },
 *   longestSession:  { value (seconds), sessionId, date },
 *   updatedAt: serverTimestamp,
 * }
 */
export const computePersonalBests = functions.https.onCall(
  safeCallable(async (data: unknown, context) => {
    if (!context.auth) {
      throw httpError(ErrorCode.UNAUTHENTICATED, "Must be signed in.");
    }

    const { userId } = parsePayload(ComputePersonalBestsSchema, data);

    // Users may only compute their own personal bests
    if (context.auth.uid !== userId) {
      throw httpError(
        ErrorCode.PERMISSION_DENIED,
        "You may only compute personal bests for your own account."
      );
    }

    // Verify the user document exists
    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) {
      throw httpError(ErrorCode.NOT_FOUND, "User not found.");
    }

    // Fetch all sessions (no date filter — personal bests are all-time)
    const sessionsSnap = await db
      .collection("users")
      .doc(userId)
      .collection("sessions")
      .orderBy("date", "asc")
      .get();

    if (sessionsSnap.empty) {
      // No sessions yet — write empty personal bests doc
      await db
        .collection("users")
        .doc(userId)
        .collection("stats")
        .doc("personalBests")
        .set({ updatedAt: FieldValue.serverTimestamp() });

      return { success: true, sessionCount: 0 };
    }

    let highestScore: PersonalBest | null = null;
    let mostShots: PersonalBest | null = null;
    let mostSaves: PersonalBest | null = null;
    let longestSession: PersonalBest | null = null;

    for (const doc of sessionsSnap.docs) {
      const s = doc.data();
      const sessionId = doc.id;
      const date: Timestamp | null =
        s.date instanceof Timestamp ? s.date : null;

      // Highest overall score
      if (typeof s.overallScore === "number") {
        if (!highestScore || s.overallScore > highestScore.value) {
          highestScore = { value: s.overallScore, sessionId, date };
        }
      }

      // Most shots in a session
      const shots = Array.isArray(s.shots) ? s.shots.length : (s.shotCount ?? 0);
      if (!mostShots || shots > mostShots.value) {
        mostShots = { value: shots, sessionId, date };
      }

      // Most saves in a session
      const saves = Array.isArray(s.saves) ? s.saves.length : (s.saveCount ?? 0);
      if (!mostSaves || saves > mostSaves.value) {
        mostSaves = { value: saves, sessionId, date };
      }

      // Longest session
      if (typeof s.duration === "number") {
        if (!longestSession || s.duration > longestSession.value) {
          longestSession = { value: s.duration, sessionId, date };
        }
      }
    }

    const personalBests = {
      ...(highestScore ? { highestScore } : {}),
      ...(mostShots ? { mostShotsInSession: mostShots } : {}),
      ...(mostSaves ? { mostSavesInSession: mostSaves } : {}),
      ...(longestSession ? { longestSession } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db
      .collection("users")
      .doc(userId)
      .collection("stats")
      .doc("personalBests")
      .set(personalBests);

    functions.logger.info("Personal bests computed", {
      userId,
      sessionCount: sessionsSnap.size,
    });

    return { success: true, sessionCount: sessionsSnap.size };
  })
);

// ─── Types ────────────────────────────────────────────────────────────────────

interface PersonalBest {
  value: number;
  sessionId: string;
  date: Timestamp | null;
}
