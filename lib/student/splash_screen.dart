import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import '../widgets/auth_gate.dart';

class StudentSplashScreen extends StatefulWidget {
  final String? studentRegNo;
  const StudentSplashScreen({super.key, this.studentRegNo});

  @override
  State<StudentSplashScreen> createState() => _StudentSplashScreenState();
}

class _StudentSplashScreenState extends State<StudentSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _tiltController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _tiltAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Minimalist Background Texture
          Positioned.fill(child: CustomPaint(painter: SubtleGridPainter())),

          // Main Content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _tiltController]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Animated Logo
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(
                              3,
                              2,
                              0.001,
                            ) // Lower perspective for subtle feel
                            ..rotateX(_tiltAnimation.value)
                            ..rotateY(_tiltAnimation.value * 1.5),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(35),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                // Premium Soft Shadow
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 50,
                                  spreadRadius: 5,
                                  offset: Offset(
                                    0,
                                    25 + _tiltAnimation.value * 30,
                                  ),
                                ),
                                // Inner glow/reflection
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 2,
                                  spreadRadius: -1,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Image.asset(
                              'assets/edlab.png',
                              height: 150,
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        // Soft Loading Indicator
                        SizedBox(
                          width: 40,
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.03)
      ..strokeWidth = 1;

    const double spacing = 40;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
