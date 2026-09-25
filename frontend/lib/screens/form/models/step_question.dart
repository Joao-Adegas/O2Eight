// lib/screens/form/models/step_question.dart

/// single   → escolhe 1 opção
/// multiple → escolhe 1 ou mais opções (vira lista na API)
/// price    → campo numérico em reais
enum StepType { single, multiple, price }

class StepQuestion {
  /// Nome do campo que a API espera (ex: 'smoking_time')
  final String field;
  final String title;
  final StepType type;
  final List<String> options;

  /// Opção que, ao ser marcada, desmarca as outras (ex: 'Não possuo')
  final String? exclusiveOption;

  const StepQuestion({
    required this.field,
    required this.title,
    required this.type,
    this.options = const [],
    this.exclusiveOption,
  });
}