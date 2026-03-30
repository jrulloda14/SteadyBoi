// lib/widgets/pid_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../theme.dart';
import 'common_widgets.dart';

class PidPanel extends StatefulWidget {
  const PidPanel({super.key});

  @override
  State<PidPanel> createState() => _PidPanelState();
}

class _PidPanelState extends State<PidPanel> {
  bool _autoSend = true;
  bool _saving = false;
  bool _savedFlash = false;

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<RobotBluetoothService>();
    final enabled = bt.isConnected;

    return Column(
      children: [
        AppCard(
          title: 'PID Gains',
          child: Column(
            children: [
              _PidRow(
                label: 'Kp', name: 'Proportional',
                value: bt.kp, min: 0, max: 100, step: 0.5,
                enabled: enabled,
                onChanged: (v) {
                  bt.updateKp(v);
                  if (_autoSend && enabled) _debouncedSend(bt);
                },
              ),
              const SizedBox(height: 16),
              _PidRow(
                label: 'Ki', name: 'Integral',
                value: bt.ki, min: 0, max: 5, step: 0.05,
                enabled: enabled,
                onChanged: (v) {
                  bt.updateKi(v);
                  if (_autoSend && enabled) _debouncedSend(bt);
                },
              ),
              const SizedBox(height: 16),
              _PidRow(
                label: 'Kd', name: 'Derivative',
                value: bt.kd, min: 0, max: 10, step: 0.1,
                enabled: enabled,
                onChanged: (v) {
                  bt.updateKd(v);
                  if (_autoSend && enabled) _debouncedSend(bt);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Send PID',
                      onTap: enabled ? () => bt.sendPID() : null,
                      expanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _autoSend = !_autoSend),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _autoSend
                            ? AppTheme.accentDim
                            : AppTheme.surface2,
                        border: Border.all(
                          color: _autoSend
                              ? AppTheme.accent.withAlpha(100)
                              : AppTheme.border,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'Auto ${_autoSend ? '✓' : '✗'}',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _autoSend
                              ? AppTheme.accent
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: (enabled && !_saving) ? () => _doSave(bt) : null,
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.35,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _savedFlash
                          ? AppTheme.greenDim
                          : AppTheme.greenDim.withAlpha(80),
                      border: Border.all(
                        color: AppTheme.green
                            .withAlpha(_savedFlash ? 150 : 80),
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _savedFlash
                              ? Icons.check
                              : Icons.save_outlined,
                          size: 14,
                          color: AppTheme.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _saving
                              ? 'Saving…'
                              : _savedFlash
                                  ? 'Saved to EEPROM!'
                                  : 'Save to Robot (EEPROM)',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          title: 'Calibration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hold robot still & upright then press.\nZeroes gyro drift + MPU mounting angle.\nMotors stop briefly, then resume.',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textMuted, height: 1.7),
              ),
              const SizedBox(height: 10),
              if (bt.calibrating)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim,
                    border:
                        Border.all(color: AppTheme.accent.withAlpha(80)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accent,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Calibrating — hold still…',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent)),
                    ],
                  ),
                ),
              AppButton(
                label: '⟳  Recalibrate',
                onTap: (enabled && !bt.calibrating)
                    ? () => bt.calibrate()
                    : null,
                color: AppTheme.accentDim,
                borderColor: AppTheme.accent.withAlpha(100),
                textColor: AppTheme.accent,
                expanded: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          title: 'Motor Test',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lift robot off ground first.\nEach test runs ~800ms then stops.',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textMuted, height: 1.7),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: AppButton(
                    label: '▶▶ Both Fwd',
                    onTap: enabled ? () => bt.sendCmd('TESTFWD') : null,
                    color: AppTheme.accentDim,
                    borderColor: AppTheme.accent.withAlpha(100),
                    textColor: AppTheme.accent,
                    expanded: true,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: AppButton(
                    label: '◀◀ Both Bwd',
                    onTap: enabled ? () => bt.sendCmd('TESTBWD') : null,
                    color: AppTheme.accentDim,
                    borderColor: AppTheme.accent.withAlpha(100),
                    textColor: AppTheme.accent,
                    expanded: true,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Individual motors:',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: AppButton(
                    label: 'L ▶ Fwd', small: true, expanded: true,
                    onTap: enabled ? () => bt.sendCmd('LFWD') : null,
                  )),
                  const SizedBox(width: 6),
                  Expanded(child: AppButton(
                    label: 'R ▶ Fwd', small: true, expanded: true,
                    onTap: enabled ? () => bt.sendCmd('RFWD') : null,
                  )),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: AppButton(
                    label: 'L ◀ Bwd', small: true, expanded: true,
                    onTap: enabled ? () => bt.sendCmd('LBWD') : null,
                  )),
                  const SizedBox(width: 6),
                  Expanded(child: AppButton(
                    label: 'R ◀ Bwd', small: true, expanded: true,
                    onTap: enabled ? () => bt.sendCmd('RBWD') : null,
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          title: 'Tuning Guide',
          child: const Text(
            '1. Ki=0, Kd=0 · raise Kp by +2\n'
            '2. Oscillating? Back Kp off 30%\n'
            '3. Raise Kd to damp the bounce\n'
            '    (filter absorbs gyro noise)\n'
            '4. Add tiny Ki (0.1–0.3) last\n'
            '5. Adjust Setpoint if it drifts\n'
            '⚠ Falls at 45° — motors stop',
            style: TextStyle(
              fontSize: 12, color: AppTheme.textMuted, height: 1.9,
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _lastSend;
  void _debouncedSend(RobotBluetoothService bt) {
    final now = DateTime.now();
    if (_lastSend == null ||
        now.difference(_lastSend!) >
            const Duration(milliseconds: 300)) {
      _lastSend = now;
      bt.sendPID();
    }
  }

  Future<void> _doSave(RobotBluetoothService bt) async {
    setState(() => _saving = true);
    await bt.saveToEEPROM();
    setState(() {
      _saving = false;
      _savedFlash = true;
    });
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _savedFlash = false);
  }
}

class _PidRow extends StatelessWidget {
  final String label;
  final String name;
  final double value;
  final double min;
  final double max;
  final double step;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _PidRow({
    required this.label, required this.name, required this.value,
    required this.min, required this.max, required this.step,
    required this.enabled, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: '  $name',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(step < 0.1 ? 3 : step < 1 ? 2 : 1),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.surface2,
            thumbColor: AppTheme.accent,
            overlayColor: AppTheme.accentDim,
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min, max: max,
            divisions: ((max - min) / step).round(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
