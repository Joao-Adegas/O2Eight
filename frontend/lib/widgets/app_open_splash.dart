// lib/widgets/app_open_splash.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Animação de abertura: o pulmão do logo "respira" algumas vezes e a tela
/// some com um fade, revelando o app.
///
/// Aparece:
/// - toda vez que o app é aberto do zero;
/// - quando o app volta para a frente depois de ficar [reopenAfter] em segundo plano.
///
/// Enquanto a animação roda, a tela de baixo (login ou Home) já está carregando.
class AppOpenSplash extends StatefulWidget {
  final Widget child;

  /// Tempo mínimo em segundo plano para a animação aparecer de novo
  final Duration reopenAfter;

  const AppOpenSplash({
    super.key,
    required this.child,
    this.reopenAfter = const Duration(minutes: 5),
  });

  @override
  State<AppOpenSplash> createState() => _AppOpenSplashState();
}

class _AppOpenSplashState extends State<AppOpenSplash> with WidgetsBindingObserver {
  bool _visible = true;
  bool _firstOpen = true;
  int _run = 0; // muda a cada exibição para reiniciar a animação
  DateTime? _backgroundSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundSince ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundSince;
      _backgroundSince = null;
      if (since != null &&
          DateTime.now().difference(since) >= widget.reopenAfter &&
          !_visible) {
        setState(() {
          _visible = true;
          _firstOpen = false;
          _run++;
        });
      }
    }
  }

  void _finish() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: _SplashView(
              key: ValueKey(_run),
              // Na primeira abertura respira 2 vezes; na volta, 1 vez e meia
              breaths: _firstOpen ? 2 : 1.5,
              onFinished: _finish,
            ),
          ),
      ],
    );
  }
}

class _SplashView extends StatefulWidget {
  final double breaths;
  final VoidCallback onFinished;

  const _SplashView({super.key, required this.breaths, required this.onFinished});

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> with TickerProviderStateMixin {
  static const _breathMs = 1600; // uma inspiração + expiração
  static const _fadeMs = 380;

  late final AnimationController _breath;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_breathMs * widget.breaths).round()),
    );
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _fadeMs),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } else {
      await _breath.forward();
    }
    if (!mounted) return;
    await _fade.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _breath.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: AppColors.surface,
        child: Center(
          child: AnimatedBuilder(
            animation: _breath,
            builder: (context, _) {
              // Fase dentro da respiração atual: 0 = expirado, 1 = inspirado
              final cycles = _breath.value * widget.breaths;
              final phase = cycles - cycles.floorToDouble();
              final b = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
              // Texto aparece aos poucos no começo
              final textIn = Curves.easeOut.transform((_breath.value * 2.2).clamp(0.0, 1.0));

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Onda que se espalha a cada inspiração
                        _Ripple(phase: phase),
                        // Halo que acompanha a respiração
                        Container(
                          width: 150 + 18 * b,
                          height: 150 + 18 * b,
                          decoration: BoxDecoration(
                            color: AppColors.teal50,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal500.withValues(alpha: 0.10 + 0.25 * b),
                                blurRadius: 20 + 28 * b,
                                spreadRadius: 2 + 6 * b,
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 1 + 0.10 * b,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 104,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Opacity(
                    opacity: textIn,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - textIn)),
                      child: const Column(
                        children: [
                          Text(
                            'O₂Eight',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Respire. Um dia de cada vez.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Anel fino que cresce e some durante a inspiração.
class _Ripple extends StatelessWidget {
  final double phase;

  const _Ripple({required this.phase});

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(phase);
    return Container(
      width: 150 + 90 * t,
      height: 150 + 90 * t,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.45 * (1 - t)),
          width: 2,
        ),
      ),
    );
  }
}
