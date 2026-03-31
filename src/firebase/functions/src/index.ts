import * as admin from "firebase-admin";

admin.initializeApp();

export { onUserCreate, onUserDelete } from "./auth/userLifecycle";
export { parentalConsent, parentApproval } from "./auth/parentalConsent";
export { aggregateStats } from "./stats/aggregateStats";
export { computePersonalBests } from "./stats/personalBests";
export { createProfile, deleteAccount } from "./users/profileManagement";
