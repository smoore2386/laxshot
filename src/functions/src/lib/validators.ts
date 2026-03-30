import { z } from "zod";

// ─── Re-usable primitives ────────────────────────────────────────────────────

const uid = z.string().min(1).max(128);
const email = z.string().email().toLowerCase();

// ─── Auth / COPPA ────────────────────────────────────────────────────────────

export const ParentalConsentSchema = z.object({
  /** UID of the under-13 child account requesting consent */
  childUid: uid,
  /** Parent's email address — receives the consent link */
  parentEmail: email,
});
export type ParentalConsentPayload = z.infer<typeof ParentalConsentSchema>;

export const ParentApprovalSchema = z.object({
  /** Opaque consent token (stored in Firestore consentTokens collection) */
  token: z.string().uuid(),
  /** Action taken by the parent */
  action: z.enum(["approve", "deny"]),
});
export type ParentApprovalPayload = z.infer<typeof ParentApprovalSchema>;

// ─── Profile ─────────────────────────────────────────────────────────────────

const POSITIONS = ["attack", "midfield", "defense", "goalie", "faceoff"] as const;

export const CreateProfileSchema = z.object({
  displayName: z.string().min(1).max(50),
  /** Age in years — used for COPPA check */
  age: z.number().int().min(5).max(99),
  position: z.enum(POSITIONS),
  /** Optional team name — not required */
  team: z.string().max(80).optional(),
  /** Parent email — required when age < 13 */
  parentEmail: email.optional(),
});
export type CreateProfilePayload = z.infer<typeof CreateProfileSchema>;

// ─── Stats ───────────────────────────────────────────────────────────────────

export const ComputePersonalBestsSchema = z.object({
  /** Target user — callers may only request their own UID */
  userId: uid,
});
export type ComputePersonalBestsPayload = z.infer<
  typeof ComputePersonalBestsSchema
>;

// ─── Account deletion ────────────────────────────────────────────────────────

export const DeleteAccountSchema = z.object({
  /** Must match the authenticated user's UID for self-deletion,
   *  or be a child UID if the caller is the linked parent */
  targetUid: uid,
  /** Confirmation string — must equal "DELETE MY ACCOUNT" */
  confirmation: z.literal("DELETE MY ACCOUNT"),
});
export type DeleteAccountPayload = z.infer<typeof DeleteAccountSchema>;

// ─── Utility ─────────────────────────────────────────────────────────────────

/**
 * Parse and validate a callable payload against a Zod schema.
 * Throws an HttpsError(invalid-argument) on failure so the client
 * receives a typed error.
 */
import { httpError, ErrorCode } from "./errors";
import type { ZodType, ZodTypeDef } from "zod";

export function parsePayload<T>(
  schema: ZodType<T, ZodTypeDef, unknown>,
  data: unknown
): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw httpError(
      ErrorCode.INVALID_ARGUMENT,
      "Invalid request payload.",
      result.error.flatten()
    );
  }
  return result.data;
}
