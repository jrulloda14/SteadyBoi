// lib/screens/controller_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/tilt_visualizer.dart';
import '../widgets/live_chart.dart';
import '../widgets/pid_panel.dart';
import '../widgets/log_panel.dart';
import 'device_picker_screen.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectOrDisconnect() async {
    final bt = context.read<RobotBluetoothService>();

    if (bt.isConnected) {
      await bt.disconnect();
      return;
    }

    final device = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const DevicePickerScreen(),
        ),
      ),
    );

    if (device != null && context.mounted) {
      await bt.connectTo(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<RobotBluetoothService>();
    final cs = bt.connectionState;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(bt, cs),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DashboardTab(),
                  _PidTab(),
                  _LogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RobotBluetoothService bt, BtConnectionState cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  letterSpacing: -0.3, color: Colors.white),
              children: [
                TextSpan(text: 'Steady'),
                TextSpan(text: 'Boi', style: TextStyle(color: AppTheme.accent)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ConnectionBadge(state: cs, deviceName: bt.connectedDeviceName),
          const Spacer(),
          GestureDetector(
            onTap: bt.isConnected ? () => bt.sendCmd('STOP') : null,
            child: Opacity(
              opacity: bt.isConnected ? 1.0 : 0.35,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.warnDim,
                  border: Border.all(color: AppTheme.warn.withAlpha(100)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('⏹ STOP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        color: AppTheme.warn, letterSpacing: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AppButton(
            label: '▶ GO',
            onTap: bt.isConnected ? () => bt.sendCmd('GO') : null,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _connectOrDisconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: bt.isConnected ? AppTheme.greenDim : AppTheme.accentDim,
                border: Border.all(
                  color: bt.isConnected
                      ? AppTheme.green.withAlpha(100)
                      : AppTheme.accent.withAlpha(100),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    bt.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    size: 14,
                    color: bt.isConnected ? AppTheme.green : AppTheme.accent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    bt.isConnected ? 'Disconnect' : 'Connect',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: bt.isConnected ? AppTheme.green : AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppTheme.accent,
        indicatorWeight: 2,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'DASHBOARD'),
          Tab(text: 'PID / CONTROL'),
          Tab(text: 'LOG'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bt = context.watch<RobotBluetoothService>();
    final rs = bt.robotState;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          child: Row(
            children: [
              TiltVisualizer(angleDeg: rs.angle),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rs.angle.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w800,
                      letterSpacing: -2, height: 1,
                      color: rs.fallen
                          ? AppTheme.warn
                          : rs.angle.abs() < 5
                              ? AppTheme.green
                              : Colors.white,
                    ),
                  ),
                  const Text('degrees tilt',
                      style: TextStyle(fontSize: 10, letterSpacing: 1,
                          color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Text(
                    rs.angle.abs() < 5
                        ? '● Balanced'
                        : rs.fallen
                            ? '⚠ FALLEN'
                            : '○ Balancing…',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: rs.fallen
                          ? AppTheme.warn
                          : rs.angle.abs() < 5
                              ? AppTheme.green
                              : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (rs.fallen)
                    _AlertChip(label: '⚠ FALLEN', color: AppTheme.warn),
                  if (rs.obstacleDetected)
                    _AlertChip(label: '◀ OBSTACLE', color: AppTheme.warn),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: StatBox(
              value: rs.pidError.toStringAsFixed(1),
              label: 'PID Error',
            )),
            const SizedBox(width: 8),
            Expanded(child: StatBox(
              value: rs.pidOutput.toStringAsFixed(0),
              label: 'Motor Out',
            )),
            const SizedBox(width: 8),
            Expanded(child: StatBox(
              value: rs.loopMs.toStringAsFixed(1),
              label: 'Loop ms',
            )),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('ANGLE & OUTPUT — LIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              const ChartLegend(),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: LiveChart(points: bt.chartPoints),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          title: 'Setpoint (°)',
          child: Column(
            children: [
              Text(
                '${bt.setpoint.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: AppTheme.accent, letterSpacing: -1,
                ),
              ),
              const Text('Adjust if robot drifts forward/backward',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('-10°',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.accent,
                        inactiveTrackColor: AppTheme.surface2,
                        thumbColor: AppTheme.accent,
                        overlayColor: AppTheme.accentDim,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: bt.setpoint.clamp(-10.0, 10.0),
                        min: -10, max: 10, divisions: 40,
                        onChanged: bt.isConnected ? bt.updateSetpoint : null,
                      ),
                    ),
                  ),
                  const Text('+10°',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
              AppButton(
                label: 'Send Setpoint',
                onTap: bt.isConnected ? () => bt.sendSetpoint() : null,
                color: AppTheme.accentDim,
                borderColor: AppTheme.accent.withAlpha(100),
                textColor: AppTheme.accent,
                expanded: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ObstacleCard(distance: rs.distance, detected: rs.obstacleDetected),
      ],
    );
  }
}

class _PidTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: PidPanel(),
    );
  }
}

class _LogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bt = context.watch<RobotBluetoothService>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          title: 'Quick Commands',
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              AppButton(
                label: 'PING',
                onTap: bt.isConnected ? () => bt.sendCmd('PING') : null,
              ),
              AppButton(
                label: 'STOP',
                onTap: bt.isConnected ? () => bt.sendCmd('STOP') : null,
                color: AppTheme.warnDim,
                borderColor: AppTheme.warn.withAlpha(100),
                textColor: AppTheme.warn,
              ),
              AppButton(
                label: 'GO',
                onTap: bt.isConnected ? () => bt.sendCmd('GO') : null,
                color: AppTheme.greenDim,
                borderColor: AppTheme.green.withAlpha(100),
                textColor: AppTheme.green,
              ),
              AppButton(
                label: 'CALIB',
                onTap: bt.isConnected ? () => bt.sendCmd('CALIB') : null,
                color: AppTheme.accentDim,
                borderColor: AppTheme.accent.withAlpha(100),
                textColor: AppTheme.accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const LogPanel(),
      ],
    );
  }
}

class _ObstacleCard extends StatelessWidget {
  final double distance;
  final bool detected;

  const _ObstacleCard({required this.distance, required this.detected});

  @override
  Widget build(BuildContext context) {
    final isClose = distance < 20;
    final barPct = (distance.clamp(0, 200) / 200).clamp(0.0, 1.0);

    return AppCard(
      title: 'Obstacle Sensor (HC-SR04)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: detected ? 'OBSTACLE' : distance < 999 ? 'Clear' : 'No data',
                color: detected ? AppTheme.warn : AppTheme.green,
                pulse: detected,
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: distance >= 999 ? '---' : distance.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: isClose ? AppTheme.warn : Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const TextSpan(
                      text: ' cm',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barPct,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isClose ? AppTheme.warn : AppTheme.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
              Text('20cm', style: TextStyle(fontSize: 9, color: AppTheme.warn)),
              Text('100 cm', style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
              Text('200 cm', style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Trigger: < 20 cm → reverse\nClear: > 25 cm → resume PID',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final BtConnectionState state;
  final String deviceName;

  const _ConnectionBadge({required this.state, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    bool pulse = false;

    switch (state) {
      case BtConnectionState.connected:
        color = AppTheme.green;
        label = deviceName.isNotEmpty ? deviceName : 'Connected';
        break;
      case BtConnectionState.connecting:
        color = AppTheme.accent;
        label = 'Connecting…';
        pulse = true;
        break;
      case BtConnectionState.error:
        color = AppTheme.warn;
        label = 'Error';
        break;
      case BtConnectionState.disconnected:
        color = AppTheme.textMuted;
        label = 'Disconnected';
    }

    return StatusBadge(label: label, color: color, pulse: pulse);
  }
}

class _AlertChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AlertChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
