# BLE Protocol Specification — LaxPod v0.1.0

This document defines the BLE communication protocol between the LaxPod sensor and the LaxShot mobile app. **This is the integration contract between LaxForge (firmware) and FrontClaw (Flutter BLE).**

## Device Discovery

| Parameter | Value |
|-----------|-------|
| Device Name | `LaxPod` (may append `-XX` serial suffix in future) |
| TX Power | +8 dBm (~30m range, suitable for lacrosse field) |
| Advertising Interval | 20–152.5ms (fast for 30s, then slow) |
| Connectable | Yes |
| Bondable | No (Phase 1 — simplified pairing) |

## Services

### 1. Motion Service (Custom)

| Property | Value |
|----------|-------|
| Service UUID | `4C415801-5348-4F54-4C41-585353454E53` |
| Description | Real-time IMU + orientation + shot detection data |

#### Motion Data Characteristic

| Property | Value |
|----------|-------|
| UUID | `4C415802-5348-4F54-4C41-585353454E53` |
| Properties | Read, Notify |
| Size | 48 bytes (fixed) |
| Notify Rate | ~200 Hz during shots, ~10 Hz when idle |

**Packet Format (48 bytes, little-endian):**

| Offset | Type | Size | Field | Unit | Description |
|--------|------|------|-------|------|-------------|
| 0 | float32 | 4 | accel_x | g | Accelerometer X-axis |
| 4 | float32 | 4 | accel_y | g | Accelerometer Y-axis |
| 8 | float32 | 4 | accel_z | g | Accelerometer Z-axis |
| 12 | float32 | 4 | gyro_x | deg/s | Gyroscope X-axis |
| 16 | float32 | 4 | gyro_y | deg/s | Gyroscope Y-axis |
| 20 | float32 | 4 | gyro_z | deg/s | Gyroscope Z-axis |
| 24 | float32 | 4 | quat_w | - | Quaternion W (scalar) |
| 28 | float32 | 4 | quat_x | - | Quaternion X |
| 32 | float32 | 4 | quat_y | - | Quaternion Y |
| 36 | float32 | 4 | quat_z | - | Quaternion Z |
| 40 | uint8 | 1 | battery_pct | % | Battery level (0–100) |
| 41 | uint8 | 1 | flags | - | Status flags (see below) |
| 42 | uint32 | 4 | timestamp | ms | Milliseconds since pod boot |
| 46 | uint16 | 2 | reserved | - | Reserved (zeros) |

**Flags byte (offset 41):**

| Bit | Name | Description |
|-----|------|-------------|
| 0 | `IN_SHOT` | 1 = shot currently in progress (accel > 8g) |
| 1 | `SESSION_ACTIVE` | 1 = BLE connection active |
| 2–7 | reserved | Always 0 |

#### Control Characteristic

| Property | Value |
|----------|-------|
| UUID | `4C415803-5348-4F54-4C41-585353454E53` |
| Properties | Write |
| Size | 1 byte |
| Purpose | Session control commands from app |

**Control Commands:**

| Value | Command | Description |
|-------|---------|-------------|
| `0x01` | START_SESSION | Begin recording session (future use) |
| `0x02` | STOP_SESSION | End recording session (future use) |
| `0x03` | RESET_SHOT_COUNT | Reset shot counter to zero |
| `0xFF` | IDENTIFY | Flash LED pattern for device identification |

### 2. Device Information Service (Standard)

| Property | Value |
|----------|-------|
| Service UUID | `0x180A` (Bluetooth SIG) |

| Characteristic | UUID | Value |
|----------------|------|-------|
| Manufacturer Name | `0x2A29` | `LaxShot` |
| Model Number | `0x2A24` | `LaxPod v1` |
| Firmware Revision | `0x2A26` | `0.1.0` |
| Hardware Revision | `0x2A27` | `XIAO-nRF52840-Sense` |

### 3. Battery Service (Standard)

| Property | Value |
|----------|-------|
| Service UUID | `0x180F` (Bluetooth SIG) |

| Characteristic | UUID | Properties | Description |
|----------------|------|------------|-------------|
| Battery Level | `0x2A19` | Read, Notify | Battery percentage (0–100) |

## Connection Parameters

After connection, the pod requests optimized parameters:

| Parameter | Value | Units |
|-----------|-------|-------|
| Min Connection Interval | 7.5 | ms |
| Max Connection Interval | 15 | ms |
| Slave Latency | 0 | events |
| Supervision Timeout | 2000 | ms |

## Data Flow

```
Pod (idle)                     App
  │                             │
  │◄── Scan + Connect ──────────│
  │                             │
  │── Connection established ──►│
  │                             │
  │◄── Subscribe to Motion ─────│  (enable notifications on 4C415802)
  │                             │
  │── Motion packets @10Hz ────►│  (idle — low rate)
  │                             │
  │── Motion packets @200Hz ───►│  (during shot — high rate, IN_SHOT=1)
  │                             │
  │── Shot complete ───────────►│  (IN_SHOT drops to 0, app records shot event)
  │                             │
  │── Motion packets @10Hz ────►│  (back to idle rate)
  │                             │
  │◄── Disconnect ──────────────│
  │                             │
  │ (5 min idle) → Deep Sleep   │
```

## Flutter Integration Notes (for FrontClaw)

### Scanning
```dart
// Scan for devices advertising the Motion Service UUID
FlutterBluePlus.startScan(
  withServices: [Guid('4C415801-5348-4F54-4C41-585353454E53')],
  timeout: Duration(seconds: 10),
);
```

### Parsing Motion Packet
```dart
class MotionPacket {
  final double accelX, accelY, accelZ;    // g
  final double gyroX, gyroY, gyroZ;       // deg/s
  final double quatW, quatX, quatY, quatZ; // unit quaternion
  final int batteryPercent;                // 0-100
  final bool inShot;                       // shot in progress
  final bool sessionActive;               // BLE connected
  final int timestampMs;                   // ms since pod boot

  factory MotionPacket.fromBytes(List<int> bytes) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return MotionPacket(
      accelX:  data.getFloat32(0, Endian.little),
      accelY:  data.getFloat32(4, Endian.little),
      accelZ:  data.getFloat32(8, Endian.little),
      gyroX:   data.getFloat32(12, Endian.little),
      gyroY:   data.getFloat32(16, Endian.little),
      gyroZ:   data.getFloat32(20, Endian.little),
      quatW:   data.getFloat32(24, Endian.little),
      quatX:   data.getFloat32(28, Endian.little),
      quatY:   data.getFloat32(32, Endian.little),
      quatZ:   data.getFloat32(36, Endian.little),
      batteryPercent: data.getUint8(40),
      inShot:  (data.getUint8(41) & 0x01) != 0,
      sessionActive: (data.getUint8(41) & 0x02) != 0,
      timestampMs: data.getUint32(42, Endian.little),
    );
  }
}
```

## Firestore Schema (for Laxback)

When the app completes a sensor session, write to:

```
users/{userId}/sensorSessions/{sessionId}
  ├─ deviceId: string       (BLE device identifier)
  ├─ startedAt: Timestamp
  ├─ endedAt: Timestamp
  ├─ firmwareVersion: string ("0.1.0")
  ├─ shotCount: number
  ├─ shots: array<ShotData>
  │   └─ { timestampMs, peakAccelG, quaternion: [w,x,y,z], durationMs }
  └─ metadata: map
      ├─ totalSamples: number
      ├─ avgSampleRateHz: number
      └─ batteryStartPct: number
```

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-04-02 | Initial protocol — Phase 1 prototype |
