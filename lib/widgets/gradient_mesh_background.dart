import 'dart:math';
import 'package:flutter/material.dart';

class GradientMeshBackground extends StatefulWidget {
  final Widget child;
  const GradientMeshBackground({super.key, required this.child});

  @override
  State<GradientMeshBackground> createState() =>
      _GradientMeshBackgroundState();
}

class _GradientMeshBackgroundState extends State<GradientMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(_controller.value),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: child!,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;

  _MeshPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withOpacity(0.12),
          const Color(0xFF0A0A0F).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.3 + 0.2 * sin(t)),
          size.height * (0.2 + 0.15 * cos(t * 0.85)),
        ),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF448AFF).withOpacity(0.1),
          const Color(0xFF0A0A0F).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.7 + 0.15 * cos(t * 0.65)),
          size.height * (0.8 + 0.1 * sin(t * 0.95)),
        ),
        radius: size.width * 0.45,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A0A3E).withOpacity(0.15),
          const Color(0xFF0A0A0F).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.5 + 0.2 * sin(t * 1.15 + 1)),
          size.height * (0.5 + 0.2 * cos(t * 0.75 + 1)),
        ),
        radius: size.width * 0.5,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint3);
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
