// lib/screens/home/widgets/recovery_timeline.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Marco de recuperação (linha do tempo divulgada pelo INCA).
class RecoveryMilestone {
  final Duration at;
  final String label;
  final String benefit;

  const RecoveryMilestone(this.at, this.label, this.benefit);
}

const List<RecoveryMilestone> kRecoveryMilestones = [
  RecoveryMilestone(Duration(minutes: 20), '20 minutos',
      'Pressão sanguínea e pulsação voltam ao normal'),
  RecoveryMilestone(Duration(hours: 2), '2 horas',
      'Não há mais nicotina circulando no sangue'),
  RecoveryMilestone(Duration(hours: 8), '8 horas',
      'O nível de oxigênio no sangue se normaliza'),
  RecoveryMilestone(Duration(hours: 24), '24 horas',
      'Os pulmões passam a funcionar melhor'),
  RecoveryMilestone(Duration(days: 2), '2 dias',
      'Olfato e paladar melhoram'),
  RecoveryMilestone(Duration(days: 21), '3 semanas',
      'A respiração fica mais fácil e a circulação melhora'),
  RecoveryMilestone(Duration(days: 365), '1 ano',
      'O risco de morte por infarto cai pela metade'),
  RecoveryMilestone(Duration(days: 1825), '5 anos',
      'Entre 5 e 10 anos, o risco de infarto se iguala ao de quem nunca fumou'),
];

/// Seção "Recuperação do corpo": próximo marco com progresso e
/// marcos já conquistados. Calculado a partir da data sem fumar.
class RecoveryTimeline extends StatefulWidget {
  final DateTime cleanSince;

  const RecoveryTimeline({super.key, required this.cleanSince});

  @override
  State<RecoveryTimeline> createState() => _RecoveryTimelineState();
}

class _RecoveryTimelineState extends State<RecoveryTimeline> {
  bool _expanded = false;

  Duration get _elapsed {
    final d = DateTime.now().difference(widget.cleanSince);
    return d.isNegative ? Duration.zero : d;
  }

  /// "3 dias", "5 h", "12 min"
  static String _short(Duration d) {
    if (d.inDays >= 1) return d.inDays == 1 ? '1 dia' : '${d.inDays} dias';
    if (d.inHours >= 1) return '${d.inHours} h';
    return '${d.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _elapsed;
    final achieved =
        kRecoveryMilestones.where((m) => elapsed >= m.at).toList();
    final next = kRecoveryMilestones
        .cast<RecoveryMilestone?>()
        .firstWhere((m) => elapsed < m!.at, orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Recuperação do corpo',
          trailing: 'Fonte: INCA',
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (next != null)
                _NextMilestone(milestone: next, elapsed: elapsed)
              else
                const _AllCompleted(),
              if (achieved.isNotEmpty || _expanded) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                if (_expanded)
                  // Linha do tempo completa, em ordem
                  ...kRecoveryMilestones.map(
                    (m) => _MilestoneRow(
                      milestone: m,
                      state: elapsed >= m.at
                          ? _RowState.done
                          : (identical(m, next)
                              ? _RowState.next
                              : _RowState.future),
                    ),
                  )
                else
                  // Só as duas conquistas mais recentes
                  ...achieved.reversed.take(2).map(
                        (m) => _MilestoneRow(
                          milestone: m,
                          state: _RowState.done,
                        ),
                      ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: AppRadius.small,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      _expanded ? 'Mostrar menos' : 'Ver linha do tempo completa',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextMilestone extends StatelessWidget {
  final RecoveryMilestone milestone;
  final Duration elapsed;

  const _NextMilestone({required this.milestone, required this.elapsed});

  /// "falta 1 dia", "faltam 240 dias", "faltam 3 h"
  static String _remainingText(Duration remaining) {
    final text = _RecoveryTimelineState._short(remaining);
    return text.startsWith('1 ') ? 'falta $text' : 'faltam $text';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (elapsed.inSeconds / milestone.at.inSeconds).clamp(0.0, 1.0);
    final remaining = milestone.at - elapsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximo marco',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '${milestone.label} sem fumar',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          milestone.benefit,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppRadius.pillShape,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.navy700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${_RecoveryTimelineState._short(elapsed)} de ${milestone.label}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              _remainingText(remaining),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navy700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AllCompleted extends StatelessWidget {
  const _AllCompleted();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.verified_outlined, color: AppColors.teal700),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Você alcançou todos os marcos de recuperação. Uma trajetória e tanto.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

enum _RowState { done, next, future }

class _MilestoneRow extends StatelessWidget {
  final RecoveryMilestone milestone;
  final _RowState state;

  const _MilestoneRow({required this.milestone, required this.state});

  @override
  Widget build(BuildContext context) {
    final isFuture = state == _RowState.future;

    final Widget marker = switch (state) {
      _RowState.done => Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.teal50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 15, color: AppColors.teal700),
        ),
      _RowState.next => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.navy700, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.navy700,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      _RowState.future => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marker,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isFuture ? AppColors.textSecondary : AppColors.text,
                  ),
                ),
                Text(
                  milestone.benefit,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção da Home, com texto opcional à direita (usado também em triggers_section.dart).
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const HomeSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}