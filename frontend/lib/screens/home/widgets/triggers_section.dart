// lib/screens/home/widgets/triggers_section.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'recovery_timeline.dart' show HomeSectionHeader;

/// Um gatilho do usuário. `level` (0.0 a 1.0) fica nulo até existir a
/// análise das conversas e do dispositivo; nesse caso não mostramos nível.
class TriggerItem {
  final String name;
  final double? level;

  const TriggerItem({required this.name, this.level});
}

/// Seção "Seus gatilhos": momento de maior risco e lista de gatilhos.
/// Tocar em qualquer item abre a assistente com uma pergunta pronta.
class TriggersSection extends StatelessWidget {
  final List<TriggerItem> triggers;
  final String? riskTime; // "De manhã", "De tarde" ou "De noite"
  final ValueChanged<String> onAskAssistant;

  const TriggersSection({
    super.key,
    required this.triggers,
    required this.onAskAssistant,
    this.riskTime,
  });

  bool get _hasLevels => triggers.any((t) => t.level != null);

  List<TriggerItem> get _sorted {
    final list = [...triggers];
    if (_hasLevels) {
      list.sort((a, b) => (b.level ?? 0).compareTo(a.level ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'Seus gatilhos'),
        const SizedBox(height: 2),
        const Text(
          'Toque em um item para montar uma estratégia com a assistente',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (riskTime != null) ...[
          _RiskTimeCard(
            riskTime: riskTime!,
            onTap: () => onAskAssistant(
              'Costumo ter mais vontade de fumar ${riskTime!.toLowerCase()}. '
              'Me ajuda a montar uma estratégia para esse momento?',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (triggers.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _sorted.length; i++) ...[
                  if (i > 0) const Divider(indent: 60),
                  _TriggerRow(
                    trigger: _sorted[i],
                    onTap: () => onAskAssistant(
                      'Quero uma estratégia para quando a vontade vier '
                      'por causa de: ${_sorted[i].name}.',
                    ),
                  ),
                ],
                if (!_hasLevels) const _LevelsNotice(),
              ],
            ),
          ),
      ],
    );
  }
}

class _RiskTimeCard extends StatelessWidget {
  final String riskTime;
  final VoidCallback onTap;

  const _RiskTimeCard({required this.riskTime, required this.onTap});

  IconData get _icon => switch (riskTime) {
        'De manhã' => Icons.wb_twilight,
        'De tarde' => Icons.wb_sunny_outlined,
        _ => Icons.nightlight_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy900,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icon, size: 26, color: AppColors.teal500),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Momento de maior risco',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onDarkSecondary,
                        ),
                      ),
                      Text(
                        riskTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Text(
                    'Montar uma estratégia com a assistente',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.teal500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriggerRow extends StatelessWidget {
  final TriggerItem trigger;
  final VoidCallback onTap;

  const _TriggerRow({required this.trigger, required this.onTap});

  static IconData iconFor(String name) => switch (name) {
        'Ansiedade' => Icons.psychology_alt_outlined,
        'Estresse' => Icons.bolt_outlined,
        'Tédio' => Icons.hourglass_empty,
        'Tristeza' => Icons.sentiment_dissatisfied_outlined,
        'Depois do café' => Icons.coffee_outlined,
        'Após refeições' => Icons.restaurant_outlined,
        'Álcool' => Icons.local_bar_outlined,
        _ => Icons.flag_outlined,
      };

  static String levelLabel(double level) {
    if (level >= 0.66) return 'Alto';
    if (level >= 0.33) return 'Moderado';
    return 'Baixo';
  }

  @override
  Widget build(BuildContext context) {
    final level = trigger.level;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.navy50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconFor(trigger.name),
                      size: 18, color: AppColors.navy700),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    trigger.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (level != null)
                  Text(
                    levelLabel(level),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: level >= 0.66
                          ? AppColors.navy700
                          : AppColors.textSecondary,
                    ),
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
              ],
            ),
            if (level != null)
              Padding(
                padding: const EdgeInsets.only(left: 46, top: 8),
                child: ClipRRect(
                  borderRadius: AppRadius.pillShape,
                  child: LinearProgressIndicator(
                    value: level.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    color: AppColors.navy700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelsNotice extends StatelessWidget {
  const _LevelsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, size: 18, color: AppColors.textSecondary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'O nível de cada gatilho aparece conforme você conversa com a '
              'assistente e usa o dispositivo.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}