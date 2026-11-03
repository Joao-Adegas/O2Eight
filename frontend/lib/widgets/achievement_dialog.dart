// lib/widgets/achievement_dialog.dart
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/achievement_service.dart';

enum AchievementAction { share, close }

/// Mostra a janela de conquista e devolve o que o usuário escolheu.
Future<AchievementAction> showAchievementDialog(
  BuildContext context, {
  required String firstName,
  required Achievement achievement,
  required double savedMoney,
}) async {
  final result = await showGeneralDialog<AchievementAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => _AchievementDialog(
      firstName: firstName,
      achievement: achievement,
      savedMoney: savedMoney,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
      );
    },
  );
  return result ?? AchievementAction.close;
}

class _AchievementDialog extends StatelessWidget {
  final String firstName;
  final Achievement achievement;
  final double savedMoney;

  const _AchievementDialog({
    required this.firstName,
    required this.achievement,
    required this.savedMoney,
  });

  static String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integer,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = firstName.isEmpty ? '' : ', $firstName';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: AppColors.navy900,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Medal(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Parabéns$name!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Você está há',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.onDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -1,
                        color: AppColors.teal500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const Text(
                    'sem fumar',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.onDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    achievement.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.onDark,
                    ),
                  ),
                  if (savedMoney >= 1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.onDark.withValues(alpha: 0.08),
                        borderRadius: AppRadius.pillShape,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.savings_outlined,
                              size: 16, color: AppColors.teal500),
                          const SizedBox(width: 6),
                          Text(
                            'Você já economizou ${_formatMoney(savedMoney)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(AchievementAction.close),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        foregroundColor: AppColors.navy900,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(AchievementAction.share),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onDarkSecondary,
                    ),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('Compartilhar na comunidade'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Medalha com anel turquesa que "acende" ao abrir.
class _Medal extends StatelessWidget {
  const _Medal();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.teal500.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.teal500.withValues(alpha: 0.3 + 0.7 * t),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal500.withValues(alpha: 0.35 * t),
                blurRadius: 36 * t,
                spreadRadius: 4 * t,
              ),
            ],
          ),
          child: Transform.scale(
            scale: 0.7 + 0.3 * t,
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppColors.teal500,
            ),
          ),
        );
      },
    );
  }
}