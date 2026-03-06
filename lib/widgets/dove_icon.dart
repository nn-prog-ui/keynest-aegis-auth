import 'package:flutter/material.dart';

class DoveIcon extends StatelessWidget {
  final double size;

  const DoveIcon({Key? key, this.size = 180}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MinimalistDovePainter(),
    );
  }
}

class MinimalistDovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double scale = size.width / 200;
    canvas.scale(scale);

    const double cx = 100;
    const double cy = 100;

    // 体（シンプルな楕円形）
    final bodyPath = Path();
    bodyPath.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 10),
        width: 60,
        height: 45,
      ),
    );
    canvas.drawPath(bodyPath, paint);

    // 頭（小さい円）
    canvas.drawCircle(Offset(cx - 38, cy - 5), 15, paint);

    // 目（小さい黒点）
    canvas.drawCircle(
      Offset(cx - 35, cy - 5),
      2,
      Paint()..color = const Color(0xFF333333),
    );

    // くちばし（三角形）
    final beakPath = Path();
    beakPath.moveTo(cx - 50, cy - 5);
    beakPath.lineTo(cx - 60, cy - 7);
    beakPath.lineTo(cx - 50, cy - 2);
    beakPath.close();
    canvas.drawPath(beakPath, paint);

    // 左の翼（大きく広がる）
    final leftWingPath = Path();
    leftWingPath.moveTo(cx - 15, cy + 5);
    leftWingPath.quadraticBezierTo(
      cx - 45, cy - 50,
      cx - 55, cy - 60,
    );
    leftWingPath.quadraticBezierTo(
      cx - 48, cy - 55,
      cx - 30, cy - 30,
    );
    leftWingPath.quadraticBezierTo(
      cx - 20, cy - 10,
      cx - 10, cy + 8,
    );
    leftWingPath.close();
    canvas.drawPath(leftWingPath, paint);

    // 左の翼の羽根線（3本）
    final featherPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx - 20, cy - 5), Offset(cx - 35, cy - 30), featherPaint);
    canvas.drawLine(Offset(cx - 25, cy - 10), Offset(cx - 42, cy - 42), featherPaint);
    canvas.drawLine(Offset(cx - 30, cy - 15), Offset(cx - 48, cy - 52), featherPaint);

    // 右の翼（大きく広がる）
    final rightWingPath = Path();
    rightWingPath.moveTo(cx + 10, cy + 5);
    rightWingPath.quadraticBezierTo(
      cx + 40, cy - 50,
      cx + 50, cy - 60,
    );
    rightWingPath.quadraticBezierTo(
      cx + 43, cy - 55,
      cx + 25, cy - 30,
    );
    rightWingPath.quadraticBezierTo(
      cx + 15, cy - 10,
      cx + 5, cy + 8,
    );
    rightWingPath.close();
    canvas.drawPath(rightWingPath, paint);

    // 右の翼の羽根線（3本）
    canvas.drawLine(Offset(cx + 15, cy - 5), Offset(cx + 30, cy - 30), featherPaint);
    canvas.drawLine(Offset(cx + 20, cy - 10), Offset(cx + 37, cy - 42), featherPaint);
    canvas.drawLine(Offset(cx + 25, cy - 15), Offset(cx + 43, cy - 52), featherPaint);

    // 尾羽（3本の羽根）
    final tailPath = Path();
    
    // 尾羽1
    tailPath.moveTo(cx + 30, cy + 15);
    tailPath.quadraticBezierTo(cx + 45, cy + 18, cx + 55, cy + 12);
    tailPath.quadraticBezierTo(cx + 48, cy + 15, cx + 32, cy + 18);
    tailPath.close();
    
    // 尾羽2
    tailPath.moveTo(cx + 30, cy + 22);
    tailPath.quadraticBezierTo(cx + 48, cy + 25, cx + 60, cy + 22);
    tailPath.quadraticBezierTo(cx + 52, cy + 25, cx + 32, cy + 25);
    tailPath.close();
    
    // 尾羽3
    tailPath.moveTo(cx + 30, cy + 28);
    tailPath.quadraticBezierTo(cx + 45, cy + 32, cx + 55, cy + 30);
    tailPath.quadraticBezierTo(cx + 48, cy + 32, cx + 32, cy + 30);
    tailPath.close();
    
    canvas.drawPath(tailPath, paint);

    // 足（2本）
    final footPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 5, cy + 30), Offset(cx - 5, cy + 42), footPaint);
    canvas.drawLine(Offset(cx + 8, cy + 30), Offset(cx + 8, cy + 42), footPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
