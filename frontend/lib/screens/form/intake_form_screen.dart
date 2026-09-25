// lib/screens/form/intake_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../services/form_service.dart';
import 'models/step_question.dart';
import 'widgets/optionTile.dart';
import 'widgets/stepIndicator.dart';

class IntakeFormScreen extends StatefulWidget {
  const IntakeFormScreen({super.key});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  final _formService = FormService();
  final _priceController = TextEditingController();

  int _step = 0;
  bool _isSubmitting = false;

  /// Respostas por campo da API. Escolha única também vira lista de 1 item.
  final Map<String, List<String>> _answers = {};

  // Os textos das opções precisam ser IGUAIS aos Literal do backend
  // (api/schemas/onboarding.py) nas perguntas de escolha única.
  static const List<StepQuestion> _questions = [
    StepQuestion(
      field: 'smoking_time',
      title: 'Há quanto tempo você fuma?',
      type: StepType.single,
      options: [
        '1 dia a 1 semana',
        '1 semana a 1 mês',
        '1 mês a 3 meses',
        '3 meses a 1 ano',
        'Mais de 1 ano',
      ],
    ),
    StepQuestion(
      field: 'cigarettes_per_day',
      title: 'Quantos cigarros por dia?',
      type: StepType.single,
      options: [
        'Entre 1 e 5',
        'Entre 5 e 10',
        'Entre 10 e 15',
        'Entre 15 e 20',
        'Mais de 20',
      ],
    ),
    StepQuestion(
      field: 'motivations_to_quit',
      title: 'Motivação para parar de fumar',
      type: StepType.multiple,
      options: [
        'Saúde',
        'Dinheiro',
        'Família',
        'Gravidez',
        'Esporte/Performance',
        'Estética',
        'Ansiedade',
      ],
    ),
    StepQuestion(
      field: 'cigarette_type',
      title: 'Qual tipo de cigarro você fuma?',
      type: StepType.multiple,
      options: ['Palito', 'POD', 'VAPE', 'Cigarro', 'Todos'],
      exclusiveOption: 'Todos',
    ),
    StepQuestion(
      field: 'pack_price',
      title: 'Quanto você gasta, em média, por maço ou refil?',
      type: StepType.price,
    ),
    StepQuestion(
      field: 'family_health_history',
      title: 'Possui problemas de saúde no histórico familiar?',
      type: StepType.multiple,
      options: [
        'Câncer de pulmão/garganta/boca',
        'Bronquite crônica',
        'Enfisema pulmonar',
        'DPOC',
        'Asma',
        'Outros',
        'Não possuo',
      ],
      exclusiveOption: 'Não possuo',
    ),
    StepQuestion(
      field: 'time_smoke_the_most',
      title: 'Qual horário em que você mais fuma?',
      type: StepType.single,
      options: ['De manhã', 'De tarde', 'De noite'],
    ),
    StepQuestion(
      field: 'triggers',
      title: 'Possui algum gatilho emocional?',
      type: StepType.multiple,
      options: [
        'Ansiedade',
        'Estresse',
        'Tédio',
        'Tristeza',
        'Depois do café',
        'Após refeições',
        'Álcool',
      ],
    ),
  ];

  static const _teal = Color(0xFF3ABFBF);
  static const _darkNavy = Color(0xFF1A2A3A);
  static const _textDark = Color(0xFF111111);
  static const _textMuted = Color(0xFF777777);

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  // ───────────────────────── Lógica ─────────────────────────

  StepQuestion get _current => _questions[_step];
  bool get _isLastStep => _step == _questions.length - 1;

  double? get _packPrice =>
      double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

  bool get _canAdvance {
    if (_current.type == StepType.price) {
      final price = _packPrice;
      return price != null && price > 0;
    }
    return (_answers[_current.field] ?? const []).isNotEmpty;
  }

  bool _isSelected(String option) =>
      (_answers[_current.field] ?? const []).contains(option);

  void _toggleOption(String option) {
    final q = _current;
    final selected = List<String>.from(_answers[q.field] ?? const []);

    if (q.type == StepType.single) {
      selected
        ..clear()
        ..add(option);
    } else if (selected.contains(option)) {
      selected.remove(option);
    } else if (option == q.exclusiveOption) {
      selected
        ..clear()
        ..add(option);
    } else {
      selected
        ..remove(q.exclusiveOption)
        ..add(option);
    }

    setState(() => _answers[q.field] = selected);
  }

  void _next() {
    if (!_canAdvance || _isSubmitting) return;
    if (_isLastStep) {
      _submit();
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0 || _isSubmitting) return;
    setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    String single(String field) => _answers[field]!.first;

    try {
      await _formService.submitForm({
        'smoking_time': single('smoking_time'),
        'cigarettes_per_day': single('cigarettes_per_day'),
        'cigarette_type': _answers['cigarette_type'],
        'motivations_to_quit': _answers['motivations_to_quit'],
        'pack_price': _packPrice,
        'triggers': _answers['triggers'],
        'family_health_history': _answers['family_health_history'],
        'time_smoke_the_most': single('time_smoke_the_most'),
      });
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } catch (e) {
      debugPrint('ERRO ao enviar formulário: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar suas respostas. $e')),
      );
    }
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _teal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3CCCB4), Color(0xFF0F5A8F)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 40).clamp(0.0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Indicador de etapas ──
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

                    // ── Card branco ──
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 370),
                        child: _buildCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final q = _current;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_step + 1}. ${q.title}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
              height: 1.3,
            ),
          ),
          if (q.type != StepType.single) ...[
            const SizedBox(height: 4),
            Text(
              q.type == StepType.multiple
                  ? 'Selecione uma ou mais opções'
                  : 'Pode ser um valor aproximado',
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ],
          const SizedBox(height: 18),

          // ── Opções ou campo de preço ──
          if (q.type == StepType.price)
            _buildPriceField()
          else
            ...q.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptionTile(
                  label: option,
                  selected: _isSelected(option),
                  onTap: () => _toggleOption(option),
                ),
              ),
            ),

          const SizedBox(height: 6),

          // ── Botões ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_step == 0 || _isSubmitting) ? null : _back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF555555),
                    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_canAdvance && !_isSubmitting) ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkNavy,
                    disabledBackgroundColor: _darkNavy.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLastStep ? 'Finalizar' : 'Próximo',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    const valueStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _textDark,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _priceController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Aceita até 4 dígitos e 2 casas decimais, com vírgula ou ponto
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                RegExp(r'^\d{0,4}([.,]\d{0,2})?$').hasMatch(newValue.text)
                    ? newValue
                    : oldValue,
          ),
        ],
        style: valueStyle,
        cursorColor: _teal,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(
          prefixText: 'R\$ ',
          prefixStyle: valueStyle,
          hintText: '0,00',
          hintStyle: const TextStyle(fontSize: 18, color: Color(0xFFAAAAAA)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
      ),
    );
  }
}