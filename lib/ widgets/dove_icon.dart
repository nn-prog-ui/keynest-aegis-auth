import 'package:flutter/material.dart';

class DoveIcon extends StatelessWidget {
  final double size;
  final Color color;

  const DoveIcon({
    super.key,
    this.size = 80,
    this.color = const Color(0xFFFF6F00),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: DovePainter(color: color),
    );
  }
}

class DovePainter extends CustomPainter {
  final Color color;

  DovePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // ピカソ風の鳩の体（簡略化されたデザイン）
    // 鳩の頭部
    path.moveTo(size.width * 0.6, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.25,
      size.width * 0.75,
      size.height * 0.3,
    );
    
    // 鳩の体
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.65,
    );
    
    // 鳩の尾
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      size.width * 0.3,
      size.height * 0.5,
    );
    
    // 翼（上部）
    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.2,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.45,
      size.width * 0.25,
      size.height * 0.5,
    );
    
    canvas.drawPath(path, paint);

    // 花束（口に咥えている）
    final flowerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 花びら（シンプルな円）
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.28),
      size.width * 0.05,
      flowerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.32),
      size.width * 0.04,
      flowerPaint,
    );

    // 目（小さな白い点）
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.32),
      size.width * 0.02,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
