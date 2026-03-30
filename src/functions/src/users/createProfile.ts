import * as functions from "firebase-functions";
import { auth, db } from "../lib/firebaseAdmin";
import { isUnderCoppaAge } from "../lib/coppaUtils";
import { parsePayload, CreateProfileSchema } from "../lib/validators";
import { httpError, ErrorCode, safeCallable } from "../lib/errors";
import { FieldValue } from "firebase-admin/firestore";

/**
 * HTTPS Callable: create or update a user profile.
 *
 * This is the canonical entry-point for setting user age (which triggers the
 * COPPA minor check) and profile data.  The Flutter app calls this after
 * initial sign-in and on profile edits.
 *
 * If the user is under 13 and no parentApproved claim exists:
 *   - Sets isMinor custom claim.
 *   - Ensures parentApproved: false on the user doc.
 *   - The app should immediately call parentalConsent callable next.
 */
export const createProfile = functions.https.onCall(
  safeCallable(async (data: unknown, context) => {
    if (!context.auth) {
      throw httpError(ErrorCode.UNAUTHENTICATED, "Must be signed in.");
    }

    const uid = context.auth.uid;
    const payload = parsePayload(CreateProfileSchema, data);
    const { displayName, age, position, team, parentEmail } = payload;

    const isMinor = isUnderCoppaAge(age);

    // Under-13 accounts must supply a parent email at profile creation time
    if (isMinor && !parentEmail) {
      throw httpError(
        ErrorCode.INVALID_ARGUMENT,
        "A parent email address is required for users under 13."
      );
    }

    // Fetch existing claims to avoid clobbering other claims
    const userRecord = await auth.getUser(uid);
    const existingClaims = userRecord.customClaims ?? {};
    const alreadyApproved = existingClaims["parentApproved"] === true;

    // Update custom claims
    await auth.setCustomUserClaims(uid, {
      ...existingClaims,
      age,
      isMinor,
      // Preserve parentApproved if already set; default false for new minors
      parentApproved: isMinor ? (alreadyApproved ? true : false) : undefined,
    });

    // Update Auth display name
    await auth.updateUser(uid, { displayName });

    // Build Firestore update
    const profileUpdate: Record<string, unknown> = {
      "profile.displayName": displayName,
      "profile.age": age,
      "profile.position": position,
      updatedAt: FieldValue.serverTimestamp(),
      isMinor,
    };

    if (team !== undefined) {
      profileUpdate["profile.team"] = team;
    }

    if (isMinor) {
      profileUpdate.parentApproved = alreadyApproved ? true : false;
      if (parentEmail) {
        profileUpdate.parentEmail = parentEmail.toLowerCase();
      }
    }

    const userRef = db.collection("users").doc(uid);
    const snap = await userRef.get();

    if (snap.exists) {
      await userRef.update(profileUpdate);
    } else {
      // Race condition: onUserCreate hasn't run yet — create the doc
      await userRef.set(
        {
          uid,
          email: userRecord.email ?? null,
          createdAt: FieldValue.serverTimestamp(),
          ...profileUpdate,
        },
        { merge: true }
      );
    }

    functions.logger.info("Profile created/updated", { uid, isMinor, age });

    return {
      success: true,
      isMinor,
      requiresParentalConsent: isMinor && !alreadyApproved,
    };
  })
);
