// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_version/app/routes.dart';
import 'package:flutter_version/core/theme/app_theme.dart';
import 'package:flutter_version/screens/home/widgets/progress_hero.dart';
import 'package:flutter_version/screens/home/widgets/recovery_timeline.dart';
import 'package:flutter_version/screens/home/widgets/risk_alert_banner.dart';
import 'package:flutter_version/screens/home/widgets/triggers_section.dart';
import 'package:flutter_version/screens/sos/sos_screen.dart';
import 'package:flutter_version/services/achievement_service.dart';
import 'package:flutter_version/services/auth_service.dart';
import 'package:flutter_version/services/form_service.dart';
import 'package:flutter_version/services/progress_service.dart';
import 'package:flutter_version/widgets/achievement_dialog.dart';
import 'package:flutter_version/widgets/nav_bottom_bar.dart';
import 'package:flutter_version/widgets/test_version_dialog.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _formService = FormService();
  final _progressService = ProgressService();
  final _achievementService = AchievementService();

  String _userName = '';
  DateTime _cleanSince = DateTime.now();
  double _dailyCost = 0;
  List<TriggerItem> _triggers = [];
  String? _riskTime;
  List<String> _motivations = [];
  bool _noticeOpen = false; // evita abrir o aviso duas vezes ao recarregar

  bool _isLoading = true;
  String? _error;
  bool _achievementChecked = false; // verifica só uma vez por abertura
  AppTab _currentTab = AppTab.dashboard;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // register-sso é idempotente: cria o usuário se não existir e devolve os dados
      final user = await _authService.registerSsoAndFetchUser();

      // Ainda não aceitou o termo em vigor → manda para a tela do termo
      if (user['terms_up_to_date'] != true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.consent);
        return;
      }

      // Primeiro acesso: ainda não respondeu o formulário → manda para ele
      final form = await _formService.getMyForm();
      if (!mounted) return;
      if (form == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.form);
        return;
      }

      final dashboard = await _progressService.getDashboard();
      if (!mounted) return;

      setState(() {
        _userName = (user['name'] as String?) ?? 'Usuário';
        _cleanSince =
            DateTime.tryParse((dashboard['clean_since'] as String?) ?? '')
                    ?.toLocal() ??
                DateTime.now();
        _dailyCost = (dashboard['daily_cost'] as num?)?.toDouble() ?? 0;

        // Gatilhos do formulário (sem nível até existir a análise da Etapa 4)
        _triggers = ((form['triggers'] as List<dynamic>?) ?? const [])
            .map((t) => TriggerItem(name: t.toString()))
            .toList();
        _riskTime = form['time_smoke_the_most'] as String?;
        _motivations =
            ((form['motivations_to_quit'] as List<dynamic>?) ?? const [])
                .map((m) => m.toString())
                .toList();

        _isLoading = false;
      });

      // Depois que a Home aparece: aviso de versão de testes e, em seguida,
      // conquista nova (se houver)
      WidgetsBinding.instance.addPostFrameCallback((_) => _afterHomeShown());
    } catch (e, st) {
      debugPrint('ERRO _loadData: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _error =
            'Não foi possível carregar seus dados.\n$e'; // tire o $e quando estiver tudo ok
        _isLoading = false;
      });
    }
  }

  String get _firstName {
    final parts = _userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// Aviso de versão de testes (uma vez por usuário neste aparelho).
  /// Se a pessoa escolher sair, encerra a sessão e volta ao login.
  Future<void> _afterHomeShown() async {
    final userId = _authService.currentUser?.id;
    if (userId == null || !mounted || _noticeOpen) return;

    _noticeOpen = true;
    final canContinue = await showTestVersionNoticeIfNeeded(context, userId: userId);
    _noticeOpen = false;
    if (!mounted) return;

    if (!canContinue) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      return;
    }

    await _maybeShowAchievement();
  }

  Future<void> _maybeShowAchievement() async {
    if (_achievementChecked || !mounted) return;
    _achievementChecked = true;

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final achievement = await _achievementService.pending(
      userId: userId,
      cleanSince: _cleanSince,
    );
    if (achievement == null || !mounted) return;

    // Marca antes de mostrar, para não repetir se o app for fechado
    await _achievementService.markShown(
      userId: userId,
      cleanSince: _cleanSince,
      achievement: achievement,
    );
    if (!mounted) return;

    final savedMoney =
        DateTime.now().difference(_cleanSince).inSeconds / 86400 * _dailyCost;

    final action = await showAchievementDialog(
      context,
      firstName: _firstName,
      achievement: achievement,
      savedMoney: savedMoney,
    );

    if (action == AchievementAction.share && mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.community,
        arguments:
            'Hoje completei ${achievement.title} sem fumar! Cada dia conta.',
      );
    }
  }

  /// Ícone "Padrões" da barra inferior e aviso de horário de risco.
  void _openInsights() {
    Navigator.of(context)
        .pushNamed(AppRoutes.insights, arguments: _motivations);
  }

  /// Botão "Estou com vontade": abre a respiração guiada.
  /// Ao voltar, recarrega a Home (o contador pode ter recomeçado).
  Future<void> _openSos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosScreen(motivations: _motivations),
        fullscreenDialog: true,
      ),
    );
    if (mounted) _loadData();
  }

  /// Abre o chat com uma pergunta já escrita no campo.
  void _askAssistant(String prompt) {
    Navigator.of(context).pushNamed(AppRoutes.chat, arguments: prompt);
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto busca os dados, mostra um loading simples em tela cheia.
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Se der erro (ex: sessão expirada, backend fora do ar), mostra
    // uma tela simples com opção de tentar de novo.
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// Ícone "Padrões" da barra inferior e aviso de horário de risco.
    void _openInsights() {
      Navigator.of(context)
          .pushNamed(AppRoutes.insights, arguments: _motivations);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSos,
        backgroundColor: AppColors.teal500,
        foregroundColor: AppColors.navy900,
        icon: const Icon(Icons.air),
        label: const Text(
          'Estou com vontade',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Destaque: pulmão, dias sem fumar e dinheiro economizado
              ProgressHero(
                userName: _userName,
                authService: _authService,
                cleanSince: _cleanSince,
                dailyCost: _dailyCost,
              ),

              // Seções abaixo do topo, centralizadas em telas largas
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.xl,
                      AppSpacing.screen,
                      96, // espaço para o botão "Estou com vontade"
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RiskAlertBanner(
                          key: ValueKey(_cleanSince),
                          onOpenInsights: _openInsights,
                        ),
                        RecoveryTimeline(cleanSince: _cleanSince),
                        const SizedBox(height: AppSpacing.xxl),
                        TriggersSection(
                          triggers: _triggers,
                          riskTime: _riskTime,
                          onAskAssistant: _askAssistant,
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
      bottomNavigationBar: NavBottomBar(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          if (tab == AppTab.chat) {
            Navigator.of(context).pushNamed(AppRoutes.chat);
            return;
          }
          if (tab == AppTab.community) {
            Navigator.of(context).pushNamed(AppRoutes.community);
            return;
          }
          if (tab == AppTab.patterns) {
            _openInsights();
            return;
          }
          if (tab == AppTab.patterns) {
            _openInsights();
            return;
          }
          setState(() => _currentTab = tab);
        },
      ),
    );
  }
}
