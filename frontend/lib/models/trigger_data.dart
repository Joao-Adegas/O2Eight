import 'package:flutter/material.dart';

class TriggerData {
  final String name;
  final double percentage; // 0.0 a 1.0, para a barra de progresso
  final IconData icon;

  const TriggerData({
    required this.name,
    required this.percentage,
    required this.icon,
  });
}

// Mock de dados — ajuste os valores/ícones conforme sua base real
const List<TriggerData> mockTriggers = [
  TriggerData(name: "Café", percentage: 0.4, icon: Icons.coffee),
  TriggerData(name: "Estresse", percentage: 0.65, icon: Icons.sentiment_dissatisfied),
  TriggerData(name: "Tédio", percentage: 0.3, icon: Icons.hourglass_empty),
  TriggerData(name: "Álcool", percentage: 0.5, icon: Icons.local_bar),
  TriggerData(name: "Após refeição", percentage: 0.55, icon: Icons.restaurant),
  TriggerData(name: "Socialização", percentage: 0.45, icon: Icons.groups),
];