import 'package:first_try/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Animated splash. The brand gradient sits behind a glowing monogram badge,
/// the badge gently breathes via a repeating animation, and the title fades
/// up on first paint. Visible while [AuthCubit.hydrate] runs (~600ms typical),
/// then go_router redirects.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: Motion.epic)
      ..forward();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _glow]),
        builder: (context, _) {
          final introT = Curves.easeOutCubic.transform(_intro.value);
          final glowT = _glow.value;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Soft glow halo behind the badge.
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 320 + (glowT * 24),
                      height: 320 + (glowT * 24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Colors.white.withValues(alpha: 0.10 + glowT * 0.05),
                      ),
                    ),
                  ),
                ),
                // Logo + name (fades in from below).
                Center(
                  child: Opacity(
                    opacity: introT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - introT) * 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoBadge(glow: glowT),
                          const SizedBox(height: 24),
                          Text(
                            'School App',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Learn. Connect. Thrive.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Slim progress bar at the bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Center(
                    child: SizedBox(
                      width: 96,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: Radii.pillRadius,
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final double glow;
  const _LogoBadge({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Radii.xlRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35 + glow * 0.25),
            blurRadius: 40 + glow * 20,
            spreadRadius: 4 + glow * 4,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          colors: context.palette.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
        child: const Icon(
          Icons.school_rounded,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }
}
