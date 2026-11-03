// lib/screens/insights/insights_screen.dart
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/progress_service.dart';
import '../home/widgets/recovery_timeline.dart' show HomeSectionHeader;
import '../sos/sos_screen.dart';

/// Insights: quando a pessoa sente vontade, quando fuma, gatilhos e o
/// próximo horário de risco previsto a partir do histórico.
///
/// Argumento opcional da rota: List<String> com as motivações do formulário
/// (repassadas para a tela "Estou com vontade").
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

/// Cores das três séries dos gráficos (fixas para a legenda bater).
class _Series {
  static const overcome = AppColors.teal700;
  static const smoked = AppColors.statusRecent;
  static const device = AppColors.navy700;
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _progressService = ProgressService();

  static const _periodOptions = [7, 30, 90];

  int _days = 30;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<String> _motivations = const [];
  bool _readArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArgs) return;
    _readArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List) _motivations = args.map((e) => e.toString()).toList();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _progressService.getInsights(days: _days);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ERRO ao carregar insights: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar seus insights.';
        _isLoading = false;
      });
    }
  }

  void _changePeriod(int days) {
    if (days == _days) return;
    _days = days;
    _load();
  }

  void _openSos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SosScreen(motivations: _motivations)),
    );
  }

  void _askStrategy(String windowLabel) {
    Navigator.of(context).pushNamed(
      AppRoutes.chat,
      arguments: 'Meu horário de maior vontade de fumar costuma ser $windowLabel. '
          'Me ajude a montar um plano para atravessar esse horário sem fumar.',
    );
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final totals = (data['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    final moments = (totals['moments'] as num?)?.toInt() ?? 0;
    final hasEnough = data['has_enough_data'] == true;
    final minEvents = (data['min_events_for_patterns'] as num?)?.toInt() ?? 5;
    final nextAlert = (data['next_alert'] as Map?)?.cast<String, dynamic>();
    final windows = _maps(data['risk_windows']);
    final triggers = ((data['triggers'] as List?) ?? const []).map((e) => e.toString()).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PeriodSelector(
                    options: _periodOptions,
                    selected: _days,
                    onSelected: _changePeriod,
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (nextAlert != null) ...[
                    _NextAlertCard(
                      alert: nextAlert,
                      onAskStrategy: _askStrategy,
                      onSos: _openSos,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _StatsRow(totals: totals),
                  const SizedBox(height: AppSpacing.xxl),
                  if (moments == 0)
                    const _EmptyState()
                  else ...[
                    if (!hasEnough) ...[
                      _InfoNote(
                        'Com $moments de $minEvents registros ainda não dá para '
                        'prever seus horários de risco. Por enquanto, o alerta usa '
                        'o período que você informou no formulário.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const HomeSectionHeader(title: 'Ao longo do dia'),
                    const SizedBox(height: AppSpacing.md),
                    _HourChart(
                      byHour: _maps(data['by_hour']),
                      riskWindows: windows.where((w) => w['source'] == 'history').toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const HomeSectionHeader(title: 'Por período'),
                    const SizedBox(height: AppSpacing.md),
                    _PeriodBars(byPeriod: _maps(data['by_period'])),
                    const SizedBox(height: AppSpacing.xxl),
                    const HomeSectionHeader(title: 'Por dia da semana'),
                    const SizedBox(height: AppSpacing.md),
                    _WeekdayChart(byWeekday: _maps(data['by_weekday'])),
                  ],
                  if (triggers.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const HomeSectionHeader(title: 'Seus gatilhos'),
                    const SizedBox(height: AppSpacing.md),
                    _TriggerChips(triggers: triggers),
                  ],
                  if (moments > 0) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const HomeSectionHeader(title: 'Histórico recente'),
                    const SizedBox(height: AppSpacing.md),
                    _RecentList(items: _maps(data['recent'])),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Utilitários ─────────────────────────

List<Map<String, dynamic>> _maps(dynamic value) =>
    ((value as List?) ?? const []).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

String _hourLabel(int h) => '${h.toString().padLeft(2, '0')}h';

String windowLabel(Map<String, dynamic> w) =>
    'das ${_hourLabel(_int(w['start_hour']))} às ${_hourLabel(_int(w['end_hour']))}';

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

const _weekdayNames = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String _formatWhen(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = today.difference(day).inDays;
  final time = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return 'Hoje, $time';
  if (diff == 1) return 'Ontem, $time';
  final date = '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}';
  return '${_weekdayNames[at.weekday - 1]}, $date, $time';
}

// ───────────────────────── Componentes ─────────────────────────

class _PeriodSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelected;

  const _PeriodSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final d in options)
          ChoiceChip(
            label: Text('$d dias'),
            selected: d == selected,
            onSelected: (_) => onSelected(d),
            selectedColor: AppColors.navy700,
            backgroundColor: AppColors.surface,
            side: BorderSide(color: d == selected ? AppColors.navy700 : AppColors.border),
            labelStyle: TextStyle(
              color: d == selected ? AppColors.onDark : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _NextAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final ValueChanged<String> onAskStrategy;
  final VoidCallback onSos;

  const _NextAlertCard({
    required this.alert,
    required this.onAskStrategy,
    required this.onSos,
  });

  @override
  Widget build(BuildContext context) {
    final inWindow = alert['in_window'] == true;
    final active = alert['active'] == true;
    final minutes = _int(alert['minutes_until']);
    final label = windowLabel(alert);
    final fromForm = alert['source'] == 'form';

    final String headline;
    if (inWindow) {
      headline = 'Você está no seu horário de risco agora';
    } else if (active) {
      headline = 'Seu horário de risco começa em ${_formatMinutes(minutes)}';
    } else {
      headline = 'Próximo horário de risco em ${_formatMinutes(minutes)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.notifications_active_outlined : Icons.schedule,
                color: active ? AppColors.statusStabilizing : AppColors.teal500,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                fromForm ? 'Previsto pelo seu formulário' : 'Previsto pelo seu histórico',
                style: const TextStyle(color: AppColors.onDarkSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            headline,
            style: const TextStyle(
              color: AppColors.onDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Costuma bater $label. Planeje algo para esse horário: '
            'água, uma caminhada curta ou falar com alguém.',
            style: const TextStyle(color: AppColors.onDarkSecondary, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: onSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: AppColors.navy900,
                ),
                icon: const Icon(Icons.air, size: 18),
                label: const Text('Estou com vontade'),
              ),
              OutlinedButton.icon(
                onPressed: () => onAskStrategy(label),
                style: OutlinedButton.styleFrom(
                  // O tema pinta OutlinedButton de branco; aqui o fundo é escuro
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.onDark,
                  side: const BorderSide(color: AppColors.onDarkSecondary),
                ),
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Montar um plano'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> totals;

  const _StatsRow({required this.totals});

  @override
  Widget build(BuildContext context) {
    final rate = totals['success_rate'] as num?;
    final smoked = _int(totals['smoked']) + _int(totals['device']);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.9,
      children: [
        _StatTile(label: 'Momentos de vontade', value: '${_int(totals['moments'])}'),
        _StatTile(
          label: 'Vontades vencidas',
          value: '${_int(totals['overcome'])}',
          color: _Series.overcome,
        ),
        _StatTile(label: 'Vezes que fumou', value: '$smoked', color: _Series.smoked),
        _StatTile(
          label: 'Taxa de sucesso',
          value: rate == null ? '–' : '${(rate * 100).round()}%',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, this.color = AppColors.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.navy50, borderRadius: AppRadius.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.navy700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, size: 40, color: AppColors.navy700),
          SizedBox(height: AppSpacing.md),
          Text(
            'Ainda não há registros neste período',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Toque em "Estou com vontade" sempre que sentir vontade de fumar, '
            'ou use o dispositivo O₂Eight. Com alguns registros, mostramos seus '
            'horários de risco e avisamos antes deles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(t, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        );
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        item(_Series.overcome, 'Venceu'),
        item(_Series.smoked, 'Fumou'),
        item(_Series.device, 'Dispositivo'),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Barras empilhadas por hora (0h a 23h). Horas de risco ganham fundo destacado.
class _HourChart extends StatelessWidget {
  final List<Map<String, dynamic>> byHour;
  final List<Map<String, dynamic>> riskWindows;

  const _HourChart({required this.byHour, required this.riskWindows});

  bool _isRisk(int hour) {
    for (final w in riskWindows) {
      final start = _int(w['start_hour']);
      final end = _int(w['end_hour']);
      final len = (end - start) % 24 == 0 ? 24 : (end - start) % 24;
      if ((hour - start) % 24 < len) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const chartHeight = 140.0;
    var maxTotal = 1;
    for (final b in byHour) {
      final t = _int(b['overcome']) + _int(b['smoked']) + _int(b['device']);
      if (t > maxTotal) maxTotal = t;
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in byHour)
                  Expanded(
                    child: Tooltip(
                      message: '${_hourLabel(_int(b['hour']))}: '
                          '${_int(b['overcome'])} venceu, '
                          '${_int(b['smoked'])} fumou, '
                          '${_int(b['device'])} dispositivo',
                      child: Container(
                        height: chartHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _isRisk(_int(b['hour']))
                              ? AppColors.statusStabilizing.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: _StackedBar(
                          segments: [
                            (_int(b['device']), _Series.device),
                            (_int(b['smoked']), _Series.smoked),
                            (_int(b['overcome']), _Series.overcome),
                          ],
                          maxValue: maxTotal,
                          maxHeight: chartHeight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final h in const [0, 6, 12, 18, 23])
                Expanded(
                  child: Text(
                    _hourLabel(h),
                    textAlign: h == 0
                        ? TextAlign.start
                        : (h == 23 ? TextAlign.end : TextAlign.center),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _Legend(),
          if (riskWindows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.statusStabilizing.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Horários de risco: ${riskWindows.map(windowLabel).join(', ')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  /// (valor, cor), de baixo para cima.
  final List<(int, Color)> segments;
  final int maxValue;
  final double maxHeight;

  const _StackedBar({
    required this.segments,
    required this.maxValue,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.$1 > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in visible.reversed)
            Container(height: maxHeight * s.$1 / maxValue, color: s.$2),
        ],
      ),
    );
  }
}

/// Barras horizontais: madrugada, manhã, tarde, noite.
class _PeriodBars extends StatelessWidget {
  final List<Map<String, dynamic>> byPeriod;

  const _PeriodBars({required this.byPeriod});

  @override
  Widget build(BuildContext context) {
    var maxCount = 1;
    for (final p in byPeriod) {
      if (_int(p['count']) > maxCount) maxCount = _int(p['count']);
    }
    return _Card(
      child: Column(
        children: [
          for (final p in byPeriod)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['label']}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                        Text(
                          '${p['range']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final count = _int(p['count']);
                        final smoked = _int(p['smoked']);
                        final full = constraints.maxWidth;
                        return Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.navy50,
                                borderRadius: AppRadius.pillShape,
                              ),
                            ),
                            ClipRRect(
                              borderRadius: AppRadius.pillShape,
                              child: Row(
                                children: [
                                  Container(
                                    height: 14,
                                    width: full * (count - smoked) / maxCount,
                                    color: _Series.overcome,
                                  ),
                                  Container(
                                    height: 14,
                                    width: full * smoked / maxCount,
                                    color: _Series.smoked,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_int(p['count'])}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Verde: venceu a vontade. Coral: fumou (app ou dispositivo).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colunas por dia da semana.
class _WeekdayChart extends StatelessWidget {
  final List<Map<String, dynamic>> byWeekday;

  const _WeekdayChart({required this.byWeekday});

  @override
  Widget build(BuildContext context) {
    const chartHeight = 100.0;
    var maxCount = 1;
    for (final d in byWeekday) {
      if (_int(d['count']) > maxCount) maxCount = _int(d['count']);
    }
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in byWeekday)
            Expanded(
              child: Column(
                children: [
                  Text(
                    _int(d['count']) == 0 ? '' : '${_int(d['count'])}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        child: _StackedBar(
                          segments: [
                            (_int(d['smoked']), _Series.smoked),
                            (_int(d['count']) - _int(d['smoked']), _Series.overcome),
                          ],
                          maxValue: maxCount,
                          maxHeight: chartHeight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${d['label']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TriggerChips extends StatelessWidget {
  final List<String> triggers;

  const _TriggerChips({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in triggers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: AppRadius.pillShape,
            ),
            child: Text(
              t,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal700),
            ),
          ),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _RecentList({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _RecentTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final kind = '${item['kind']}';
    final at = DateTime.tryParse('${item['at']}')?.toLocal();
    final duration = _int(item['duration_seconds']);
    final puffs = item['puffs'] as num?;

    final (IconData icon, Color color, String title) = switch (kind) {
      'overcome' => (Icons.check_circle_outline, _Series.overcome, 'Venceu a vontade'),
      'smoked' => (Icons.smoking_rooms_outlined, _Series.smoked, 'Fumou'),
      'device' => (Icons.sensors, _Series.device, 'Uso do dispositivo'),
      _ => (Icons.remove_circle_outline, AppColors.textSecondary, 'Saiu antes de concluir'),
    };

    final details = <String>[
      if (duration > 0) _formatMinutes((duration / 60).ceil()),
      if (puffs != null && puffs > 0) '${puffs.toInt()} puxadas',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                if (details.isNotEmpty)
                  Text(details.join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (at != null)
            Text(_formatWhen(at),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
