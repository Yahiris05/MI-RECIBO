import 'package:flutter/material.dart';
import '../theme.dart';

class WavesBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintOrange = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    final paintNavy = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.fill;

    // 1. Dibujar la curva naranja (Fondo)
    final pathOrange = Path();
    pathOrange.moveTo(0, size.height * 0.45);
    
    // Curva de control 1: de (0, 0.45h) a (w, 0.35h) pasando por control (0.3w, 0.1h) y (0.7w, 0.7h)
    pathOrange.cubicTo(
      size.width * 0.3, size.height * 0.15,
      size.width * 0.65, size.height * 0.65,
      size.width, size.height * 0.3
    );
    pathOrange.lineTo(size.width, size.height);
    pathOrange.lineTo(0, size.height);
    pathOrange.close();
    
    canvas.drawPath(pathOrange, paintOrange);

    // 2. Dibujar la curva azul marino (Frente)
    final pathNavy = Path();
    pathNavy.moveTo(0, size.height * 0.6);
    
    // Curva de control 2: de (0, 0.6h) a (w, 0.5h) con bezier
    pathNavy.cubicTo(
      size.width * 0.35, size.height * 0.35,
      size.width * 0.6, size.height * 0.8,
      size.width, size.height * 0.48
    );
    pathNavy.lineTo(size.width, size.height);
    pathNavy.lineTo(0, size.height);
    pathNavy.close();

    canvas.drawPath(pathNavy, paintNavy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavesBackgroundWidget extends StatelessWidget {
  final double height;
  const WavesBackgroundWidget({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: WavesBackgroundPainter(),
      ),
    );
  }
}
