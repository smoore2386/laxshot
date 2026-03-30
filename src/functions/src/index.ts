/**
 * LaxShot Cloud Functions — entry point.
 *
 * All functions are exported from their respective modules and re-exported
 * here so Firebase CLI picks them up from a single file.
 *
 * Function inventory:
 *
 *  Auth triggers
 *    onUserCreate        — initialise user doc, detect minors, set claims
 *    onUserDelete        — cascade-delete Firestore + Storage
 *
 *  COPPA / Parental consent
 *    parentalConsent     — callable: generate token, send consent email
 *    parentApproval      — callable: parent approves or denies child account
 *
 *  Stats
 *    aggregateStats      — scheduled (daily): aggregate weekly/monthly stats
 *    computePersonalBests — callable: recompute all-time personal bests
 *
 *  Users
 *    createProfile       — callable: create / update user profile + age claim
 *    deleteAccount       — callable: GDPR/COPPA-compliant full account deletion
 */

export { onUserCreate } from "./auth/onUserCreate";
export { onUserDelete } from "./auth/onUserDelete";

export { parentalConsent } from "./coppa/parentalConsent";
export { parentApproval } from "./coppa/parentApproval";

export { aggregateStats } from "./stats/aggregateStats";
export { computePersonalBests } from "./stats/computePersonalBests";

export { createProfile } from "./users/createProfile";
export { deleteAccount } from "./users/deleteAccount";
