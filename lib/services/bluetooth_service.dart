// lib/services/bluetooth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/robot_state.dart';

enum BtConnectionState { disconnected, connecting, connected, error }

class RobotBluetoothService extends ChangeNotifier {
  // ── Connection state ────────────────────────────────────────
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BtConnectionState.connected;

  BluetoothConnection? _connection;
  String _connectedDeviceName = '';
  String get connectedDeviceName => _connectedDeviceName;

  // ── Robot state ─────────────────────────────────────────────
  RobotState _robotState = const RobotState();
  RobotState get robotState => _robotState;

  // ── Chart data ──────────────────────────────────────────────
  final List<ChartPoint> chartPoints = [];
  static const int maxChartPoints = 200;

  // ── Log ─────────────────────────────────────────────────────
  final List<LogEntry> logEntries = [];
  static const int maxLogEntries = 120;

  // ── PID & setpoint ──────────────────────────────────────────
  double kp = 15.0;
  double ki = 0.0;
  double kd = 0.8;
  double setpoint = 0.0;

  // ── Calibration ─────────────────────────────────────────────
  bool calibrating = false;

  // ── Internal ────────────────────────────────────────────────
  String _lineBuffer = '';
  StreamSubscription? _inputSub;

  // ════════════════════════════════════════════════════════════
  //  Connect to a paired HC-05 device
  // ════════════════════════════════════════════════════════════
  Future<void> connectTo(BluetoothDevice device) async {
    _setConnectionState(BtConnectionState.connecting);
    _addLog('Connecting to ${device.name ?? device.address}…', LogType.info);

    try {
      _connection = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 12));

      _connectedDeviceName = device.name ?? device.address;
      _setConnectionState(BtConnectionState.connected);
      _addLog('Connected — ${device.name}', LogType.ack);

      _inputSub = _connection!.input!
          .map((bytes) => utf8.decode(bytes, allowMalformed: true))
          .listen(
            _onData,
            onDone: _onDisconnected,
            onError: (e) {
              _addLog('Read error: $e', LogType.warn);
              _onDisconnected();
            },
          );

