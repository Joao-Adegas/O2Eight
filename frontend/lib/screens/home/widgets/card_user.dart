// lib/screens/home/widgets/card_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_version/screens/home/widgets/filled_image.dart';

class UserCard extends StatelessWidget {
  final double daysNotSmoked;
  final double money;

  /// Meta usada para "encher" a imagem do pulmão (30 dias = 100%)
  static const int goalDays = 30;

  const UserCard({
    super.key,
    required this.daysNotSmoked,
    required this.money,
  });

  String get _moneyText => 'R\$ ${money.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tempo sem fumar",
                style: TextStyle(color: Colors.black),
              ),
              Text(
                "${daysNotSmoked.toInt()}d",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Dinheiro economizado",
                style: TextStyle(color: Color(0xFF0780AE)),
              ),
              Text(
                _moneyText,
                style: const TextStyle(
                  color: Color(0xFF0780AE),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          FilledImage(
            fillPercent: (daysNotSmoked / goalDays).clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }
}