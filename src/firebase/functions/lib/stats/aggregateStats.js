"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.aggregateStats = void 0;
const admin = require("firebase-admin");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
const db = admin.firestore();
exports.aggregateStats = (0, scheduler_1.onSchedule)("0 3 * * *", async () => {
    v2_1.logger.info("aggregateStats: starting daily run");
    let lastDoc = null;
    let totalProcessed = 0;
    let keepGoing = true;
    while (keepGoing) {
        let query = db.collection("users").orderBy("uid").limit(100);
        if (lastDoc)
            query = query.startAfter(lastDoc);
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        await Promise.all(snapshot.docs.map((userDoc) => aggregateForUser(userDoc.id).catch((err) => {
            v2_1.logger.error("aggregateStats: failed for user", { uid: userDoc.id, error: err.message });
        })));
        totalProcessed += snapshot.size;
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.size < 100)
            keepGoing = false;
    }
    v2_1.logger.info("aggregateStats: done", { totalProcessed });
});
async function aggregateForUser(uid) {
    var _a;
    const sessionsSnap = await db.collection("sessions")
        .where("uid", "==", uid)
        .where("completedAt", "!=", null)
        .orderBy("completedAt", "desc")
        .limit(500)
        .get();
    if (sessionsSnap.empty)
        return;
    const sessions = sessionsSnap.docs.map((d) => d.data());
    const scores = sessions.map((s) => { var _a; return (_a = s.score) !== null && _a !== void 0 ? _a : 0; }).filter((s) => s > 0);
    const avgScore = scores.length > 0
        ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
        : 0;
    const bestScore = scores.length > 0 ? Math.max(...scores) : 0;
    const categoryTotals = {};
    for (const session of sessions) {
        const breakdown = (_a = session.breakdown) !== null && _a !== void 0 ? _a : {};
        for (const [cat, score] of Object.entries(breakdown)) {
            if (!categoryTotals[cat])
                categoryTotals[cat] = [];
            categoryTotals[cat].push(score);
        }
    }
    const avgBreakdown = {};
    for (const [cat, catScores] of Object.entries(categoryTotals)) {
        avgBreakdown[cat] = Math.round(catScores.reduce((a, b) => a + b, 0) / catScores.length);
    }
    const goalZoneCounts = new Array(9).fill(0);
    for (const session of sessions) {
        const zone = session.goalZone;
        if (zone != null && zone >= 0 && zone <= 8)
            goalZoneCounts[zone]++;
    }
    const sessionDates = new Set(sessions
        .map((s) => {
        var _a;
        const ts = s.completedAt;
        return (_a = ts === null || ts === void 0 ? void 0 : ts.toDate().toISOString().split("T")[0]) !== null && _a !== void 0 ? _a : "";
    })
        .filter(Boolean));
    const streak = computeStreak(sessionDates);
    await db.collection("stats").doc(uid).set({
        uid,
        totalSessions: sessions.length,
        avgScore,
        bestScore,
        avgBreakdown,
        goalZoneCounts,
        currentStreak: streak,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}
function computeStreak(sessionDates) {
    let streak = 0;
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    for (let i = 0; i < 365; i++) {
        const d = new Date(today);
        d.setUTCDate(d.getUTCDate() - i);
        const key = d.toISOString().split("T")[0];
        if (sessionDates.has(key)) {
            streak++;
        }
        else if (i > 0) {
            break;
        }
    }
    return streak;
}
//# sourceMappingURL=aggregateStats.js.map