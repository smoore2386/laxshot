import * as functions from "firebase-functions";

/** Canonical error codes used across LaxShot Cloud Functions. */
export const ErrorCode = {
  // Auth
  UNAUTHENTICATED: "unauthenticated",
  PERMISSION_DENIED: "permission-denied",
  // Input
  INVALID_ARGUMENT: "invalid-argument",
  // Business logic
  ALREADY_EXISTS: "already-exists",
  NOT_FOUND: "not-found",
  FAILED_PRECONDITION: "failed-precondition",
  // Server
  INTERNAL: "internal",
  UNAVAILABLE: "unavailable",
} as const;

export type ErrorCodeValue = (typeof ErrorCode)[keyof typeof ErrorCode];

/**
 * Factory to create a typed HttpsError with a consistent message format.
 *
 * @example
 *   throw httpError(ErrorCode.NOT_FOUND, "User profile not found", { userId });
 */
export function httpError(
  code: ErrorCodeValue,
  message: string,
  details?: unknown
): functions.https.HttpsError {
  const err = new functions.https.HttpsError(
    code as functions.https.FunctionsErrorCode,
    message,
    details
  );
  functions.logger.warn(`[HttpsError] ${code}: ${message}`, { details });
  return err;
}

/**
 * Wraps an async callable handler so unhandled errors surface as INTERNAL
 * HttpsErrors instead of leaking stack traces to the client.
 */
export function safeCallable<T, R>(
  handler: (data: T, context: functions.https.CallableContext) => Promise<R>
) {
  return async (
    data: T,
    context: functions.https.CallableContext
  ): Promise<R> => {
    try {
      return await handler(data, context);
    } catch (err) {
      if (err instanceof functions.https.HttpsError) throw err;
      functions.logger.error("Unhandled callable error", err);
      throw httpError(ErrorCode.INTERNAL, "An unexpected error occurred.");
    }
  };
}
