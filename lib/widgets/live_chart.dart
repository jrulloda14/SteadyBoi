// lib/widgets/live_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/robot_state.dart';
import '../theme.dart';

class LiveChart extends StatelessWidget {
  final List<ChartPoint> points;

  const LiveChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('Waiting for telemetry…',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      );
    }

    final angleSpots  = <FlSpot>[];
    final outputSpots = <FlSpot>[];
    final spSpots     = <FlSpot>[];

    final base = points.first.time.millisecondsSinceEpoch.toDouble();

    for (final p in points) {
      final x = (p.time.millisecondsSinceEpoch - base) / 1000.0;
      angleSpots.add(FlSpot(x, p.angle));
      outputSpots.add(FlSpot(x, p.output / 6.375));
      spSpots.add(FlSpot(x, p.setpoint));
    }

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppTheme.border, strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}°',
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 34,
              getTitlesWidget: (v, _) => Text(
                '${(v * 6.375).toInt()}',
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: -40, maxY: 40,
        lineBarsData: [
          LineChartBarData(
            spots: angleSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppTheme.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withAlpha(15),
            ),
          ),
          LineChartBarData(
            spots: outputSpots,
            isCurved: false,
            color: AppTheme.warn,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spSpots,
            isCurved: false,
            color: Colors.white.withAlpha(40),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: const [4, 4],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.surface2,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final labels = ['Angle', 'Output', 'Setpoint'];
              final colors = [AppTheme.accent, AppTheme.warn, Colors.white54];
              final i = s.barIndex;
              final val = i == 1
                  ? (s.y * 6.375).toStringAsFixed(0)
                  : s.y.toStringAsFixed(1);
              return LineTooltipItem(
                '${labels[i]}: $val',
                TextStyle(color: colors[i], fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendItem(color: AppTheme.accent, label: 'Angle (°)'),
        SizedBox(width: 14),
        _LegendItem(color: AppTheme.warn, label: 'Output (PWM)'),
        SizedBox(width: 14),
        _LegendItem(color: Colors.white38, label: 'Setpoint', dashed: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({
    super.key,
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16, height: 2,
          color: dashed ? Colors.transparent : color,
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}
