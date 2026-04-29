import 'package:flutter/material.dart';

class SteamTheme {
  static const darkBg = Color(0xFF101216);
  static const steamNavy = Color(0xFF171a21);
  static const steamBlue = Color(0xFF66c0f4);
  static const cardBg = Color(0xFF1b2838);

  static Color getScoreColor(double score) {
    if (score >= 75) return const Color(0xFFa3cf06); // Verde
    if (score >= 50) return const Color(0xFFffbd00); // Amarelo
    return const Color(0xFFff0000); // Vermelho
  }
}