import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/shine_logo.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final AnimationController _shimmerController;
  late final AnimationController _floatController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _footerOpacity;

  bool _navigated = false;

  static const _splashDuration = Duration(milliseconds: 5200);

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    // Floor at 0.15 so logo never fully disappears if frames skip.
    _logoOpacity = Tween<double>(begin: 0.15, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.15, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );
    _footerOpacity = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    while (ref.read(authProvider).isLoading && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.hasError) {
      context.go(AppRoutes.login);
      return;
    }

    final session = auth.valueOrNull;
    if (session != null) {
      context.go(
        session.user.role == UserRole.superAdmin
            ? AppRoutes.admin
            : AppRoutes.executive,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: _goNext,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFBF2),
                Color(0xFFFFF0C8),
                Color(0xFFE4F7EC),
                Color(0xFFD8F0E4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient drifting blobs
              AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController,
                  _orbitController,
                ]),
                builder: (context, _) {
                  final t = _floatController.value;
                  final o = _orbitController.value * 2 * math.pi;
                  return Stack(
                    children: [
                      Positioned(
                        top: -60 + t * 24,
                        right: -40 + math.sin(o) * 18,
                        child: _SoftBlob(
                          size: size.width * 0.55,
                          color: AppColors.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      Positioned(
                        bottom: -80 - t * 20,
                        left: -50 + math.cos(o) * 16,
                        child: _SoftBlob(
                          size: size.width * 0.6,
                          color: AppColors.secondary.withValues(alpha: 0.18),
                        ),
                      ),
                      Positioned(
                        top: size.height * 0.38,
                        left: -30 + math.sin(o * 1.3) * 28,
                        child: _SoftBlob(
                          size: 140,
                          color: AppColors.primaryBright
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Floating grain particles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ParticleFieldPainter(
                        progress: _orbitController.value,
                      ),
                    );
                  },
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo stage
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _pulseController,
                        _orbitController,
                        _floatController,
                      ]),
                      builder: (context, _) {
                        final pulse = _pulseController.value;
                        final floatY = (_floatController.value - 0.5) * 10;
                        final scale =
                            (0.88 + _logoScale.value * 0.12) *
                            (1.0 + pulse * 0.035);

                        return Transform.translate(
                          offset: Offset(0, floatY),
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: scale,
                              child: SizedBox(
                                width: 300,
                                height: 300,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer ring
                                    CustomPaint(
                                      size: const Size(300, 300),
                                      painter: _OrbitRingPainter(
                                        rotation:
                                            _orbitController.value * 2 * math.pi,
                                        pulse: pulse,
                                      ),
                                    ),
                                    // Sun rays
                                    CustomPaint(
                                      size: const Size(280, 280),
                                      painter: _SunRaysPainter(
                                        rotation: _orbitController.value *
                                            2 *
                                            math.pi,
                                        intensity: 0.55 + pulse * 0.45,
                                      ),
                                    ),
                                    // Glow halo
                                    Container(
                                      width: 190 + pulse * 18,
                                      height: 190 + pulse * 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(
                                              alpha: 0.28 + pulse * 0.22,
                                            ),
                                            blurRadius: 42 + pulse * 20,
                                            spreadRadius: 6 + pulse * 6,
                                          ),
                                          BoxShadow(
                                            color: AppColors.secondary
                                                .withValues(
                                              alpha: 0.16 + pulse * 0.14,
                                            ),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const ShineLogo(size: 168),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Brand name with shimmer sweep
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _shimmerController,
                      ]),
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: Column(
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    final t = _shimmerController.value;
                                    return LinearGradient(
                                      begin: Alignment(-1.2 + t * 2.4, 0),
                                      end: Alignment(-0.2 + t * 2.4, 0),
                                      colors: const [
                                        AppColors.primaryDark,
                                        AppColors.primaryBright,
                                        AppColors.secondary,
                                        AppColors.primaryDark,
                                      ],
                                      stops: const [0.0, 0.35, 0.55, 1.0],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'SHINE GOLD',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3.5,
                                          fontSize: 32,
                                          height: 1.1,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: 56 + _titleOpacity.value * 28,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _taglineOpacity.value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxxl,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'ORGANIC AGRO INVENTION',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: AppColors.primaryDark,
                                        letterSpacing: 2.4,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Field intelligence for a greener harvest',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Footer progress + hint
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _progressController,
                        _pulseController,
                      ]),
                      builder: (context, _) {
                        final pulse = _pulseController.value;
                        return Opacity(
                          opacity: _footerOpacity.value,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xxxl,
                              0,
                              AppSpacing.xxxl,
                              AppSpacing.xxl,
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    children: [
                                      LinearProgressIndicator(
                                        value: _progressController.value,
                                        minHeight: 5,
                                        backgroundColor: AppColors.primarySoft
                                            .withValues(alpha: 0.55),
                                        color: AppColors.primary,
                                      ),
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment(
                                            -1 +
                                                _progressController.value * 2,
                                            0,
                                          ),
                                          child: Container(
                                            width: 28,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.55,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Opacity(
                                  opacity: 0.55 + pulse * 0.45,
                                  child: Text(
                                    'Tap anywhere to continue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter({required this.rotation, required this.intensity});

  final double rotation;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    const rayCount = 16;

    for (var i = 0; i < rayCount; i++) {
      final angle = rotation + (i * 2 * math.pi / rayCount);
      final long = i.isEven;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primaryBright.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.22 * intensity),
            AppColors.secondary.withValues(alpha: 0.28 * intensity),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = long ? 3.5 : 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final inner = radius * 0.52;
      final outer = radius * (long ? 0.98 : 0.82);
      canvas.drawLine(
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) =>
      old.rotation != rotation || old.intensity != intensity;
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.rotation, required this.pulse});

  final double rotation;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42 + pulse * 4;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.primary.withValues(alpha: 0.22 + pulse * 0.15);
    canvas.drawCircle(center, radius, ring);

    final ring2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.secondary.withValues(alpha: 0.14 + pulse * 0.1);
    canvas.drawCircle(center, radius * 0.78, ring2);

    // Orbiting dots
    for (var i = 0; i < 5; i++) {
      final angle = rotation * (i.isEven ? 1 : -1) + i * 1.25;
      final r = i.isEven ? radius : radius * 0.78;
      final pos = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      final dot = Paint()
        ..color = (i % 3 == 0 ? AppColors.primary : AppColors.secondary)
            .withValues(alpha: 0.75);
      canvas.drawCircle(pos, i.isEven ? 4.2 : 3.2, dot);
      canvas.drawCircle(
        pos,
        i.isEven ? 8 : 6,
        Paint()
          ..color = (i % 3 == 0 ? AppColors.primary : AppColors.secondary)
              .withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) =>
      old.rotation != rotation || old.pulse != pulse;
}

class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({required this.progress});

  final double progress;

  // Fixed particle seeds — recomputed every frame from index, not Random.
  static const _count = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return;

    for (var i = 0; i < _count; i++) {
      // Hash-ish deterministic values from index (stable across frames).
      final bx = ((i * 73) % 100) / 100.0;
      final by = ((i * 47 + 19) % 100) / 100.0;
      final speed = 0.35 + ((i * 17) % 65) / 100.0;
      final phase = ((i * 31) % 100) / 100.0;
      final radius = 1.2 + ((i * 11) % 25) / 10.0;
      final drift = math.sin((progress + phase) * 2 * math.pi * speed);

      var x = (bx * size.width + drift * 18) % size.width;
      if (x < 0) x += size.width;
      var y = (by * size.height - progress * size.height * speed * 0.35) %
          size.height;
      if (y < 0) y += size.height;

      if (!x.isFinite || !y.isFinite) continue;

      final isGold = i % 3 != 0;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = (isGold ? AppColors.primary : AppColors.secondary)
              .withValues(alpha: 0.18 + (drift.abs() * 0.22)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter old) =>
      old.progress != progress;
}
