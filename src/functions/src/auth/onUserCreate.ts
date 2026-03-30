import * as functions from "firebase-functions";
import { auth, db } from "../lib/firebaseAdmin";
import { isUnderCoppaAge, COPPA_AGE_THRESHOLD } from "../lib/coppaUtils";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Fires whenever a new Firebase Auth user is created.
 *
 * Responsibilities:
 *   1. Detect if the user is a minor (age < 13) from registration metadata.
 *   2. Set `isMinor` custom claim on the Auth token.
 *   3. Initialise the /users/{uid} Firestore document.
 *      - Minors get parentApproved: false — sessions are blocked until a
 *        parent approves via the parentalConsent / parentApproval flow.
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  functions.logger.info("onUserCreate triggered", { uid: user.uid });

  // Age may be passed via displayName metadata during social sign-in,
  // or via custom claims set client-side before this trigger fires.
  // The createProfile callable is the canonical way to set age — until then
  // we default to non-minor (no parental gate on first sign-in).
  const existingClaims =
    (await auth.getUser(user.uid)).customClaims ?? {};

  const age: number | undefined =
    typeof existingClaims["age"] === "number"
      ? (existingClaims["age"] as number)
      : undefined;

  const isMinor = age !== undefined ? isUnderCoppaAge(age) : false;

  // ── 1. Set custom claims ──────────────────────────────────────────────────
  await auth.setCustomUserClaims(user.uid, {
    ...existingClaims,
    isMinor,
    // parentApproved claim starts false for minors; updated by parentApproval
    ...(isMinor ? { parentApproved: false } : {}),
  });

  // ── 2. Initialise Firestore user document ─────────────────────────────────
  const userDocRef = db.collection("users").doc(user.uid);

  const baseDoc: Record<string, unknown> = {
    uid: user.uid,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoURL: user.photoURL ?? null,
    isMinor,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    profile: {},
    settings: {
      notifications: true,
      privacyMode: "private",
    },
  };

  if (isMinor) {
    baseDoc.parentApproved = false;
    baseDoc.parentUid = null;
    baseDoc.parentEmail = null;
    functions.logger.info("Minor account created — awaiting parental consent", {
      uid: user.uid,
      age,
    });
  }

  await userDocRef.set(baseDoc, { merge: true });

  functions.logger.info("User document initialised", {
    uid: user.uid,
    isMinor,
    coppaThreshold: COPPA_AGE_THRESHOLD,
  });
});
