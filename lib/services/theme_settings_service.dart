import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  final ThemeMode themeMode; // system, light, dark
  final int accentColorIndex;
  final int surfaceColorIndex;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.accentColorIndex = 0,
    this.surfaceColorIndex = 0,
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    int? accentColorIndex,
    int? surfaceColorIndex,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      surfaceColorIndex: surfaceColorIndex ?? this.surfaceColorIndex,
    );
  }
}

class ThemeSettingsService {
  final SharedPreferences _prefs;
  ThemeSettingsService(this._prefs);

  static const _themeModeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';
  static const _surfaceKey = 'theme_surface';

  ThemeSettings load() {
    final modeStr = _prefs.getString(_themeModeKey);
    final mode = modeStr == 'light' ? ThemeMode.light : modeStr == 'dark' ? ThemeMode.dark : ThemeMode.system;
    return ThemeSettings(
      themeMode: mode,
      accentColorIndex: _prefs.getInt(_accentKey) ?? 0,
      surfaceColorIndex: _prefs.getInt(_surfaceKey) ?? 0,
    );
  }

  Future<void> save(ThemeSettings settings) async {
    final modeStr = settings.themeMode == ThemeMode.light ? 'light' : settings.themeMode == ThemeMode.dark ? 'dark' : 'system';
    await _prefs.setString(_themeModeKey, modeStr);
    await _prefs.setInt(_accentKey, settings.accentColorIndex);
    await _prefs.setInt(_surfaceKey, settings.surfaceColorIndex);
  }
}
