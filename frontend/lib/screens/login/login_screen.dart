import 'package:flutter/material.dart';

import '../../components/gradient_button.dart';
import '../../core/theme/app_theme.dart';
import '../../app/routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
    final cardColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundShapes(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [AppTheme.accentStart, AppTheme.accentEnd],
                    ).createShader(rect),
                    child: const Text(
                      'O2Eight',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sua jornada para respirar melhor comeca hoje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Bem-vindo(a)',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Entre com sua conta para salvar progresso, metas e planos personalizados.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _GoogleButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.form);
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ao continuar, voce concorda com os Termos de Uso e Politica de Privacidade.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 14),
                        GradientButton(
                          text: 'Explorar sem login',
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.home);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF08162B), Color(0xFF0B1F3A), Color(0xFF0D2B4A)]
              : const [Color(0xFFF5F8FC), Color(0xFFE7F0FA), Color(0xFFDCECF7)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowCircle(
              size: 260,
              color: AppTheme.accentEnd.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowCircle(
              size: 240,
              color: AppTheme.accentStart.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 220,
            left: 24,
            right: 24,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.accentStart.withValues(alpha: 0.18)),
                color: AppTheme.accentStart.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0x1AFFFFFF) : Colors.white,
        foregroundColor: isDark ? AppTheme.darkText : AppTheme.lightText,
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      onPressed: onPressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleMark(),
          SizedBox(width: 10),
          Text(
            'Continuar com Google',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}
