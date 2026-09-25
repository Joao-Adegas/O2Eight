import 'package:flutter/material.dart';
import 'package:flutter_version/screens/home/widgets/filled_image.dart';

class UserCard extends StatelessWidget {
  final double daysNotSmoked;
  final double money;

  const UserCard({
    super.key,
    required this.daysNotSmoked,
    required this.money,
  });

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
                style: const TextStyle(color: Colors.black,fontSize: 30,fontWeight:FontWeight.w700 ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Dinheiro economizado",
                style: TextStyle(color: Color(0xFF0780AE)),
              ),
              Text(
                "R\$ ${money.toInt()}",
                style: const TextStyle(color: Color(0xFF0780AE),fontSize: 30,fontWeight:FontWeight.w700),
              ),
            ],
          ),
          const FilledImage(fillPercent: 0.3),
        ],
      ),
    );
  }
}