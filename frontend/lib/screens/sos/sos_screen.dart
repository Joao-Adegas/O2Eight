// lib/screens/sos/sos_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/progress_service.dart';
import 'relapse_screen.dart';

enum _Phase { breathing, checkIn, victory }

/// Momento de vontade: respiração guiada por alguns minutos,
/// depois "como está a vontade agora?".
class SosScreen extends StatefulWidget {
  /// Motivos que o usuário marcou no formulário (ex: ["Família", "Saúde"])
  final List<String> motivations;

  const SosScreen({super.key, this.motivations = const []});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final _progressService = ProgressService();

  // Ritmo da respiração: inspira 4 s, segura 2 s, solta 6 s (ciclo de 12 s)
  static const _inhale = 4.0, _hold = 2.0, _exhale = 6.0;
  static const _cycle = _inhale + _hold + _exhale;

  static const _firstSession = 180; // 3 minutos
  static const _extraSession = 120; // "mais um pouco": +2 minutos

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_cycle * 1000).round()),
  )..repeat();

  final DateTime _startedAt = DateTime.now();
  Timer? _ticker;
  int _elapsed = 0;
  int _sessionSeconds = _firstSession;

  _Phase _phase = _Phase.breathing;
  bool _recorded = false; // evita registrar o mesmo momento duas vezes
  bool _isSaving = false;
  int? _overcomeTotal;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breath.dispose();
    super.dispose();
  }

  // ───────────────────────── Lógica ─────────────────────────

  void _tick() {
    if (!mounted || _phase != _Phase.breathing) return;
    setState(() => _elapsed++);
    if (_elapsed >= _sessionSeconds) {
      _breath.stop();
      setState(() => _phase = _Phase.checkIn);
    }
  }

  int get _durationSeconds => DateTime.now().difference(_startedAt).inSeconds;

  Future<Map<String, dynamic>?> _record(String outcome) async {
    if (_recorded) return null;
    _recorded = true;
    try {
      return await _progressService.recordCraving(
        outcome: outcome,
        startedAt: _startedAt,
        durationSeconds: _durationSeconds,
      );
    } catch (e) {
      debugPrint('ERRO ao registrar vontade: $e');
      return null;
    }
  }

  void _moreTime() {
    setState(() {
      _sessionSeconds += _extraSession;
      _phase = _Phase.breathing;
    });
    _breath.repeat();
  }

  Future<void> _overcome() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    _breath.stop();
    final result = await _record('overcome');
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _overcomeTotal = (result?['overcome_total'] as num?)?.toInt();
      _phase = _Phase.victory;
    });
  }

  Future<void> _smoked() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar que você fumou?'),
        content: const Text(
          'O contador de dias sem fumar vai recomeçar a partir de agora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final result = await _record('smoked');
    if (!mounted) return;

    if (result == null) {
      setState(() => _isSaving = false);
      _recorded = false; // permite tentar de novo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível registrar agora.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RelapseScreen(
          previousCleanDays:
              (result['previous_clean_days'] as num?)?.toInt() ?? 0,
        ),
      ),
    );
  }

  Future<void> _talkToAssistant() async {
    await _record('abandoned');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.chat,
      arguments: 'Fiz o exercício de respiração, mas ainda estou com muita '
          'vontade de fumar. Me ajuda?',
    );
  }

  Future<void> _close() async {
    if (_phase != _Phase.victory) {
      _record('abandoned'); // não precisa esperar
    }
    Navigator.of(context).pop();
  }

  // ───────────────────────── Textos ─────────────────────────

  String get _motivationText {
    final m = widget.motivations;
    if (m.isEmpty) return '';
    if (m.length == 1) return m.first;
    return '${m.sublist(0, m.length - 1).join(', ')} e ${m.last}';
  }

  List<String> get _supportMessages => [
        'A vontade costuma passar em poucos minutos. Fique aqui comigo.',
        if (widget.motivations.isNotEmpty)
          'Lembre por que você decidiu parar: $_motivationText.',
        'Você não precisa decidir nada agora. Só acompanhe a respiração.',
        'Depois do exercício, beba um copo de água e mude de ambiente.',
        'Com o tempo, as vontades ficam mais fracas e mais raras.',
      ];

  /// Troca a frase de apoio a cada ciclo de respiração
  String get _currentMessage {
    final messages = _supportMessages;
    return messages[(_elapsed ~/ _cycle) % messages.length];
  }

  String get _remainingText {
    final left = (_sessionSeconds - _elapsed).clamp(0, _sessionSeconds);
    final m = left ~/ 60, s = left % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (_phase) {
      _Phase.breathing => _buildBreathing(),
      _Phase.checkIn => _buildCheckIn(),
      _Phase.victory => _buildVictory(),
    };

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: AppColors.navy900,
        foregroundColor: AppColors.onDark,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : _close,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey(_phase), child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vamos atravessar essa vontade juntos',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(child: _BreathingCircle(animation: _breath)),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 52,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _currentMessage,
              key: ValueKey(_currentMessage),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.onDarkSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: SizedBox(
            width: 200,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.pillShape,
                  child: LinearProgressIndicator(
                    value: _elapsed / _sessionSeconds,
                    minHeight: 4,
                    backgroundColor: AppColors.onDark.withValues(alpha: 0.12),
                    color: AppColors.teal500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Faltam $_remainingText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onDarkSecondary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: _isSaving ? null : _overcome,
          style: _primaryStyle,
          child: const Text('A vontade passou'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _smokedButton(),
      ],
    );
  }

  Widget _buildCheckIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.self_improvement, size: 56, color: AppColors.teal500),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Como está a vontade agora?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: _isSaving ? null : _overcome,
          style: _primaryStyle,
          child: const Text('Passou'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: _isSaving ? null : _moreTime,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.onDark,
            side: BorderSide(color: AppColors.onDark.withValues(alpha: 0.3)),
          ),
          child: const Text('Ainda estou com vontade · mais 2 minutos'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _isSaving ? null : _talkToAssistant,
          style: TextButton.styleFrom(foregroundColor: AppColors.teal500),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Conversar com a assistente'),
        ),
        _smokedButton(),
      ],
    );
  }

  Widget _buildVictory() {
    final total = _overcomeTotal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal500.withValues(alpha: 0.14),
                border: Border.all(color: AppColors.teal500, width: 3),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 56, color: AppColors.teal500),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Você venceu mais uma vontade',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (total != null && total > 0)
          Text(
            total == 1
                ? 'Essa foi a sua primeira vitória registrada.'
                : 'Essa foi a sua ${total}ª vitória.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.teal500,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Cada vontade que passa mostra que você está no controle.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.onDarkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: _primaryStyle,
          child: const Text('Voltar ao início'),
        ),
      ],
    );
  }

  Widget _smokedButton() {
    return TextButton(
      onPressed: _isSaving ? null : _smoked,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onDark.withValues(alpha: 0.5),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: const Text('Não aguentei, fumei'),
    );
  }

  ButtonStyle get _primaryStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal500,
        foregroundColor: AppColors.navy900,
        disabledBackgroundColor: AppColors.teal500.withValues(alpha: 0.4),
      );
}

/// Círculo que guia a respiração: cresce ao inspirar, para ao segurar,
/// diminui devagar ao soltar o ar.
class _BreathingCircle extends StatelessWidget {
  final Animation<double> animation;

  const _BreathingCircle({required this.animation});

  static const double _size = 240;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          const inhale = _SosScreenState._inhale;
          const hold = _SosScreenState._hold;
          const exhale = _SosScreenState._exhale;
          final t = animation.value * _SosScreenState._cycle;

          final double scale;
          final String label;
          if (t < inhale) {
            scale = 0.55 + 0.45 * Curves.easeInOut.transform(t / inhale);
            label = 'Inspire';
          } else if (t < inhale + hold) {
            scale = 1.0;
            label = 'Segure';
          } else {
            final p = (t - inhale - hold) / exhale;
            scale = 1.0 - 0.45 * Curves.easeInOut.transform(p);
            label = 'Solte o ar devagar';
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              // Contorno do tamanho máximo, como referência
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal500.withValues(alpha: 0.16),
                    border: Border.all(color: AppColors.teal500, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal500.withValues(alpha: 0.25 * scale),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}