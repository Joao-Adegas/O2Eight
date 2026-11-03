// lib/screens/sos/relapse_screen.dart
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';

/// Tela exibida depois que o usuário registra que fumou
/// (pelo botão de vontade e, futuramente, pelo dispositivo ESP32).
/// O objetivo é acolher, não culpar: a forma como o app reage a uma
/// recaída influencia se a pessoa tenta de novo.
class RelapseScreen extends StatelessWidget {
  /// Dias sem fumar antes desta recaída
  final int previousCleanDays;

  const RelapseScreen({super.key, required this.previousCleanDays});

  String get _streakMessage {
    if (previousCleanDays >= 2) {
      return 'Você ficou $previousCleanDays dias sem fumar. Esse tempo mostrou '
          'que você consegue, e ele não se perde.';
    }
    if (previousCleanDays == 1) {
      return 'Você ficou 1 dia inteiro sem fumar. Isso mostrou que você '
          'consegue, e não se perde.';
    }
    return 'Você está tentando, e isso já é um passo importante.';
  }

  void _restart(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _talkToAssistant(BuildContext context) {
    final days = previousCleanDays > 0
        ? ' depois de $previousCleanDays ${previousCleanDays == 1 ? 'dia' : 'dias'} sem fumar'
        : '';
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.chat,
      arguments: 'Acabei de fumar$days. Me ajuda a entender o que '
          'aconteceu e a recomeçar?',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.teal500.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.favorite_outline,
                      size: 40,
                      color: AppColors.teal500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Tudo bem. Recomeçar faz parte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _streakMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'A maioria das pessoas precisa de algumas tentativas até '
                    'parar de vez. Cada uma ensina algo sobre os seus gatilhos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.onDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _restart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        foregroundColor: AppColors.navy900,
                      ),
                      child: const Text('Recomeçar agora'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => _talkToAssistant(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onDarkSecondary,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Entender o que aconteceu com a assistente'),
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