// lib/screens/home/widgets/risk_alert_banner.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/progress_service.dart';

/// Aviso na Home quando o horário de risco previsto está perto (até 60 min
/// antes) ou já começou. Busca os insights sozinho; se não houver alerta
/// ativo ou a chamada falhar, não ocupa espaço.
class RiskAlertBanner extends StatefulWidget {
  final VoidCallback onOpenInsights;

  const RiskAlertBanner({super.key, required this.onOpenInsights});

  @override
  State<RiskAlertBanner> createState() => _RiskAlertBannerState();
}

class _RiskAlertBannerState extends State<RiskAlertBanner> {
  Map<String, dynamic>? _alert;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ProgressService().getInsights(days: 30);
      final alert = (data['next_alert'] as Map?)?.cast<String, dynamic>();
      if (!mounted) return;
      setState(() => _alert = alert != null && alert['active'] == true ? alert : null);
    } catch (e) {
      debugPrint('Aviso de risco indisponível: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    if (alert == null) return const SizedBox.shrink();

    final inWindow = alert['in_window'] == true;
    final minutes = (alert['minutes_until'] as num?)?.toInt() ?? 0;
    final start = (alert['start_hour'] as num?)?.toInt() ?? 0;
    final end = (alert['end_hour'] as num?)?.toInt() ?? 0;
    String hh(int h) => '${h.toString().padLeft(2, '0')}h';

    final title = inWindow
        ? 'Você está no seu horário de risco'
        : 'Horário de risco em $minutes min';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Material(
        color: AppColors.statusStabilizing.withValues(alpha: 0.18),
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: widget.onOpenInsights,
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.navy900),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Costuma bater das ${hh(start)} às ${hh(end)}. '
                        'Se a vontade vier, toque em "Estou com vontade".',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
