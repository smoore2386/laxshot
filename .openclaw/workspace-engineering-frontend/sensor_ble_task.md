# Flutter BLE Integration Task — From LaxForge to FrontClaw

**Priority:** High — needed before end-to-end testing  
**Depends on:** BLE protocol spec at `hardware/docs/ble_protocol.md`  
**Deadline:** Before pods are assembled (firmware is ready now)

---

## What LaxForge Needs

LaxForge has built the firmware and BLE protocol for the LaxPod sensor pod. FrontClaw needs to implement the Flutter-side BLE integration so the LaxShot app can connect to pods and display real-time motion data.

## Task: Create `lib/features/sensor/` Module

### 1. Add dependency to pubspec.yaml
```yaml
flutter_blue_plus: ^1.35.0  # or latest
```

### 2. Create these files

#### `lib/features/sensor/models/motion_packet.dart`
Parse the 48-byte BLE motion packet. See the Dart parsing example in `hardware/docs/ble_protocol.md` (Flutter Integration Notes section).

Fields: `accelX/Y/Z` (g), `gyroX/Y/Z` (deg/s), `quatW/X/Y/Z`, `batteryPercent`, `inShot`, `sessionActive`, `timestampMs`

#### `lib/features/sensor/models/sensor_session_model.dart`
Firestore model for sensor sessions:
```dart
SensorSessionModel {
  sessionId, userId, deviceId,
  startedAt, endedAt,
  firmwareVersion,
  shotCount,
  shots: List<ShotData>,  // { timestampMs, peakAccelG, quaternion, durationMs }
  metadata: { totalSamples, avgSampleRateHz, batteryStartPct }
}
```

#### `lib/features/sensor/services/ble_service.dart`
- Scan for devices advertising Motion Service UUID: `4C415801-5348-4F54-4C41-585353454E53`
- Connect to selected device
- Subscribe to Motion characteristic notifications (UUID: `4C415802-...`)
- Parse incoming 48-byte packets into `MotionPacket` objects
- Expose connection state stream + motion data stream

#### `lib/features/sensor/providers/sensor_provider.dart`
Riverpod providers:
- `sensorConnectionProvider` — BLE connection state (disconnected/scanning/connecting/connected)
- `sensorDataStreamProvider` — Stream of `MotionPacket` from connected pod
- `sensorBatteryProvider` — Current battery percentage
- `sensorShotCountProvider` — Running shot count from current session

#### `lib/features/sensor/screens/sensor_connect_screen.dart`
- "Connect Sensor" screen with scan button
- List of discovered LaxPod devices
- Tap to connect, show connection progress
- Navigate to live session screen on successful connection

#### `lib/features/sensor/screens/live_session_screen.dart`
- Real-time display of accel/gyro values
- Quaternion visualization (simple 3D cube or arrow)
- Shot counter (increments when IN_SHOT flag fires)
- Battery indicator
- "End Session" button → save to Firestore

#### `lib/features/sensor/widgets/sensor_status_widget.dart`
- Small widget for home screen showing connection status + battery
- Tappable → navigates to sensor_connect_screen

### 3. Add route to GoRouter
```dart
GoRoute(path: '/sensor', builder: (_, __) => SensorConnectScreen()),
GoRoute(path: '/sensor/live', builder: (_, __) => LiveSessionScreen()),
```

### 4. BLE Protocol Quick Reference

| Property | Value |
|----------|-------|
| Device Name | `LaxPod` |
| Motion Service UUID | `4C415801-5348-4F54-4C41-585353454E53` |
| Motion Characteristic | `4C415802-5348-4F54-4C41-585353454E53` |
| Packet Size | 48 bytes, little-endian |
| Notify Rate | 200Hz during shots, 10Hz idle |

Full spec: `hardware/docs/ble_protocol.md`

### 5. iOS/Android Permissions

**iOS** (`Info.plist`):
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>LaxShot needs Bluetooth to connect to your LaxPod sensor</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>LaxShot needs Bluetooth to connect to your LaxPod sensor</string>
```

**Android** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

---

When complete, notify LaxForge so we can run end-to-end testing (pod → app → Firestore).
