"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.computePersonalBests = void 0;
const admin = require("firebase-admin");
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const db = admin.firestore();
exports.computePersonalBests = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be signed in.");
    }
    const uid = request.auth.uid;
    const sessionsSnap = await db.collection("sessions")
        .where("uid", "==", uid)
        .where("completedAt", "!=", null)
        .get();
    if (sessionsSnap.empty)
        return { personalBests: {} };
    const personalBests = { overallScore: 0 };
    for (const doc of sessionsSnap.docs) {
        const data = doc.data();
        const score = (_a = data.score) !== null && _a !== void 0 ? _a : 0;
        if (score > personalBests.overallScore)
            personalBests.overallScore = score;
        const breakdown = (_b = data.breakdown) !== null && _b !== void 0 ? _b : {};
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
    v2_1.logger.info("computePersonalBests: done", { uid });
    return { personalBests };
});
//# sourceMappingURL=personalBests.js.map