import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors matching TAMS Website
  static const Color primary = Color(0xFF0F2942); // Deep Navy
  static const Color primaryDark = Color(0xFF0B1A2B); // Dark Navy / Background
  static const Color primaryLight = Color(0xFF1B3A5C); // Navy Blue
  static const Color accent = Color(0xFFFF6F22); // Vibrant Orange
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentSoft = Color(0xFFFFF0E8);

  static const Color bgLight = Color(0xFFF0F3F8); // Page Background
  static const Color surface = Color(0xFFFFFFFF); // Card Surface
  static const Color textDark = Color(0xFF263445); // Slate Dark
  static const Color textMuted = Color(0xFF687789); // Muted Grey
  static const Color border = Color(0xFFDCE2E8); // Border Color

  // Status Colors
  static const Color success = Color(0xFF16834A);
  static const Color successSoft = Color(0xFFE6F5EC);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFF4E9);

  static const Color danger = Color(0xFFC0392B);
  static const Color dangerSoft = Color(0xFFFCEBE9);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFE7EEFE);

  // Status helper mapping
  static Color getStatusColor(String? status) {
    if (status == null) return textMuted;
    final s = status.toLowerCase().trim();
    if (s == 'available' || s == 'paid' || s == 'completed' || s == 'valid') {
      return success;
    }
    if (s == 'pending' || s == 'in progress' || s == 'expiring soon' || s == 'scheduled') {
      return warning;
    }
    if (s == 'on trip' || s == 'on duty' || s == 'confirmed') {
      return info;
    }
    if (s == 'maintenance' || s == 'unavailable' || s == 'expired' || s == 'cancelled' || s == 'overdue' || s == 'unpaid' || s == 'failed') {
      return danger;
    }
    return textMuted;
  }

  static Color getStatusBgColor(String? status) {
    if (status == null) return const Color(0xFFF1F5F9);
    final s = status.toLowerCase().trim();
    if (s == 'available' || s == 'paid' || s == 'completed' || s == 'valid') {
      return successSoft;
    }
    if (s == 'pending' || s == 'in progress' || s == 'expiring soon' || s == 'scheduled') {
      return warningSoft;
    }
    if (s == 'on trip' || s == 'on duty' || s == 'confirmed') {
      return infoSoft;
    }
    if (s == 'maintenance' || s == 'unavailable' || s == 'expired' || s == 'cancelled' || s == 'overdue' || s == 'unpaid' || s == 'failed') {
      return dangerSoft;
    }
    return const Color(0xFFF1F5F9);
  }

  // Format currency
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    try {
      final double val = amount is num ? amount.toDouble() : double.parse(amount.toString());
      return '₹${val.toStringAsFixed(2)}';
    } catch (_) {
      return '₹$amount';
    }
  }

  // Main ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
    );
  }
}