      await Future.delayed(const Duration(milliseconds: 400));
      await sendCmd('PING');
    } catch (e) {
      _setConnectionState(BtConnectionState.error);
      _addLog('Connection failed: $e', LogType.warn);
    }
  }

  void _onDisconnected() {
    _connection = null;
    _inputSub?.cancel();
    _inputSub = null;
    _lineBuffer = '';
    _connectedDeviceName = '';
    _setConnectionState(BtConnectionState.disconnected);
    _addLog('Bluetooth disconnected.', LogType.info);
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _onDisconnected();
  }

  // ════════════════════════════════════════════════════════════
  //  Send command
  // ════════════════════════════════════════════════════════════
  Future<void> sendCmd(String cmd) async {
    if (_connection == null || !isConnected) {
      _addLog('No connection — command not sent', LogType.warn);
      return;
    }
    try {
      _connection!.output.add(utf8.encode('$cmd\n'));
      await _connection!.output.allSent;
    } catch (e) {
      _addLog('Send failed: $e', LogType.warn);
    }
  }

  Future<void> sendPID() async {
    await sendCmd('P:${kp.toStringAsFixed(2)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('I:${ki.toStringAsFixed(3)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('D:${kd.toStringAsFixed(2)}');
  }

  Future<void> sendSetpoint() async {
    await sendCmd('S:${setpoint.toStringAsFixed(2)}');
  }

  Future<void> saveToEEPROM() async {
    await sendCmd('P:${kp.toStringAsFixed(2)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('I:${ki.toStringAsFixed(3)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('D:${kd.toStringAsFixed(2)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('S:${setpoint.toStringAsFixed(2)}');
    await Future.delayed(const Duration(milliseconds: 40));
    await sendCmd('SAVE');
  }

  Future<void> calibrate() async {
    calibrating = true;
    notifyListeners();
    await sendCmd('CALIB');
  }

  // ════════════════════════════════════════════════════════════
  //  Parse incoming data
  // ════════════════════════════════════════════════════════════
  void _onData(String chunk) {
    _lineBuffer += chunk;
    final parts = _lineBuffer.split('\n');
    _lineBuffer = parts.removeLast();
    for (final line in parts) {
      _processLine(line.trim());
    }
  }

  final _reAngle = RegExp(r'Angle:([-\d.]+)');
  final _reErr   = RegExp(r'Err:([-\d.]+)');
  final _reOut   = RegExp(r'Out:([-\d.]+)');
  final _reDist  = RegExp(r'Dist:([\d.]+)');
  final _reDt    = RegExp(r'dt:([\d.]+)');

  void _processLine(String line) {
    if (line.isEmpty) return;

    if (line.startsWith('Angle:')) {
      final angle  = double.tryParse(_reAngle.firstMatch(line)?.group(1) ?? '') ?? 0;
      final err    = double.tryParse(_reErr.firstMatch(line)?.group(1)   ?? '') ?? 0;
      final output = double.tryParse(_reOut.firstMatch(line)?.group(1)   ?? '') ?? 0;
      final dist   = double.tryParse(_reDist.firstMatch(line)?.group(1)  ?? '') ?? 999;
      final dt     = double.tryParse(_reDt.firstMatch(line)?.group(1)    ?? '') ?? 0;

      _robotState = _robotState.copyWith(
        angle: angle,
        pidError: err,
        pidOutput: output,
        distance: dist,
        loopMs: dt,
        fallen: angle.abs() > 45,
      );

      chartPoints.add(ChartPoint(
        angle: angle,
        output: output,
        setpoint: setpoint,
        time: DateTime.now(),
      ));
      if (chartPoints.length > maxChartPoints) {
        chartPoints.removeAt(0);
      }

      _addLog(line, LogType.data);
      notifyListeners();
      return;
    }

    if (line == 'OBS:1') {
      _robotState = _robotState.copyWith(obstacleDetected: true);
      _addLog('Obstacle detected — reversing', LogType.warn);
    } else if (line == 'OBS:0') {
      _robotState = _robotState.copyWith(obstacleDetected: false);
      _addLog('Obstacle cleared — resuming balance', LogType.ack);
    } else if (line == 'CAL:START') {
      calibrating = true;
      _addLog('Calibration started — hold still…', LogType.info);
    } else if (line == 'CAL:DONE') {
      calibrating = false;
      _addLog('Calibration complete ✓', LogType.ack);
    } else if (line.startsWith('SETPOINT:')) {
      final sv = double.tryParse(line.split(':')[1]);
      if (sv != null) {
        setpoint = sv;
        _addLog('Setpoint reset to ${sv.toStringAsFixed(1)}°', LogType.ack);
      }
    } else if (line == 'SAVED') {
      _addLog('Settings saved to EEPROM ✓', LogType.ack);
    } else if (line == 'PONG') {
      _addLog('PONG — Arduino responding', LogType.ack);
    } else if (line.startsWith('ACK:')) {
      _addLog(line, LogType.ack);
    } else if (line.isNotEmpty) {
      _addLog(line, LogType.data);
    }

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════════
  void _setConnectionState(BtConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  void _addLog(String text, LogType type) {
    logEntries.add(LogEntry(text: text, type: type, time: DateTime.now()));
    if (logEntries.length > maxLogEntries) logEntries.removeAt(0);
  }

  void clearLog() {
    logEntries.clear();
    notifyListeners();
  }

  void updateKp(double v) { kp = v; notifyListeners(); }
  void updateKi(double v) { ki = v; notifyListeners(); }
  void updateKd(double v) { kd = v; notifyListeners(); }
  void updateSetpoint(double v) { setpoint = v; notifyListeners(); }
}

// ── Log entry ────────────────────────────────────────────────
enum LogType { data, ack, warn, info }

class LogEntry {
  final String text;
  final LogType type;
  final DateTime time;
  LogEntry({required this.text, required this.type, required this.time});
}
