// lib/widgets/log_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../theme.dart';
import 'common_widgets.dart';

class LogPanel extends StatefulWidget {
  const LogPanel({super.key});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<RobotBluetoothService>();
    _scrollToBottom();

    return AppCard(
      title: 'Serial Log',
      titleTrailing: AppButton(
        label: 'Clear',
        small: true,
        onTap: bt.clearLog,
      ),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: bt.logEntries.isEmpty
            ? const Center(
                child: Text('No data yet…',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              )
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(8),
                itemCount: bt.logEntries.length,
                itemBuilder: (ctx, i) {
                  final entry = bt.logEntries[i];
                  return _LogLine(entry: entry);
                },
              ),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;
  const _LogLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color color;
    String prefix;

    switch (entry.type) {
      case LogType.ack:
        color = AppTheme.green;
        prefix = '✓ ';
        break;
      case LogType.warn:
        color = AppTheme.warn;
        prefix = '⚠ ';
        break;
      case LogType.info:
        color = AppTheme.accent;
        prefix = 'ℹ ';
        break;
      case LogType.data:
        color = const Color(0xFF8899BB);
        prefix = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$prefix${entry.text}',
        style: TextStyle(
          fontSize: 10.5,
          fontFamily: 'monospace',
          color: color,
          height: 1.5,
        ),
      ),
    );
  }
}
