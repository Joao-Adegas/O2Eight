// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_version/app/routes.dart';
import 'package:flutter_version/models/trigger_data.dart';
import 'package:flutter_version/screens/home/components/vettical_carrossel.dart';
import 'package:flutter_version/screens/home/widgets/trigger_carousel.dart';
import 'package:flutter_version/services/auth_service.dart';
import 'package:flutter_version/services/form_service.dart';
import 'package:flutter_version/services/progress_service.dart';
import 'package:flutter_version/widgets/nav_bottom_bar.dart';
import 'package:flutter_version/widgets/user_avatar_menu.dart';
import './widgets/card_user.dart';

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
  // Espaçamento lateral único para reaproveitar em toda a tela
  static const double _horizontalPadding = 24;

  final _authService = AuthService();
  final _formService = FormService();
  final _progressService = ProgressService();

  String _userName = '';
  int _cleanDays = 0;
  double _savedMoney = 0;

  bool _isLoading = true;
  String? _error;
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

      // Primeiro acesso: ainda não respondeu o formulário → manda para ele
      final hasForm = await _formService.hasForm();
      if (!mounted) return;
      if (!hasForm) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.form);
        return;
      }

      final dashboard = await _progressService.getDashboard();
      if (!mounted) return;

      setState(() {
        _userName = (user['name'] as String?) ?? 'Usuário';
        _cleanDays = (dashboard['clean_days'] as num).toInt();
        _savedMoney = (dashboard['estimated_saved_money'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('ERRO _loadData: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar seus dados.\n$e'; // tire o $e quando estiver tudo ok
        _isLoading = false;
      });
    }
  }

  String get _progressText =>
      _cleanDays == 1 ? '1 dia de progresso' : '$_cleanDays dias de progresso';

  @override
  Widget build(BuildContext context) {
    // Enquanto busca os dados, mostra um loading simples em tela cheia.
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Se der erro (ex: sessão expirada, backend fora do ar), mostra
    // uma tela simples com opção de tentar de novo.
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Container com degradê (ocupa 100% da largura, com padding interno)
                    Container(
                      width: double.infinity,
                      height: 160,
                      padding: const EdgeInsets.all(_horizontalPadding),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2ECFCF),
                            Color(0xFF1A7FA8),
                            Color(0xFF0D4F7C),
                          ],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Olá $_userName",
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                                Text(
                                  _progressText,
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          UserAvatarMenu(
                            userName: _userName,
                            authService: _authService,
                          ),
                        ],
                      ),
                    ),

                    // Card sobrepondo — usa o mesmo _horizontalPadding do topo
                    Positioned(
                      bottom: -100,
                      left: _horizontalPadding,
                      right: _horizontalPadding,
                      child: UserCard(
                        daysNotSmoked: _cleanDays.toDouble(),
                        money: _savedMoney,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 130),

                // "Recuperação Biológica" — ainda estático; vira IA na próxima etapa
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                  ),
                  child: Container(
                    alignment: Alignment.topLeft,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x503CCCB4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            "Recuperação Biológica",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        VerticalCarousel(
                          items: [
                            "Com 2 semanas sem fumar seus pulmões começam a ter uma respiração normal.",
                            "Com 1 mês sem fumar sua circulação sanguínea melhora.",
                            "Com 3 meses sem fumar sua função pulmonar aumenta em até 30%.",
                            "Com 1 ano sem fumar o risco de doença cardíaca cai pela metade.",
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // "Principais Gatilhos" — ainda com dados de exemplo
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Principais Gatilhos",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D4F7C),
                        ),
                      ),
                      SizedBox(height: 12),
                      TriggerCarousel(triggers: mockTriggers),
                    ],
                  ),
                ),
              ],
            ),
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
          setState(() => _currentTab = tab);
        },
      ),
    );
  }
}