// lib/screens/device_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';

class DevicePickerScreen extends StatefulWidget {
  const DevicePickerScreen({super.key});

  @override
  State<DevicePickerScreen> createState() => _DevicePickerScreenState();
}

class _DevicePickerScreenState extends State<DevicePickerScreen> {
  List<BluetoothDevice> _paired = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() { _loading = true; _error = null; });

    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final denied = statuses.values.any((s) =>
        s == PermissionStatus.denied || s == PermissionStatus.permanentlyDenied);

    if (denied) {
      setState(() {
        _error = 'Bluetooth permissions are required.\nPlease enable them in Settings.';
        _loading = false;
      });
      return;
    }

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _paired = devices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load paired devices:\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await FlutterBluetoothSerial.instance.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accent.withAlpha(80)),
                        ),
                        child: const Icon(Icons.bluetooth, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                              letterSpacing: -0.5, color: Colors.white),
                          children: [
                            TextSpan(text: 'Steady'),
                            TextSpan(text: 'Boi', style: TextStyle(color: AppTheme.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SELECT HC-05 DEVICE',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pair your HC-05 module in Android Settings first (PIN: 1234 or 0000)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    )
                  : _error != null
                      ? _buildError()
                      : _paired.isEmpty
                          ? _buildEmpty()
                          : _buildDeviceList(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      label: 'BT Settings',
                      icon: Icons.settings_bluetooth,
                      onTap: _openSettings,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onTap: _loadDevices,
                      accent: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paired.length,
      itemBuilder: (ctx, i) {
        final device = _paired[i];
        final isHC05 = (device.name ?? '').toUpperCase().contains('HC') ||
            (device.name ?? '').toUpperCase().contains('BT');
        return _DeviceTile(
          device: device,
          isHC05: isHC05,
          onTap: () => Navigator.of(context).pop(device),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled,
                size: 56, color: AppTheme.textMuted.withAlpha(100)),
            const SizedBox(height: 16),
            const Text('No paired devices found',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Pair your HC-05 module first:\n'
              '1. Power on the robot\n'
              '2. Go to Android Bluetooth Settings\n'
              '3. Pair "HC-05" (PIN: 1234 or 0000)\n'
              '4. Come back and refresh',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.warn),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.6)),
            const SizedBox(height: 20),
            _OutlineButton(
              label: 'Open App Settings',
              icon: Icons.open_in_new,
              onTap: openAppSettings,
              accent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool isHC05;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.isHC05, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHC05 ? AppTheme.accentDim : AppTheme.surface,
          border: Border.all(
            color: isHC05 ? AppTheme.accent.withAlpha(100) : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isHC05 ? AppTheme.accentDim : AppTheme.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bluetooth,
                color: isHC05 ? AppTheme.accent : AppTheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name ?? 'Unknown Device',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: isHC05 ? AppTheme.accent : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.address,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (isHC05)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withAlpha(80)),
                ),
                child: const Text('HC-05',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppTheme.accent)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  const _OutlineButton({
    required this.label, required this.icon, required this.onTap, this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color: accent ? AppTheme.accentDim : AppTheme.surface2,
          border: Border.all(
            color: accent ? AppTheme.accent.withAlpha(100) : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: accent ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: accent ? AppTheme.accent : AppTheme.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}
