import * as functions from "firebase-functions";
import { db } from "../lib/firebaseAdmin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

/**
 * Scheduled Cloud Function — runs daily at 02:00 UTC.
 *
 * For each user who has had a session in the last 31 days:
 *   - Aggregates rolling 7-day and 30-day metrics.
 *   - Writes results to users/{userId}/stats/aggregated.
 *
 * Stats shape written:
 * {
 *   weekly:  { shotCount, saveCount, avgScore, totalDuration, sessionCount },
 *   monthly: { shotCount, saveCount, avgScore, totalDuration, sessionCount },
 *   updatedAt: serverTimestamp,
 * }
 */
export const aggregateStats = functions.pubsub
  .schedule("0 2 * * *") // daily at 02:00 UTC
  .timeZone("UTC")
  .onRun(async (_context) => {
    functions.logger.info("aggregateStats started");

    const now = new Date();
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Find all sessions modified in the last 31 days across all users.
    // We use a collection group query so we don't need to enumerate users.
    const recentSessions = await db
      .collectionGroup("sessions")
      .where("date", ">=", Timestamp.fromDate(thirtyDaysAgo))
      .get();

    if (recentSessions.empty) {
      functions.logger.info("No recent sessions found — nothing to aggregate.");
      return;
    }

    // Group sessions by userId
    const sessionsByUser = new Map<
      string,
      Array<FirebaseFirestore.DocumentData>
    >();

    for (const doc of recentSessions.docs) {
      // Path: users/{userId}/sessions/{sessionId}
      const userId = doc.ref.parent.parent?.id;
      if (!userId) continue;
      if (!sessionsByUser.has(userId)) sessionsByUser.set(userId, []);
      sessionsByUser.get(userId)!.push(doc.data());
    }

    functions.logger.info("Aggregating stats", { userCount: sessionsByUser.size });

    // Process all users in parallel (cap at 50 concurrent writes)
    const userIds = Array.from(sessionsByUser.keys());
    const CONCURRENCY = 50;

    for (let i = 0; i < userIds.length; i += CONCURRENCY) {
      await Promise.all(
        userIds.slice(i, i + CONCURRENCY).map(async (userId) => {
          const sessions = sessionsByUser.get(userId)!;

          const weekly = computeWindow(sessions, sevenDaysAgo);
          const monthly = computeWindow(sessions, thirtyDaysAgo);

          await db
            .collection("users")
            .doc(userId)
            .collection("stats")
            .doc("aggregated")
            .set(
              {
                weekly,
                monthly,
                updatedAt: FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
        })
      );
    }

    functions.logger.info("aggregateStats complete", {
      usersProcessed: sessionsByUser.size,
    });
  });

// ─── Helpers ─────────────────────────────────────────────────────────────────

interface WindowStats {
  sessionCount: number;
  shotCount: number;
  saveCount: number;
  totalDuration: number; // seconds
  avgScore: number | null;
}

function computeWindow(
  sessions: Array<FirebaseFirestore.DocumentData>,
  since: Date
): WindowStats {
  const inWindow = sessions.filter((s) => {
    const date: Date =
      s.date instanceof Timestamp
        ? s.date.toDate()
        : s.date instanceof Date
        ? s.date
        : new Date(s.date);
    return date >= since;
  });

  if (inWindow.length === 0) {
    return {
      sessionCount: 0,
      shotCount: 0,
      saveCount: 0,
      totalDuration: 0,
      avgScore: null,
    };
  }

  let shotCount = 0;
  let saveCount = 0;
  let totalDuration = 0;
  let scoreSum = 0;
  let scoredSessions = 0;

  for (const s of inWindow) {
    shotCount += Array.isArray(s.shots) ? s.shots.length : (s.shotCount ?? 0);
    saveCount += Array.isArray(s.saves) ? s.saves.length : (s.saveCount ?? 0);
    totalDuration += typeof s.duration === "number" ? s.duration : 0;
    if (typeof s.overallScore === "number") {
      scoreSum += s.overallScore;
      scoredSessions++;
    }
  }

  return {
    sessionCount: inWindow.length,
    shotCount,
    saveCount,
    totalDuration,
    avgScore: scoredSessions > 0 ? scoreSum / scoredSessions : null,
  };
}
