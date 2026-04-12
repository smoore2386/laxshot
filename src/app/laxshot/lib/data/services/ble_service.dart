import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/ble_constants.dart';
import '../models/motion_packet.dart';

enum BleConnectionState { disconnected, connecting, connected }

/// Manages BLE communication with a LaxPod sensor device.
class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _motionController = StreamController<MotionPacket>.broadcast();

  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  /// Stream of connection state changes.
  Stream<BleConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Stream of parsed motion packets from the sensor.
  Stream<MotionPacket> get motionStream => _motionController.stream;

  /// The currently connected device, if any.
  BluetoothDevice? get connectedDevice => _device;

  /// Whether Bluetooth is currently supported and turned on.
  Future<bool> get isAvailable async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return false;
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false; // Simulator or unsupported platform
    }
  }

  /// Request BLE-related permissions. Returns true if all granted.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    }
    // iOS handles permissions via Info.plist at first BLE usage
    return true;
  }

  /// Start scanning for LaxPod devices. Returns a stream of scan results.
  /// Safely handles simulators / devices without Bluetooth.
  Stream<List<ScanResult>> startScan() async* {
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.motionServiceUuid)],
        timeout: BleConstants.scanTimeout,
      );
    } catch (_) {
      // BLE unavailable (e.g. simulator) — yield empty and stop
      yield <ScanResult>[];
      return;
    }
    yield* FlutterBluePlus.scanResults;
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a LaxPod device, discover services, and enable notifications.
  Future<void> connect(BluetoothDevice device) async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    _connectionStateController.add(BleConnectionState.connecting);

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _device = device;

      // Listen for disconnections
      _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionStateController.add(BleConnectionState.disconnected);
          _notifySub?.cancel();
          if (!_intentionalDisconnect) {
            _attemptReconnect();
          }
        }
      });

      // Discover services and set up characteristics
      final services = await device.discoverServices();
      await _setupCharacteristics(services);

      _connectionStateController.add(BleConnectionState.connected);
    } catch (e) {
      _connectionStateController.add(BleConnectionState.disconnected);
      rethrow;
    }
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _notifySub?.cancel();
    _connectionSub?.cancel();
    await _device?.disconnect();
    _device = null;
    _controlChar = null;
    _connectionStateController.add(BleConnectionState.disconnected);
  }

  /// Send a control command to the pod (e.g. START_SESSION, IDENTIFY).
  Future<void> sendCommand(int command) async {
    if (_controlChar == null) return;
    await _controlChar!.write([command], withoutResponse: false);
  }

  /// Clean up all resources.
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _motionController.close();
  }

  // ── Private ──────────────────────────────────────────────────────

  Future<void> _setupCharacteristics(List<BluetoothService> services) async {
    for (final service in services) {
      if (service.uuid == Guid(BleConstants.motionServiceUuid)) {
        for (final char in service.characteristics) {
          if (char.uuid == Guid(BleConstants.motionDataCharUuid)) {
            // Enable notifications
            await char.setNotifyValue(true);
            _notifySub?.cancel();
            _notifySub = char.lastValueStream.listen(_onMotionData);
          } else if (char.uuid == Guid(BleConstants.controlCharUuid)) {
            _controlChar = char;
          }
        }
      }
    }
  }

  void _onMotionData(List<int> value) {
    if (value.length < BleConstants.packetSize) return;
    try {
      final packet = MotionPacket.fromBytes(value);
      _motionController.add(packet);
    } catch (_) {
      // Malformed packet — skip
    }
  }

  Future<void> _attemptReconnect() async {
    if (_device == null) return;
    if (_reconnectAttempts >= BleConstants.maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = BleConstants.reconnectBaseDelay * (1 << (_reconnectAttempts - 1));
    await Future<void>.delayed(delay);

    if (_intentionalDisconnect) return;

    try {
      _connectionStateController.add(BleConnectionState.connecting);
      await _device!.connect(timeout: const Duration(seconds: 10));
      final services = await _device!.discoverServices();
      await _setupCharacteristics(services);
      _reconnectAttempts = 0;
      _connectionStateController.add(BleConnectionState.connected);
    } catch (_) {
      if (_reconnectAttempts < BleConstants.maxReconnectAttempts) {
        _attemptReconnect();
      } else {
        _connectionStateController.add(BleConnectionState.disconnected);
      }
    }
  }
}
