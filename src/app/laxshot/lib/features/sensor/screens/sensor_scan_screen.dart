import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/ble_constants.dart';
import '../providers/ble_provider.dart';

class SensorScanScreen extends ConsumerStatefulWidget {
  const SensorScanScreen({super.key});

  @override
  ConsumerState<SensorScanScreen> createState() => _SensorScanScreenState();
}

class _SensorScanScreenState extends ConsumerState<SensorScanScreen> {
  bool _scanning = false;
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final bleService = ref.read(bleServiceProvider);

    // Check permissions
    final granted = await bleService.requestPermissions();
    if (!granted) {
      setState(() => _error = 'Bluetooth permissions are required to connect to LaxPod.');
      return;
    }

    // Check BLE availability
    final available = await bleService.isAvailable;
    if (!available) {
      setState(() => _error = 'Please turn on Bluetooth to scan for your LaxPod sensor.');
      return;
    }

    setState(() {
      _scanning = true;
      _error = null;
    });

    // Scan will auto-stop after timeout
    Future.delayed(BleConstants.scanTimeout, () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _connecting = true);
    try {
      await ref.read(bleServiceProvider).stopScan();
      await ref.read(bleServiceProvider).connect(device);
      if (mounted) {
        context.go(AppRoutes.sensorLive);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = 'Failed to connect: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResults = ref.watch(bleScanResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Connect LaxPod'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _scanning
                        ? Icons.bluetooth_searching
                        : Icons.bluetooth,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _scanning
                          ? 'Scanning for LaxPod sensors...'
                          : 'Tap a device below to connect',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_scanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
            ],

            const SizedBox(height: AppSizes.lg),
            const Text(
              'Available Devices',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.sm),

            // Device list
            Expanded(
              child: scanResults.when(
                data: (results) {
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_off,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            _scanning
                                ? 'Looking for LaxPod...'
                                : 'No devices found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          if (!_scanning)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSizes.md),
                              child: ElevatedButton.icon(
                                onPressed: _startScan,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Scan Again'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final device = result.device;
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device';
                      final rssi = result.rssi;

                      return _DeviceTile(
                        name: name,
                        rssi: rssi,
                        connecting: _connecting,
                        onConnect: () => _connectToDevice(device),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Scan error: $e',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),

            // Rescan button
            if (!_scanning)
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan Again'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final int rssi;
  final bool connecting;
  final VoidCallback onConnect;

  const _DeviceTile({
    required this.name,
    required this.rssi,
    required this.connecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(Icons.sensors, color: AppColors.primary, size: 22),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Signal: ${_rssiLabel(rssi)}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: connecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -50) return 'Excellent ($rssi dBm)';
    if (rssi >= -70) return 'Good ($rssi dBm)';
    if (rssi >= -85) return 'Fair ($rssi dBm)';
    return 'Weak ($rssi dBm)';
  }
}
