import 'package:flutter/material.dart';

/// Renderização vetorial precisa do logotipo oficial do Google (G de 4 cores).
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Cores oficiais do Google
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final strokeWidth = w * 0.20;
    final innerRadius = radius - strokeWidth / 2;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Arco Azul (Right side)
    paint.color = blue;
    canvas.drawArc(innerRect, -0.65, 1.3, false, paint);

    // Barra horizontal azul central (inicia no centro e vai até o anel à direita)
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - strokeWidth / 2, radius + 1 - (center.dx - 1), strokeWidth),
      barPaint,
    );

    // Arco Verde (Bottom)
    paint.color = green;
    canvas.drawArc(innerRect, 0.65, 1.45, false, paint);

    // Arco Amarelo (Left / Bottom-left)
    paint.color = yellow;
    canvas.drawArc(innerRect, 2.10, 1.35, false, paint);

    // Arco Vermelho (Top)
    paint.color = red;
    canvas.drawArc(innerRect, 3.45, 1.55, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
