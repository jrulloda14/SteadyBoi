// lib/widgets/common_widgets.dart

import 'package:flutter/material.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? titleTrailing;

  const AppCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: AppTheme.textMuted,
                    ),
                  ),
                  if (titleTrailing != null) titleTrailing!,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const StatBox({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 0.8, color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;
  final bool small;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.borderColor,
    this.textColor,
    this.icon,
    this.small = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final btn = GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: small ? 8 : 10,
            horizontal: small ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: color ?? AppTheme.surface2,
            border: Border.all(color: borderColor ?? AppTheme.border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 13 : 15,
                    color: textColor ?? AppTheme.textPrimary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color, pulse: pulse),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _Dot({required this.color, required this.pulse});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 1.0, end: 0.2).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: widget.color.withAlpha(180), blurRadius: 5)],
      ),
    );
    if (!widget.pulse) return dot;
    return FadeTransition(opacity: _anim, child: dot);
  }
}
