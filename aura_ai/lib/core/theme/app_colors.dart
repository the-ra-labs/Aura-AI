import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF05050F);
  static const violet = Color(0xFF7B6CFF);
  static const purple = Color(0xFFB36BFF);
  static const cyan = Color(0xFF35E0FF);
  static const pink = Color(0xFFFF5FA2);
  static const gold = Color(0xFFFFB454);
  static const textPrimary = Color(0xFFF4F4FF);
  static const textSecondary = Color(0xA6F4F4FF);

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, purple],
  );
  static const brandWarm = LinearGradient(colors: [gold, pink]);
}