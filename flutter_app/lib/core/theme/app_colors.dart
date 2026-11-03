import 'package:flutter/material.dart';

/// Centralized color palette for SitePyoe — dark forest-green nursery theme.
abstract final class AppColors {
  // ── Dark colors (Default UI) ──────────────────────────────
  static const Color darkBackground     = Color(0xFF0D1F17); // Deep dark forest
  static const Color darkSurface        = Color(0xFF142A1E); // Card surface
  static const Color darkSurfaceVariant = Color(0xFF1C3827); // Elevated surface
  static const Color darkNavRailBg      = Color(0xFF091710); // Darkest rail
  static const Color darkTextPrimary    = Color(0xFFF0F7F2);
  static const Color darkTextSecondary  = Color(0xFF8BB89A);
  static const Color darkTextMuted      = Color(0xFF5A7A6A);
  static const Color darkBorder         = Color(0xFF1F3D2C);
  static const Color darkBorderLight    = Color(0xFF2A5038);
  static const Color darkDivider        = Color(0xFF162B20);

  // ── Light / White colors ──────────────────────────────────
  static const Color lightBackground     = Color(0xFFF4F6F4); // Clean soft light
  static const Color lightSurface        = Color(0xFFFFFFFF); // Pure white card
  static const Color lightSurfaceVariant = Color(0xFFE8ECE9); // Light elevated surface
  static const Color lightNavRailBg      = Color(0xFFFFFFFF); // White rail with border
  static const Color lightTextPrimary    = Color(0xFF14241B); // Dark charcoal green
  static const Color lightTextSecondary  = Color(0xFF456B54); // Muted forest sage
  static const Color lightTextMuted      = Color(0xFF759482); // Soft sage gray
  static const Color lightBorder         = Color(0xFFD6DFD9); // Light crisp border
  static const Color lightBorderLight    = Color(0xFFE5ECE7);
  static const Color lightDivider        = Color(0xFFE2E9E4);

  // ── Active Theme State ────────────────────────────────────
  static bool isDark = true;

  // ── Active Theme-dependent Colors ─────────────────────────
  static Color background     = darkBackground;
  static Color surface        = darkSurface;
  static Color surfaceVariant = darkSurfaceVariant;
  static Color navRailBg      = darkNavRailBg;
  static Color textPrimary    = darkTextPrimary;
  static Color textSecondary  = darkTextSecondary;
  static Color textMuted      = darkTextMuted;
  static Color border         = darkBorder;
  static Color borderLight    = darkBorderLight;
  static Color divider        = darkDivider;

  static void setThemeMode(ThemeMode mode) {
    isDark = mode != ThemeMode.light;
    background     = isDark ? darkBackground : lightBackground;
    surface        = isDark ? darkSurface : lightSurface;
    surfaceVariant = isDark ? darkSurfaceVariant : lightSurfaceVariant;
    navRailBg      = isDark ? darkNavRailBg : lightNavRailBg;
    textPrimary    = isDark ? darkTextPrimary : lightTextPrimary;
    textSecondary  = isDark ? darkTextSecondary : lightTextSecondary;
    textMuted      = isDark ? darkTextMuted : lightTextMuted;
    border         = isDark ? darkBorder : lightBorder;
    borderLight    = isDark ? darkBorderLight : lightBorderLight;
    divider        = isDark ? darkDivider : lightDivider;
  }

  // ── Brand ────────────────────────────────────────────────
  static const Color primary        = Color(0xFF30C97C); // Emerald green
  static const Color primaryDark    = Color(0xFF25A464);
  static const Color primaryLight   = Color(0xFF5FE19D);
  static const Color accent         = Color(0xFFF5C842); // Gold (prices)

  // ── Semantic ─────────────────────────────────────────────
  static const Color success        = Color(0xFF4CAF82);
  static const Color warning        = Color(0xFFF5C842);
  static const Color error          = Color(0xFFE57373);
  static const Color textOnPrimary  = Color(0xFF001A0D);

  // ── Category accents ─────────────────────────────────────
  static const Color catPlants      = Color(0xFF2E7D52);
  static const Color catPots        = Color(0xFF8B4513);
  static const Color catChemicals   = Color(0xFF1565C0);
  static const Color catTools       = Color(0xFF6A1B9A);
  static const Color catOthers      = Color(0xFF37474F);

  // ── Origin badge colors ───────────────────────────────────
  static const Color originThai     = Color(0xFF1565C0); // Thai flag blue
  static const Color originChina    = Color(0xFFC62828); // China flag red
  static const Color originLocal    = Color(0xFF2E7D52); // Local / Myanmar green

  // ── Payment method ───────────────────────────────────────
  static const Color paymentCash    = Color(0xFF4CAF50);
  static const Color paymentKpay    = Color(0xFF1E88E5);
  static const Color paymentBanking = Color(0xFF7B1FA2);
  static const Color paymentCredit  = Color(0xFFE64A19);
}
