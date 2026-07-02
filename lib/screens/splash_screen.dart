import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/gradient_mesh_background.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _taglineController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _taglineController.forward();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0)
                      .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _logoController.dispose();
    _ringController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientMeshBackground(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _ringController]),
                  builder: (context, _) {
                    final t = _logoController.value;
                    final ringT = _ringController.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * t,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing ring
                            Container(
                              width: 120 + ringT * 20,
                              height: 120 + ringT * 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF7C4DFF).withOpacity(0.2 - ringT * 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Middle glow ring
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF).withOpacity(0.2 + ringT * 0.15),
                                    blurRadius: 30 + ringT * 20,
                                    spreadRadius: 5 + ringT * 5,
                                  ),
                                ],
                              ),
                            ),
                            // Logo circle
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF).withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, _) {
                    final t = _logoController.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - t)),
                        child: const Text(
                          'Nexus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _taglineController,
                  builder: (context, _) {
                    final t = _taglineController.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - t)),
                        child: Text(
                          'Intelligent Conversations',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF7C4DFF),
      const Color(0xFF448AFF),
      const Color(0xFFE040FB),
      const Color(0xFF00BCD4),
    ];

    for (int i = 0; i < 40; i++) {
      final seed = i * 137.5;
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withOpacity(0.15 + (seed % 10) / 10 * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final phase = (seed * 0.01) % (2 * pi);
      final x = ((seed + progress * 300 + 50 * sin(progress * 2 + phase)) % (size.width + 100)) - 50;
      final y = ((seed * 0.7 + progress * 200 + 40 * cos(progress * 1.5 + phase)) % (size.height + 100)) - 50;
      final radius = 1.5 + (seed % 10) / 10 * 2.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
