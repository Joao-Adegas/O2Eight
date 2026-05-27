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
          Column(
            children: [
              Text("Teste")
            ],
          )
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
              ? const [Color(0xFF3CCCB4), Color(0xFF0F5A8F)]
              : const [Color(0xFF3CCCB4), Color(0xFF0F5A8F)],
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
