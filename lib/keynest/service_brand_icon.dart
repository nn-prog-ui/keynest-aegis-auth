import 'package:flutter/material.dart';

import 'aegis_palette.dart';
import 'service_master.dart';

class ServiceBrandIcon extends StatelessWidget {
  const ServiceBrandIcon({
    super.key,
    this.service,
    this.fallbackName = '',
    this.size = 44,
  });

  final ServiceMaster? service;
  final String fallbackName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoAsset = service?.logoAsset.trim() ?? '';
    final color = Color(service?.iconColor ?? AegisPalette.brand.value);
    final iconStyle = service?.iconStyle.trim().toLowerCase() ?? 'solid';
    final label = service?.resolvedIconLabel ?? _fallbackLabel;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: _decorationFor(iconStyle, color),
      clipBehavior: Clip.antiAlias,
      child: logoAsset.isNotEmpty
          ? Padding(
              padding: EdgeInsets.all(size * 0.18),
              child: Image.asset(
                logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _LabelIcon(
                    label: label,
                    color: _foregroundFor(iconStyle, color),
                    size: size,
                  );
                },
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                if (iconStyle == 'accent')
                  Positioned(
                    right: size * 0.17,
                    bottom: size * 0.17,
                    child: Container(
                      width: size * 0.34,
                      height: size * 0.075,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                if (iconStyle == 'grid') _GridMark(color: color, size: size),
                _LabelIcon(
                  label: label,
                  color: _foregroundFor(iconStyle, color),
                  size: size,
                ),
              ],
            ),
    );
  }

  String get _fallbackLabel {
    final trimmed = fallbackName.trim();
    if (trimmed.isEmpty) {
      return 'F';
    }
    return trimmed.characters.first.toUpperCase();
  }

  BoxDecoration _decorationFor(String iconStyle, Color color) {
    final isSoft = iconStyle == 'soft';
    final isOutline = iconStyle == 'outline';
    final background = isOutline
        ? Colors.white
        : (isSoft ? color.withValues(alpha: 0.12) : color);

    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * 0.28),
      border: Border.all(
        color: isOutline ? color : color.withValues(alpha: 0.22),
        width: isOutline ? 1.5 : 1,
      ),
    );
  }

  Color _foregroundFor(String iconStyle, Color color) {
    if (iconStyle == 'soft' || iconStyle == 'outline') {
      return color;
    }
    return Colors.white;
  }
}

class _LabelIcon extends StatelessWidget {
  const _LabelIcon({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        color: color,
        fontSize: label.characters.length > 2 ? size * 0.27 : size * 0.36,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class _GridMark extends StatelessWidget {
  const _GridMark({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: size * 0.16,
      top: size * 0.16,
      child: Wrap(
        spacing: size * 0.05,
        runSpacing: size * 0.05,
        children: List.generate(
          4,
          (_) => Container(
            width: size * 0.12,
            height: size * 0.12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(size * 0.025),
            ),
          ),
        ),
      ),
    );
  }
}
