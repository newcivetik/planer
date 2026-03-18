import 'package:flutter/material.dart';

class AppColors {
  // ── Accent ──────────────────────────────────────────────
  static const Color accentLight = Color(0xFF4A90D9);
  static const Color accentDark = Color(0xFF5B9FE8);
  static const Color accentBgLight = Color(0xFFE8F0FE);
  static const Color accentBgDark = Color(0xFF1E3A5F);

  // Legacy aliases
  static const Color primaryLight = accentLight;
  static const Color primaryDark = accentDark;

  // ── Light palette ───────────────────────────────────────
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightSecondary = Color(0xFF888888);
  static const Color lightMuted = Color(0xFFBBBBBB);
  static const Color lightBorder = Color(0xFFEEEEEE);

  // ── Dark palette ────────────────────────────────────────
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkInput = Color(0xFF333333);
  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkSecondary = Color(0xFF999999);
  static const Color darkMuted = Color(0xFF666666);
  static const Color darkBorder = Color(0xFF333333);

  // ── Priority ────────────────────────────────────────────
  static const Color priorityHigh = Color(0xFFE74C3C);
  static const Color priorityMedium = Color(0xFFF39C12);
  static const Color priorityLow = Color(0xFF4A90D9);

  // ── Semantic ────────────────────────────────────────────
  static const Color danger = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);

  // ── Accent picker options ───────────────────────────────
  static const List<Color> accentOptions = [
    Color(0xFF4A90D9), // Синий
    Color(0xFF4CAF50), // Зелёный
    Color(0xFFE53935), // Красный
    Color(0xFF9C27B0), // Фиолетовый
    Color(0xFFFF9800), // Оранжевый
    Color(0xFF00BCD4), // Бирюзовый
    Color(0xFFE91E63), // Розовый
    Color(0xFF607D8B), // Серо-синий
  ];

  static const List<String> accentNames = [
    'Синий',
    'Зелёный',
    'Красный',
    'Фиолетовый',
    'Оранжевый',
    'Бирюзовый',
    'Розовый',
    'Серо-синий',
  ];

  // ── Category colors ─────────────────────────────────────
  static const List<Color> categoryColors = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5C6BC0),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFF7043),
  ];

  // ── Helpers ─────────────────────────────────────────────
  /// Subtle shadow matching the prototype: 0 1px 3px rgba(0,0,0,0.06)
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Returns the accent background tint for the given brightness.
  static Color accentBg(Brightness brightness) =>
      brightness == Brightness.light ? accentBgLight : accentBgDark;
}
