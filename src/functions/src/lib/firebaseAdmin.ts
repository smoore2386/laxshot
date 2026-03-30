import * as admin from "firebase-admin";

// Singleton pattern — safe to import from any function file.
// firebase-functions runtime calls initializeApp() once; subsequent calls are no-ops.
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
export const messaging = admin.messaging();
export default admin;
