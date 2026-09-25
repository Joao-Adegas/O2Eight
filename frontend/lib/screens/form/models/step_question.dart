class StepQuestion {
  final String title;
  final List<String> options;
  final String? Function() getter;
  final void Function(String?) setter;

  StepQuestion({
    required this.title,
    required this.options,
    required this.getter,
    required this.setter,
  });
}
