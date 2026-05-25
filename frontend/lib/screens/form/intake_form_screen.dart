import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../components/gradient_button.dart';
import '../../components/section_card.dart';
import '../../core/theme/app_theme.dart';

class IntakeFormScreen extends StatefulWidget {
  const IntakeFormScreen({super.key});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  int _step = 0;

  String? _tempoFuma;
  String? _cigarrosDia;
  String? _motivacao;
  String? _tipoCigarro;
  String? _historicoSaude;
  String? _horarioMaisFuma;
  String? _gatilhoEmocional;

  late final List<_StepQuestion> _questions = [
    _StepQuestion(
      title: 'A quanto tempo fuma?',
      options: const [
        '1 dia a 1 semana',
        '1 semana a 1 mes',
        '1 mes a 3 meses',
        '3 meses a 1 ano',
      ],
      getter: () => _tempoFuma,
      setter: (v) => _tempoFuma = v,
    ),
    _StepQuestion(
      title: 'Quantos cigarros por dia?',
      options: const ['1 a 5', '5 a 10', '+10'],
      getter: () => _cigarrosDia,
      setter: (v) => _cigarrosDia = v,
    ),
    _StepQuestion(
      title: 'Motivacao para parar de fumar',
      options: const [
        'Saude',
        'Dinheiro',
        'Familia',
        'Gravidez',
        'Esporte/Performance',
        'Estetica',
        'Ansiedade',
      ],
      getter: () => _motivacao,
      setter: (v) => _motivacao = v,
    ),
    _StepQuestion(
      title: 'Qual tipo de cigarro voce fuma?',
      options: const ['Paiero', 'POD', 'VAPE', 'Cigarro', 'Todos'],
      getter: () => _tipoCigarro,
      setter: (v) => _tipoCigarro = v,
    ),
    _StepQuestion(
      title: 'Possui problemas de saude no historico familiar?',
      options: const [
        'Cancer de pulmao/garganta/boca',
        'Bronquite cronica',
        'Enfisema pulmonar',
        'DPOC',
        'Asma',
        'Outros',
        'Nao possuo',
      ],
      getter: () => _historicoSaude,
      setter: (v) => _historicoSaude = v,
    ),
    _StepQuestion(
      title: 'Qual horario em que voce mais fuma?',
      options: const ['De manha', 'De tarde', 'De noite'],
      getter: () => _horarioMaisFuma,
      setter: (v) => _horarioMaisFuma = v,
    ),
    _StepQuestion(
      title: 'Possui algum gatilho emocional?',
      options: const [
        'Ansiedade',
        'Estresse',
        'Tedio',
        'Tristeza',
        'Depois do cafe',
        'Apos refeicoes',
        'Alcool',
      ],
      getter: () => _gatilhoEmocional,
      setter: (v) => _gatilhoEmocional = v,
    ),
  ];

  bool get _canAdvance => _questions[_step].getter() != null;

  void _next() {
    if (!_canAdvance) return;

    if (_step == _questions.length - 1) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
    final progress = (_step + 1) / _questions.length;
    final question = _questions[_step];

    return Scaffold(
      body: Stack(
        children: [
          const _FormBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        'Perfil inicial',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_step + 1}/${_questions.length}',
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: AppTheme.accentEnd.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentStart),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SectionCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [AppTheme.accentStart, AppTheme.accentEnd],
                            ).createShader(rect),
                            child: Text(
                              question.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Escolha uma opcao para personalizar seu plano.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final option in question.options)
                                    _ChoicePill(
                                      label: option,
                                      selected: option == question.getter(),
                                      onTap: () {
                                        setState(() {
                                          question.setter(option);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    text: _step == _questions.length - 1 ? 'Finalizar e entrar' : 'Continuar',
                    onPressed: _canAdvance ? _next : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = const LinearGradient(
      colors: [AppTheme.accentStart, AppTheme.accentEnd],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: selected ? selectedColor : null,
          color: selected
              ? null
              : (isDark ? const Color(0x1AFFFFFF) : const Color(0xFFEAF2F9)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF0B1F3A)
                  : (isDark ? AppTheme.darkText : AppTheme.lightText),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormBackground extends StatelessWidget {
  const _FormBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0A1B33), Color(0xFF0B1F3A)]
              : const [Color(0xFFF4F8FC), Color(0xFFE7F0FA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _Glow(
              size: 260,
              color: AppTheme.accentEnd.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _Glow(
              size: 280,
              color: AppTheme.accentStart.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

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

class _StepQuestion {
  final String title;
  final List<String> options;
  final String? Function() getter;
  final void Function(String?) setter;

  _StepQuestion({
    required this.title,
    required this.options,
    required this.getter,
    required this.setter,
  });
}
