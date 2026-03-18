import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  return AccentColorNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state);
  }
}

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(AppColors.accentOptions[0]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('accentColor');
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.toARGB32());
  }
}
