import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemePreferenceStore {
  Future<String?> readThemePreference();

  Future<void> writeThemePreference(String value);
}

class SharedPreferencesThemeStore implements ThemePreferenceStore {
  static const _themePreferenceKey = 'theme_preference';

  @override
  Future<String?> readThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themePreferenceKey);
  }

  @override
  Future<void> writeThemePreference(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, value);
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController(this._store);

  final ThemePreferenceStore _store;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final storedValue = await _store.readThemePreference();
    final storedMode = _themeModeFromStorage(storedValue);
    if (_themeMode == storedMode) return;

    _themeMode = storedMode;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
    await _store.writeThemePreference(mode.name);
  }

  ThemeMode _themeModeFromStorage(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
