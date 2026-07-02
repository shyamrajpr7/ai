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

    // Base dark fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A0F),
    );

    // Large ambient gradient blobs
    _drawBlob(canvas, size, const Color(0xFF7C4DFF), 0.12,
      Offset(
        size.width * (0.3 + 0.2 * sin(t)),
        size.height * (0.2 + 0.15 * cos(t * 0.85)),
      ),
      size.width * 0.6,
    );

    _drawBlob(canvas, size, const Color(0xFF448AFF), 0.10,
      Offset(
        size.width * (0.7 + 0.15 * cos(t * 0.65)),
        size.height * (0.8 + 0.1 * sin(t * 0.95)),
      ),
      size.width * 0.45,
    );

    _drawBlob(canvas, size, const Color(0xFF1A0A3E), 0.18,
      Offset(
        size.width * (0.5 + 0.2 * sin(t * 1.15 + 1)),
        size.height * (0.5 + 0.2 * cos(t * 0.75 + 1)),
      ),
      size.width * 0.5,
    );

    // Floating glow orbs
    _drawOrb(canvas, size, const Color(0xFF7C4DFF), 0.08,
      Offset(
        size.width * (0.15 + 0.12 * sin(t * 0.7 + 0.3)),
        size.height * (0.3 + 0.1 * cos(t * 0.5 + 1.2)),
      ),
      size.width * 0.08,
    );

    _drawOrb(canvas, size, const Color(0xFF448AFF), 0.06,
      Offset(
        size.width * (0.85 + 0.1 * sin(t * 0.9 + 2.1)),
        size.height * (0.7 + 0.12 * cos(t * 0.6 + 0.8)),
      ),
      size.width * 0.06,
    );

    _drawOrb(canvas, size, const Color(0xFFE040FB), 0.05,
      Offset(
        size.width * (0.4 + 0.15 * sin(t * 0.55 + 4.2)),
        size.height * (0.15 + 0.1 * cos(t * 0.8 + 3.5)),
      ),
      size.width * 0.04,
    );

    _drawOrb(canvas, size, const Color(0xFF00BCD4), 0.05,
      Offset(
        size.width * (0.6 + 0.12 * sin(t * 0.75 + 1.8)),
        size.height * (0.85 + 0.08 * cos(t * 0.45 + 2.7)),
      ),
      size.width * 0.05,
    );
  }

  void _drawBlob(Canvas canvas, Size size, Color color, double opacity, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawOrb(Canvas canvas, Size size, Color color, double opacity, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
