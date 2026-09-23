import 'package:flutter/material.dart';

/// Ícone vetorial das ferramentas cruzadas (Auto Center Silva).
class CrossedWrenchesWidget extends StatelessWidget {
  final Color color;
  final double size;

  const CrossedWrenchesWidget({
    super.key,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrossedWrenchesPainter(color: color),
    );
  }
}

class _CrossedWrenchesPainter extends CustomPainter {
  final Color color;
  _CrossedWrenchesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..fillType = PathFillType.evenOdd;
    path.moveTo(size.width * 0.6000, size.height * 0.1600);
    path.lineTo(size.width * 0.5600, size.height * 0.1600);
    path.lineTo(size.width * 0.4800, size.height * 0.2200);
    path.lineTo(size.width * 0.4600, size.height * 0.2600);
    path.lineTo(size.width * 0.4600, size.height * 0.3400);
    path.lineTo(size.width * 0.3800, size.height * 0.4200);
    path.lineTo(size.width * 0.1600, size.height * 0.1800);
    path.lineTo(size.width * 0.1400, size.height * 0.1800);
    path.lineTo(size.width * 0.0600, size.height * 0.2600);
    path.lineTo(size.width * 0.2800, size.height * 0.4600);
    path.lineTo(size.width * 0.3200, size.height * 0.4800);
    path.lineTo(size.width * 0.2200, size.height * 0.5800);
    path.lineTo(size.width * 0.1400, size.height * 0.5800);
    path.lineTo(size.width * 0.1000, size.height * 0.6200);
    path.lineTo(size.width * 0.0800, size.height * 0.6200);
    path.lineTo(size.width * 0.0600, size.height * 0.6600);
    path.lineTo(size.width * 0.0600, size.height * 0.7600);
    path.lineTo(size.width * 0.1400, size.height * 0.6800);
    path.lineTo(size.width * 0.1600, size.height * 0.6800);
    path.lineTo(size.width * 0.2000, size.height * 0.7200);
    path.lineTo(size.width * 0.1800, size.height * 0.7800);
    path.lineTo(size.width * 0.1400, size.height * 0.8000);
    path.lineTo(size.width * 0.1600, size.height * 0.8400);
    path.lineTo(size.width * 0.2400, size.height * 0.8200);
    path.lineTo(size.width * 0.2800, size.height * 0.7800);
    path.lineTo(size.width * 0.2800, size.height * 0.7000);
    path.lineTo(size.width * 0.3000, size.height * 0.6600);
    path.lineTo(size.width * 0.3400, size.height * 0.6200);
    path.lineTo(size.width * 0.3600, size.height * 0.6200);
    path.lineTo(size.width * 0.3800, size.height * 0.5800);
    path.lineTo(size.width * 0.4200, size.height * 0.6000);
    path.lineTo(size.width * 0.4200, size.height * 0.6200);
    path.lineTo(size.width * 0.5600, size.height * 0.7600);
    path.lineTo(size.width * 0.5600, size.height * 0.7800);
    path.lineTo(size.width * 0.6000, size.height * 0.8200);
    path.lineTo(size.width * 0.6200, size.height * 0.8000);
    path.lineTo(size.width * 0.6000, size.height * 0.7600);
    path.lineTo(size.width * 0.6200, size.height * 0.7200);
    path.lineTo(size.width * 0.6600, size.height * 0.7600);
    path.lineTo(size.width * 0.7000, size.height * 0.7400);
    path.lineTo(size.width * 0.7000, size.height * 0.7200);
    path.lineTo(size.width * 0.6400, size.height * 0.6600);
    path.lineTo(size.width * 0.6200, size.height * 0.6600);
    path.lineTo(size.width * 0.5000, size.height * 0.5400);
    path.lineTo(size.width * 0.4600, size.height * 0.5200);
    path.lineTo(size.width * 0.4600, size.height * 0.5000);
    path.lineTo(size.width * 0.5000, size.height * 0.4800);
    path.lineTo(size.width * 0.5400, size.height * 0.4200);
    path.lineTo(size.width * 0.6400, size.height * 0.4200);
    path.lineTo(size.width * 0.7200, size.height * 0.3400);
    path.lineTo(size.width * 0.7200, size.height * 0.2800);
    path.lineTo(size.width * 0.7000, size.height * 0.2600);
    path.lineTo(size.width * 0.6200, size.height * 0.3400);
    path.lineTo(size.width * 0.5600, size.height * 0.2800);
    path.lineTo(size.width * 0.5600, size.height * 0.2400);
    path.lineTo(size.width * 0.6000, size.height * 0.2000);
    path.lineTo(size.width * 0.6200, size.height * 0.2000);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrossedWrenchesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Ícone vetorial da xícara de café com vapor (Café Aurora).
class CoffeeCupWidget extends StatelessWidget {
  final Color color;
  final double size;

