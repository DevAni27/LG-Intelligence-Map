import 'package:flutter/material.dart';

/// Global Pulse dark theme — deep navy background with cyan/teal accents.
/// Matches the UI mockups from the proposal.
class AppTheme {
  AppTheme._();

  // ── Brand colors ──────────────────────────────────────────────
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1A2332);
  static const Color cardColor = Color(0xFF151D2E);

  static const Color primary = Color(0xFF00BCD4); // cyan accent
  static const Color primaryLight = Color(0xFF4DD0E1);
  static const Color primaryDark = Color(0xFF0097A7);

  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textTertiary = Color(0xFF546E7A);

  // ── Event category colors ─────────────────────────────────────
  static const Color earthquakeColor = Color(0xFFEF4444); // red
  static const Color floodStormColor = Color(0xFF3B82F6); // blue
  static const Color wildfireColor = Color(0xFFF97316); // orange
  static const Color diseaseColor = Color(0xFFA855F7); // purple
  static const Color conflictColor = Color(0xFFEAB308); // yellow

  // ── Severity colors ───────────────────────────────────────────
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityMedium = Color(0xFFEAB308);
  static const Color severityLow = Color(0xFF6B7280);

  // ── Status colors ─────────────────────────────────────────────
  static const Color statusConnected = Color(0xFF22C55E);
  static const Color statusDisconnected = Color(0xFFEF4444);
  static const Color statusLoading = Color(0xFFEAB308);

  // ── Theme data ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: primaryLight,
        error: severityCritical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textTertiary,
          fontSize: 12,
        ),
      ),
    );
  }
}
