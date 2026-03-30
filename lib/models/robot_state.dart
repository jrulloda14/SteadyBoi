// lib/models/robot_state.dart

class RobotState {
  final double angle;
  final double pidError;
  final double pidOutput;
  final double distance;
  final double loopMs;
  final bool fallen;
  final bool obstacleDetected;

  const RobotState({
    this.angle = 0,
    this.pidError = 0,
    this.pidOutput = 0,
    this.distance = 999,
    this.loopMs = 0,
    this.fallen = false,
    this.obstacleDetected = false,
  });

  RobotState copyWith({
    double? angle,
    double? pidError,
    double? pidOutput,
    double? distance,
    double? loopMs,
    bool? fallen,
    bool? obstacleDetected,
  }) {
    return RobotState(
      angle: angle ?? this.angle,
      pidError: pidError ?? this.pidError,
      pidOutput: pidOutput ?? this.pidOutput,
      distance: distance ?? this.distance,
      loopMs: loopMs ?? this.loopMs,
      fallen: fallen ?? this.fallen,
      obstacleDetected: obstacleDetected ?? this.obstacleDetected,
    );
  }
}

class ChartPoint {
  final double angle;
  final double output;
  final double setpoint;
  final DateTime time;

  ChartPoint({
    required this.angle,
    required this.output,
    required this.setpoint,
    required this.time,
  });
}
