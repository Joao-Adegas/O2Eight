// lib/services/achievement_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  /// Dias sem fumar necessários
  final int days;

  /// Como o marco aparece em destaque ("3 meses")
  final String title;

  /// Mensagem da janela. Afirmações de saúde seguem só os marcos do INCA.
  final String message;

  const Achievement({
    required this.days,
    required this.title,
    required this.message,
  });
}

/// Marcos em ordem crescente.
const List<Achievement> kAchievements = [
  Achievement(
    days: 1,
    title: '1 dia',
    message:
        'Você atravessou as primeiras 24 horas, que costumam ser as mais '
        'difíceis. Seus pulmões já estão funcionando melhor.',
  ),
  Achievement(
    days: 2,
    title: '2 dias',
    message: 'Seu olfato e seu paladar já começaram a melhorar.',
  ),
  Achievement(
    days: 7,
    title: '1 semana',
    message:
        'Sete dias de escolhas firmes. Cada dia a mais fortalece o novo hábito.',
  ),
  Achievement(
    days: 14,
    title: '2 semanas',
    message: 'Duas semanas sem fumar. A nova rotina está ganhando forma.',
  ),
  Achievement(
    days: 21,
    title: '3 semanas',
    message: 'Sua respiração está mais fácil e sua circulação melhorou.',
  ),
  Achievement(
    days: 30,
    title: '1 mês',
    message: 'Um mês inteiro sem cigarro. Isso é uma grande conquista.',
  ),
  Achievement(
    days: 90,
    title: '3 meses',
    message: 'Três meses de persistência. Seu corpo e sua rotina já são outros.',
  ),
  Achievement(
    days: 180,
    title: '6 meses',
    message: 'Meio ano sem fumar. Você provou que consegue.',
  ),
  Achievement(
    days: 365,
    title: '1 ano',
    message: 'O risco de morte por infarto já caiu pela metade.',
  ),
  Achievement(
    days: 730,
    title: '2 anos',
    message: 'Dois anos livre do cigarro. Uma trajetória que inspira.',
  ),
  Achievement(
    days: 1825,
    title: '5 anos',
    message:
        'Seu risco de infarto está se aproximando do de quem nunca fumou.',
  ),
];

/// Decide se há uma conquista nova para mostrar.
///
/// Guarda no aparelho o último marco exibido para cada sequência sem fumar.
/// A sequência é identificada pela data de início (clean_since): se a pessoa
/// fumar, a data muda e os marcos voltam a aparecer do zero.
class AchievementService {
  String _key(String userId, DateTime cleanSince) =>
      'achievement_${userId}_${cleanSince.toUtc().millisecondsSinceEpoch}';

  Achievement? _reached(DateTime cleanSince) {
    final days = DateTime.now().difference(cleanSince).inDays;
    Achievement? reached;
    for (final a in kAchievements) {
      if (days >= a.days) reached = a;
    }
    return reached;
  }

  /// Marco mais alto já atingido e ainda não exibido, ou null.
  Future<Achievement?> pending({
    required String userId,
    required DateTime cleanSince,
  }) async {
    final reached = _reached(cleanSince);
    if (reached == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_key(userId, cleanSince)) ?? 0;
    return reached.days > lastShown ? reached : null;
  }

  Future<void> markShown({
    required String userId,
    required DateTime cleanSince,
    required Achievement achievement,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(userId, cleanSince), achievement.days);
  }
}