  const CoffeeCupWidget({
    super.key,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CoffeeCupPainter(color: color),
    );
  }
}

class _CoffeeCupPainter extends CustomPainter {
  final Color color;
  _CoffeeCupPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..fillType = PathFillType.evenOdd;

    // Corpo da xícara
    path.moveTo(size.width * 0.1000, size.height * 0.4000);
    path.lineTo(size.width * 0.1000, size.height * 0.5600);
    path.lineTo(size.width * 0.1200, size.height * 0.5800);
    path.lineTo(size.width * 0.1200, size.height * 0.6200);
    path.lineTo(size.width * 0.2000, size.height * 0.7200);
    path.lineTo(size.width * 0.2800, size.height * 0.7600);
    path.lineTo(size.width * 0.4000, size.height * 0.7600);
    path.lineTo(size.width * 0.4800, size.height * 0.7200);
    path.lineTo(size.width * 0.5600, size.height * 0.6200);
    path.lineTo(size.width * 0.6200, size.height * 0.6200);
    path.lineTo(size.width * 0.6600, size.height * 0.6000);
    path.lineTo(size.width * 0.6800, size.height * 0.5600);
    path.lineTo(size.width * 0.6800, size.height * 0.4800);
    path.lineTo(size.width * 0.6400, size.height * 0.4400);
    path.lineTo(size.width * 0.6000, size.height * 0.4400);
    path.lineTo(size.width * 0.5600, size.height * 0.4000);
    path.close();

    // Furo da alça
    path.moveTo(size.width * 0.6000, size.height * 0.4600);
    path.lineTo(size.width * 0.6400, size.height * 0.5000);
    path.lineTo(size.width * 0.6400, size.height * 0.5400);
    path.lineTo(size.width * 0.5800, size.height * 0.6000);
    path.lineTo(size.width * 0.5600, size.height * 0.5800);
    path.lineTo(size.width * 0.5600, size.height * 0.5000);
    path.close();

    // Vapor 1
    path.moveTo(size.width * 0.2600, size.height * 0.2000);
    path.lineTo(size.width * 0.2200, size.height * 0.2400);
    path.lineTo(size.width * 0.2400, size.height * 0.3200);
    path.lineTo(size.width * 0.2800, size.height * 0.3200);
    path.lineTo(size.width * 0.2600, size.height * 0.2800);
    path.lineTo(size.width * 0.2600, size.height * 0.2400);
    path.lineTo(size.width * 0.2800, size.height * 0.2200);
    path.close();

    // Vapor 2 (central)
    path.moveTo(size.width * 0.3600, size.height * 0.1400);
    path.lineTo(size.width * 0.3400, size.height * 0.1400);
    path.lineTo(size.width * 0.3200, size.height * 0.3400);
    path.lineTo(size.width * 0.3600, size.height * 0.3400);
    path.lineTo(size.width * 0.3600, size.height * 0.3000);
    path.lineTo(size.width * 0.3400, size.height * 0.2800);
    path.lineTo(size.width * 0.3800, size.height * 0.2000);
    path.lineTo(size.width * 0.3800, size.height * 0.1600);
    path.close();

    // Vapor 3
    path.moveTo(size.width * 0.4600, size.height * 0.2000);
    path.lineTo(size.width * 0.4400, size.height * 0.2000);
    path.lineTo(size.width * 0.4200, size.height * 0.3000);
    path.lineTo(size.width * 0.4400, size.height * 0.3000);
    path.lineTo(size.width * 0.4800, size.height * 0.2400);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CoffeeCupPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Ícone vetorial da tesoura vertical (Barbearia Norte).
class VerticalScissorsWidget extends StatelessWidget {
  final Color color;
  final double size;

