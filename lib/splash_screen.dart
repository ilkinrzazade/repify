import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Animated launch screen: the logo pops in with a neon glow,
/// then the name slides up, then the app opens [next].
class SplashScreen extends StatefulWidget {
  final Widget next;

  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> logoScale = CurvedAnimation(
    parent: controller,
    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
  );
  late final Animation<double> logoTurn = CurvedAnimation(
    parent: controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
  );
  late final Animation<double> glow = CurvedAnimation(
    parent: controller,
    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> textIn = CurvedAnimation(
    parent: controller,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
  );
  late final Animation<double> taglineIn = CurvedAnimation(
    parent: controller,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );

  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller.forward();
    timer = Timer(const Duration(milliseconds: 2200), openApp);
  }

  void openApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => widget.next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Soft lime light behind the logo.
              Center(
                child: Opacity(
                  opacity: glow.value * 0.9,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.lime.withAlpha(70), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: (1 - logoTurn.value) * -math.pi / 4,
                      child: Transform.scale(
                        scale: 0.2 + 0.8 * logoScale.value,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lime.withAlpha((140 * glow.value).round()),
                                blurRadius: 40 * glow.value,
                                spreadRadius: 4 * glow.value,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 60,
                            color: AppColors.onLime,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: textIn.value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - textIn.value)),
                        child: const Text(
                          'Repify',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: taglineIn.value,
                      child: const Text(
                        'Track every rep. See your progress.',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
