// lib/presentation/providers/app_state_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AppStateProvider extends ChangeNotifier {
  bool _hasCompletedOnboarding = false;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('tr', 'TR');
  bool _isInitialized = false;

  // Getters
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  AppStateProvider() {
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _hasCompletedOnboarding = prefs.getBool(
            AppConstants.keyOnboardingCompleted,
          ) ??
          false;

      final themeModeString = prefs.getString(AppConstants.keyThemeMode);
      _themeMode = _parseThemeMode(themeModeString);

      final languageCode = prefs.getString(AppConstants.keyLanguageCode);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Failed to load app state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyOnboardingCompleted, true);

      _hasCompletedOnboarding = true;
      notifyListeners();
    } catch (e) {
      print('Failed to save onboarding completion: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.keyThemeMode,
        mode.toString().split('.').last,
      );

      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      print('Failed to save theme mode: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLanguageCode, locale.languageCode);

      _locale = locale;
      notifyListeners();
    } catch (e) {
      print('Failed to save locale: $e');
    }
  }

  Future<void> resetAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _hasCompletedOnboarding = false;
      _themeMode = ThemeMode.system;
      _locale = const Locale('tr', 'TR');

      notifyListeners();
    } catch (e) {
      print('Failed to reset app state: $e');
    }
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}