  const VerticalScissorsWidget({
    super.key,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VerticalScissorsPainter(color: color),
    );
  }
}

class _VerticalScissorsPainter extends CustomPainter {
  final Color color;
  _VerticalScissorsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..fillType = PathFillType.evenOdd;

    // Contorno exterior da tesoura
    path.moveTo(size.width * 0.1800, size.height * 0.1800);
    path.lineTo(size.width * 0.1600, size.height * 0.2200);
    path.lineTo(size.width * 0.1800, size.height * 0.3200);
    path.lineTo(size.width * 0.2200, size.height * 0.3600);
    path.lineTo(size.width * 0.2600, size.height * 0.4400);
    path.lineTo(size.width * 0.3400, size.height * 0.5000);
    path.lineTo(size.width * 0.2600, size.height * 0.6000);
    path.lineTo(size.width * 0.1800, size.height * 0.6000);
    path.lineTo(size.width * 0.1200, size.height * 0.6600);
    path.lineTo(size.width * 0.1200, size.height * 0.7600);
    path.lineTo(size.width * 0.1800, size.height * 0.8200);
    path.lineTo(size.width * 0.2400, size.height * 0.8200);
    path.lineTo(size.width * 0.2800, size.height * 0.8000);
    path.lineTo(size.width * 0.3200, size.height * 0.7600);
    path.lineTo(size.width * 0.3200, size.height * 0.6400);
    path.lineTo(size.width * 0.3800, size.height * 0.5800);
    path.lineTo(size.width * 0.4400, size.height * 0.6400);
    path.lineTo(size.width * 0.4400, size.height * 0.7600);
    path.lineTo(size.width * 0.5000, size.height * 0.8200);
    path.lineTo(size.width * 0.5600, size.height * 0.8200);
    path.lineTo(size.width * 0.6000, size.height * 0.8000);
    path.lineTo(size.width * 0.6400, size.height * 0.7600);
    path.lineTo(size.width * 0.6400, size.height * 0.6800);
    path.lineTo(size.width * 0.6200, size.height * 0.6400);
    path.lineTo(size.width * 0.5800, size.height * 0.6000);
    path.lineTo(size.width * 0.5000, size.height * 0.6000);
    path.lineTo(size.width * 0.4400, size.height * 0.5400);
    path.lineTo(size.width * 0.4600, size.height * 0.4600);
    path.lineTo(size.width * 0.5200, size.height * 0.4000);
    path.lineTo(size.width * 0.6000, size.height * 0.2600);
    path.lineTo(size.width * 0.5800, size.height * 0.2000);
    path.lineTo(size.width * 0.5600, size.height * 0.1800);
    path.lineTo(size.width * 0.5000, size.height * 0.2400);
    path.lineTo(size.width * 0.5000, size.height * 0.2600);
    path.lineTo(size.width * 0.4600, size.height * 0.3000);
    path.lineTo(size.width * 0.3800, size.height * 0.4400);
    path.lineTo(size.width * 0.3400, size.height * 0.4000);
    path.lineTo(size.width * 0.3200, size.height * 0.3400);
    path.lineTo(size.width * 0.2200, size.height * 0.2200);
    path.lineTo(size.width * 0.2200, size.height * 0.2000);
    path.close();

    // Aro direito (furo do dedo)
    path.moveTo(size.width * 0.5200, size.height * 0.6400);
    path.lineTo(size.width * 0.5600, size.height * 0.6400);
    path.lineTo(size.width * 0.6000, size.height * 0.6800);
    path.lineTo(size.width * 0.6000, size.height * 0.7400);
    path.lineTo(size.width * 0.5400, size.height * 0.7800);
    path.lineTo(size.width * 0.5200, size.height * 0.7800);
    path.lineTo(size.width * 0.4600, size.height * 0.7000);
    path.close();

    // Aro esquerdo (furo do dedo)
    path.moveTo(size.width * 0.2000, size.height * 0.6400);
    path.lineTo(size.width * 0.2400, size.height * 0.6400);
    path.lineTo(size.width * 0.2800, size.height * 0.6800);
    path.lineTo(size.width * 0.2800, size.height * 0.7400);
    path.lineTo(size.width * 0.2400, size.height * 0.7800);
    path.lineTo(size.width * 0.2000, size.height * 0.7800);
    path.lineTo(size.width * 0.1400, size.height * 0.7200);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VerticalScissorsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Ícone vetorial da pata de pet (Pet Vila).
class PawPrintWidget extends StatelessWidget {
  final Color color;
  final double size;

