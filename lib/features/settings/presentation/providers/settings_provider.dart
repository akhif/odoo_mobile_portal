import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences_service.dart';

// Theme provider
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(PreferencesService.instance.isDarkMode);

  void toggleTheme() {
    state = !state;
    PreferencesService.instance.setDarkMode(state);
  }

  void setDarkMode(bool value) {
    state = value;
    PreferencesService.instance.setDarkMode(value);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// App settings state
class AppSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;

  const AppSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'en',
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(AppSettings(
          darkMode: PreferencesService.instance.isDarkMode,
          notificationsEnabled: PreferencesService.instance.notificationsEnabled,
          language: PreferencesService.instance.language,
        ));

  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    PreferencesService.instance.setDarkMode(value);
  }

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    PreferencesService.instance.setNotificationsEnabled(value);
  }

  void setLanguage(String value) {
    state = state.copyWith(language: value);
    PreferencesService.instance.setLanguage(value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});
