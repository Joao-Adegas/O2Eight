import 'package:flutter/material.dart';
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
                  // Container com degradê
                  Container(
                    width: double.infinity,
                    height: 160, // ← um pouco menor agora
                    padding: const EdgeInsets.all(24),
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

                  // Card sobrepondo na parte de baixo
                  const Positioned(
                    bottom: -100, // ← metade do card para fora
                    left: 24,
                    right: 24,
                    child: UserCard(daysNotSmoked: 12, money: 21),
                  ),
                ],
              ),

              const SizedBox(height: 130), // ← espaço para compensar o card sobreposto
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Color(0xFF3CCCB4),
                    
                ),
                child: const Column(
                  children: [
                    Text("Recuperação Biológica" ,style: TextStyle(
                      color: Colors.black
                    ),),
                    SizedBox(height: 20),

                    // carrousel
                  ],
                ),
              )
            ],
            
          ),
        ),
      ),
    );
  }
}
