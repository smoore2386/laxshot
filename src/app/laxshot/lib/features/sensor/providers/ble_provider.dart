import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/dev_config.dart';
import '../../../data/models/motion_packet.dart';
import '../../../data/services/ble_service.dart';
import '../../../data/services/fake_ble_service.dart';

/// Singleton BLE service instance.
/// Uses [FakeBleService] in debug builds when [DevConfig.useFakeBle] is true,
/// so the full sensor flow can be exercised without real BLE hardware.
final bleServiceProvider = Provider<BleService>((ref) {
  final service = DevConfig.useFakeBle ? FakeBleService() : BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Connection state stream.
final bleConnectionStateProvider =
    StreamProvider<BleConnectionState>((ref) {
  return ref.watch(bleServiceProvider).connectionState;
});

/// Whether BLE is currently connected.
final bleIsConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(bleConnectionStateProvider).valueOrNull;
  return state == BleConnectionState.connected;
});

/// Scan results stream — active only while a scan is running.
final bleScanResultsProvider =
    StreamProvider.autoDispose<List<ScanResult>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.startScan();
});

/// Raw motion packet stream from the connected sensor.
final motionPacketStreamProvider =
    StreamProvider<MotionPacket>((ref) {
  return ref.watch(bleServiceProvider).motionStream;
});

/// Battery level derived from the latest motion packet.
final sensorBatteryProvider = Provider<int>((ref) {
  return ref.watch(motionPacketStreamProvider).valueOrNull?.batteryPercent ??
      -1;
});
