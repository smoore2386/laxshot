/// BLE protocol constants for LaxPod v0.1.0 sensor communication.
/// Source of truth: hardware/docs/ble_protocol.md
class BleConstants {
  BleConstants._();

  // Device discovery
  static const String deviceName = 'LaxPod';

  // Service UUIDs
  static const String motionServiceUuid =
      '4C415801-5348-4F54-4C41-585353454E53';
  static const String motionDataCharUuid =
      '4C415802-5348-4F54-4C41-585353454E53';
  static const String controlCharUuid =
      '4C415803-5348-4F54-4C41-585353454E53';

  // Standard services
  static const String batteryServiceUuid = '180F';
  static const String batteryLevelCharUuid = '2A19';
  static const String deviceInfoServiceUuid = '180A';

  // Packet size
  static const int packetSize = 48;

  // Control commands (write to controlCharUuid)
  static const int cmdStartSession = 0x01;
  static const int cmdStopSession = 0x02;
  static const int cmdResetShotCount = 0x03;
  static const int cmdIdentify = 0xFF;

  // Flags byte bit masks
  static const int flagInShot = 0x01;
  static const int flagSessionActive = 0x02;

  // Scanning
  static const Duration scanTimeout = Duration(seconds: 10);

  // Connection
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectBaseDelay = Duration(seconds: 1);
}
