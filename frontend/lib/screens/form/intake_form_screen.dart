import 'package:flutter/material.dart';
import 'models/step_question.dart';
import '../../app/routes.dart';
import 'widgets/optionTile.dart';
import 'widgets/stepIndicator.dart';

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

  late final List<StepQuestion> _questions = [
    StepQuestion(
      title: 'Há quanto tempo você fuma?',
      options: const [
        '1 dia a 1 semana',
        '1 semana a 1 mês',
        '1 mês a 3 meses',
        '3 meses a 1 ano',
      ],
      getter: () => _tempoFuma,
      setter: (v) => _tempoFuma = v,
    ),
    StepQuestion(
      title: 'Quantos cigarros por dia?',
      options: const ['1 a 5', '5 a 10', '+10'],
      getter: () => _cigarrosDia,
      setter: (v) => _cigarrosDia = v,
    ),
    StepQuestion(
      title: 'Motivação para parar de fumar',
      options: const [
        'Saúde',
        'Dinheiro',
        'Família',
        'Gravidez',
        'Esporte/Performance',
        'Estética',
        'Ansiedade',
      ],
      getter: () => _motivacao,
      setter: (v) => _motivacao = v,
    ),
    StepQuestion(
      title: 'Qual tipo de cigarro você fuma?',
      options: const ['Palito', 'POD', 'VAPE', 'Cigarro', 'Todos'],
      getter: () => _tipoCigarro,
      setter: (v) => _tipoCigarro = v,
    ),
    StepQuestion(
      title: 'Possui problemas de saúde no histórico familiar?',
      options: const [
        'Câncer de pulmão/garganta/boca',
        'Bronquite crônica',
        'Enfisema pulmonar',
        'DPOC',
        'Asma',
        'Outros',
        'Não possuo',
      ],
      getter: () => _historicoSaude,
      setter: (v) => _historicoSaude = v,
    ),
    StepQuestion(
      title: 'Qual horário em que você mais fuma?',
      options: const ['De manhã', 'De tarde', 'De noite'],
      getter: () => _horarioMaisFuma,
      setter: (v) => _horarioMaisFuma = v,
    ),
    StepQuestion(
      title: 'Possui algum gatilho emocional?',
      options: const [
        'Ansiedade',
        'Estresse',
        'Tédio',
        'Tristeza',
        'Depois do café',
        'Após refeições',
        'Álcool',
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
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step -= 1);
  }

  static const _bgColor = Color(0xFF3ABFBF);
  static const _darkNavy = Color(0xFF1A2A3A);

  @override
  Widget build(BuildContext context) {
    final question = _questions[_step];

    return Scaffold(
      backgroundColor: _bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3CCCB4),
              Color(0xFF0F5A8F),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Step Indicator ──────────────────────────────────────────
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StepIndicator(
                        totalSteps: _questions.length,
                        currentStep: _step,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Card branco ─────────────────────────────────────────────

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 370),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8, // desfoque
                            spreadRadius: 2, // expansão
                            offset:
                                const Offset(0, 8), // (horizontal, vertical)
                          ),
                        ],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize:
                            MainAxisSize.min, // <-- encolhe ao conteúdo
                        children: [
                          Text(
                            '${_step + 1}. ${question.title}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Lista sem Expanded — altura natural
                          ...List.generate(question.options.length, (index) {
                            final option = question.options[index];
                            final selected = option == question.getter();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OptionTile(
                                label: option,
                                selected: selected,
                                onTap: () =>
                                    setState(() => question.setter(option)),
                              ),
                            );
                          }),

                          const SizedBox(height: 6),

                          // ── Botões ──────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _back,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF555555),
                                    side: const BorderSide(
                                        color: Color(0xFFCCCCCC), width: 1.5),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  child: const Text(
                                    'Voltar',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 60),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _canAdvance ? _next : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _darkNavy,
                                    disabledBackgroundColor:
                                        _darkNavy.withValues(alpha: 0.4),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                  ),
                                  child: Text(
                                    _step == _questions.length - 1
                                        ? 'Finalizar'
                                        : 'Próximo',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
