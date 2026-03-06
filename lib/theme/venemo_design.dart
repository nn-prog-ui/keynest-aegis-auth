import 'package:flutter/material.dart';

class VenemoPalette {
  static const Color surfaceBackground = Color(0xFFF5F5F7);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFE5E7EB);
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryDeep = Color(0xFF0066CC);
  static const Color textMain = Color(0xFF111418);
  static const Color textSub = Color(0xFF6B7280);

  static const LinearGradient subtleBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F6F8)],
  );
}

class SparkBackground extends StatelessWidget {
  final Widget child;
  final bool withClouds;

  const SparkBackground({
    super.key,
    required this.child,
    this.withClouds = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: VenemoPalette.subtleBackground),
      child: child,
    );
  }
}

class FrostedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FrostedPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VenemoPalette.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: VenemoPalette.panelDark,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
