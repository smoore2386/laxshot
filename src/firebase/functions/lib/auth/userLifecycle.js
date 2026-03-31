"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDelete = exports.onUserCreate = void 0;
const admin = require("firebase-admin");
const v1_1 = require("firebase-functions/v1");
const v2_1 = require("firebase-functions/v2");
const db = admin.firestore();
exports.onUserCreate = v1_1.auth.user().onCreate(async (user) => {
    var _a, _b, _c;
    const ref = db.collection("users").doc(user.uid);
    const existing = await ref.get();
    if (existing.exists)
        return;
    await ref.set({
        uid: user.uid,
        email: (_a = user.email) !== null && _a !== void 0 ? _a : null,
        displayName: (_b = user.displayName) !== null && _b !== void 0 ? _b : null,
        photoURL: (_c = user.photoURL) !== null && _c !== void 0 ? _c : null,
        isMinor: false,
        parentApproved: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    v2_1.logger.info("onUserCreate: seeded user doc", { uid: user.uid });
});
exports.onUserDelete = v1_1.auth.user().onDelete(async (user) => {
    const uid = user.uid;
    const batch = db.batch();
    batch.delete(db.collection("users").doc(uid));
    const sessions = await db.collection("sessions").where("uid", "==", uid).get();
    sessions.docs.forEach((doc) => batch.delete(doc.ref));
    const stats = await db.collection("stats").where("uid", "==", uid).get();
    stats.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    v2_1.logger.info("onUserDelete: cascaded deletion", {
        uid,
        sessionsDeleted: sessions.size,
        statsDeleted: stats.size,
    });
});
//# sourceMappingURL=userLifecycle.js.map