  const PawPrintWidget({
    super.key,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PawPrintPainter(color: color),
    );
  }
}

class _PawPrintPainter extends CustomPainter {
  final Color color;
  _PawPrintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..fillType = PathFillType.evenOdd;

    // Almofada principal (inferior)
    path.moveTo(size.width * 0.1800, size.height * 0.7000);
    path.lineTo(size.width * 0.1800, size.height * 0.7800);
    path.lineTo(size.width * 0.2400, size.height * 0.8200);
    path.lineTo(size.width * 0.2800, size.height * 0.8200);
    path.lineTo(size.width * 0.3400, size.height * 0.7800);
    path.lineTo(size.width * 0.4200, size.height * 0.7800);
    path.lineTo(size.width * 0.4400, size.height * 0.8000);
    path.lineTo(size.width * 0.5200, size.height * 0.8200);
    path.lineTo(size.width * 0.5600, size.height * 0.8000);
    path.lineTo(size.width * 0.5800, size.height * 0.7600);
    path.lineTo(size.width * 0.5800, size.height * 0.7000);
    path.lineTo(size.width * 0.4200, size.height * 0.5200);
    path.lineTo(size.width * 0.3400, size.height * 0.5200);
    path.lineTo(size.width * 0.3000, size.height * 0.5400);
    path.close();

    // Dedo 1 (direita superior)
    path.moveTo(size.width * 0.5800, size.height * 0.4400);
    path.lineTo(size.width * 0.5600, size.height * 0.4800);
    path.lineTo(size.width * 0.5600, size.height * 0.5600);
    path.lineTo(size.width * 0.5800, size.height * 0.5800);
    path.lineTo(size.width * 0.6400, size.height * 0.5800);
    path.lineTo(size.width * 0.6800, size.height * 0.5400);
    path.lineTo(size.width * 0.6800, size.height * 0.4600);
    path.lineTo(size.width * 0.6600, size.height * 0.4400);
    path.close();

    // Dedo 2 (esquerda inferior)
    path.moveTo(size.width * 0.1000, size.height * 0.4400);
    path.lineTo(size.width * 0.0800, size.height * 0.4600);
    path.lineTo(size.width * 0.0800, size.height * 0.5400);
    path.lineTo(size.width * 0.1200, size.height * 0.5800);
    path.lineTo(size.width * 0.1800, size.height * 0.5800);
    path.lineTo(size.width * 0.2200, size.height * 0.5200);
    path.lineTo(size.width * 0.2000, size.height * 0.4800);
    path.lineTo(size.width * 0.1600, size.height * 0.4400);
    path.close();

    // Dedo 3 (centro direita)
    path.moveTo(size.width * 0.4600, size.height * 0.2600);
    path.lineTo(size.width * 0.4200, size.height * 0.3000);
    path.lineTo(size.width * 0.4000, size.height * 0.3800);
    path.lineTo(size.width * 0.4400, size.height * 0.4400);
    path.lineTo(size.width * 0.5000, size.height * 0.4400);
    path.lineTo(size.width * 0.5400, size.height * 0.4000);
    path.lineTo(size.width * 0.5600, size.height * 0.3400);
    path.lineTo(size.width * 0.5000, size.height * 0.2600);
    path.close();

    // Dedo 4 (centro esquerda)
    path.moveTo(size.width * 0.2600, size.height * 0.2600);
    path.lineTo(size.width * 0.2000, size.height * 0.3200);
    path.lineTo(size.width * 0.2000, size.height * 0.3600);
    path.lineTo(size.width * 0.2600, size.height * 0.4400);
    path.lineTo(size.width * 0.3200, size.height * 0.4400);
    path.lineTo(size.width * 0.3600, size.height * 0.3600);
    path.lineTo(size.width * 0.3400, size.height * 0.3400);
    path.lineTo(size.width * 0.3400, size.height * 0.3000);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPrintPainter oldDelegate) =>
      oldDelegate.color != color;
}
