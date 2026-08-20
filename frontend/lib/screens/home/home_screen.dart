import 'package:flutter/material.dart';
import 'package:flutter_version/screens/home/components/vettical_carrossel.dart';
import './widgets/filled_image.dart';
import './widgets/card_user.dart';


enum HomeTab { dashboard, patterns, chat, community, insights }

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Define um espaçamento lateral único para reaproveitar em toda a tela
  static const double _horizontalPadding = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Olá User",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Text(
                          "37 dias de progresso",
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Card sobrepondo — usa o mesmo _horizontalPadding do topo
                  const Positioned(
                    bottom: -100,
                    left: _horizontalPadding,
                    right: _horizontalPadding,
                    child: UserCard(daysNotSmoked: 12, money: 21),
                  ),
                ],
              ),
              const SizedBox(height: 130),

              // Container "Recuperação Biológica" — mesma técnica: sem width fixo,
              // usa Padding externo com o MESMO valor do topo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                ),
                child: Container(
                  alignment: Alignment.topLeft,
                  width: double.infinity, // ocupa toda a largura disponível
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
                        items:  [
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
            ],
          ),
        ),
      ),
    );
  }
}