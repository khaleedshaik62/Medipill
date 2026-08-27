import 'package:flutter/material.dart';

class AppColors {
  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);

  // Brand Colors - Premium Indigo theme
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF818CF8); // Indigo 400
  static const Color accent = Color(0xFF0EA5E9); // Sky 500

  // Soft Background Colors
  static const Color softBlue = Color(0xFFEEF2FF); // Indigo 50
  static const Color softTeal = Color(0xFFE0F2FE); // Sky 100
  static const Color softGreen = Color(0xFFECFDF5); // Emerald 50
  static const Color softOrange = Color(0xFFFFF7ED); // Orange 50
  static const Color softRed = Color(0xFFFEF2F2); // Red 50

  // Typography - Deep slate, never pure black
  static const Color primaryText = Color(0xFF1E293B); // Slate 800
  static const Color secondaryText = Color(0xFF64748B); // Slate 500
  static const Color mutedText = Color(0xFF94A3B8); // Slate 400

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  
  // Status Colors (for chips & hardware states)
  static const Color healthy = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color offline = Color(0xFF94A3B8); // Slate 400
}
