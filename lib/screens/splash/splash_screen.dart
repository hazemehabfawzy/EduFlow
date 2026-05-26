// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

/// Animated splash screen.
/// Waits at least 2.5 seconds, then routes to Home or Auth
/// depending on Firebase auth state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkAuth();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Let the animation play for at least 2.5 seconds
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      context.read<AuthProvider>().init(),
    ]);

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacementNamed(
      auth.isAuthenticated ? AppRoutes.home : AppRoutes.auth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            // Decorative circles
            _buildDecorativeCircles(),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing logo ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      return Container(
                        width: 120 + (_pulseController.value * 10),
                        height: 120 + (_pulseController.value * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(
                            0.08 + (_pulseController.value * 0.06),
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 24),

                  Text(
                    'SkillNest',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: -1,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  Text(
                    'Learn. Grow. Succeed.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 600.ms),

                  const SizedBox(height: 60),

                  // Loading dots
                  _LoadingDots()
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 900.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        Positioned(
          top: -60, left: -60,
          child: _GlowCircle(size: 200, color: AppColors.primary, opacity: 0.15),
        ),
        Positioned(
          bottom: -40, right: -60,
          child: _GlowCircle(size: 250, color: AppColors.accent, opacity: 0.12),
        ),
        Positioned(
          top: 200, right: -30,
          child: _GlowCircle(size: 140, color: AppColors.secondary, opacity: 0.1),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final offset = ((_ctrl.value - (i * 0.2)) % 1.0);
            final scale = offset < 0.5
                ? 1.0 + (offset * 0.8)
                : 1.4 - ((offset - 0.5) * 0.8);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.5 + (scale - 1) * 0.5),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
