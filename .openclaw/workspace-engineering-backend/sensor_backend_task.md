# Sensor Data Backend Task — From LaxForge to Laxback

**Priority:** Medium — needed before sensor sessions can be saved  
**Depends on:** BLE protocol spec at `hardware/docs/ble_protocol.md`  
**Deadline:** Before end-to-end testing

---

## What LaxForge Needs

LaxForge has built the sensor pod firmware. FrontClaw is building the Flutter BLE integration. Laxback needs to add Firestore support for sensor session data so the app can persist and aggregate sensor data.

## Task 1: Add Firestore Rules for sensorSessions

Add to `src/firebase/firestore.rules`:

```
// Sensor sessions (from LaxPod hardware)
match /users/{userId}/sensorSessions/{sessionId} {
  allow read: if isOwner(userId) || isParentOf(userId);
  allow create, update: if isOwner(userId) && isParentApproved(userId);
  allow delete: if isOwner(userId);
}
```

Same access pattern as existing `sessions` subcollection — owner can CRUD, parent can read.

## Task 2: Add Firestore Index

Add to `src/firebase/firestore.indexes.json`:

```json
{
  "collectionGroup": "sensorSessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "startedAt", "order": "DESCENDING" }
  ]
}
```

## Task 3: Sensor Stats Aggregation (Optional — Phase 1.5)

Consider adding a `aggregateSensorStats` Cloud Function that:
- Runs daily alongside existing `aggregateStats`
- Queries `sensorSessions` from last 31 days
- Computes: total sensor shots, avg peak accel, best peak accel, total sensor session time
- Writes to `users/{userId}/stats/sensorAggregated`

This can wait until after initial end-to-end testing works.

## Firestore Schema Reference

```
users/{userId}/sensorSessions/{sessionId}
  ├─ deviceId: string           // BLE device identifier
  ├─ userId: string             // Owner UID
  ├─ startedAt: Timestamp       // Session start
  ├─ endedAt: Timestamp         // Session end
  ├─ firmwareVersion: string    // "0.1.0"
  ├─ shotCount: number          // Total shots detected
  ├─ shots: array<map>          // Shot events
  │   └─ { timestampMs: number, peakAccelG: number,
  │        quaternion: [w,x,y,z], durationMs: number }
  └─ metadata: map
      ├─ totalSamples: number   // Total IMU samples received
      ├─ avgSampleRateHz: number
      └─ batteryStartPct: number
```

Full BLE protocol: `hardware/docs/ble_protocol.md`

---

When rules are deployed, notify LaxForge so we can run end-to-end testing.
