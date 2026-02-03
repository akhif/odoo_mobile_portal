import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  late SharedPreferences _prefs;

  // Preference Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLanguage = 'language';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Preferences
  bool get isDarkMode => _prefs.getBool(keyDarkMode) ?? false;

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(keyDarkMode, value);
  }

  // First Launch Check
  bool get isFirstLaunch => _prefs.getBool(keyFirstLaunch) ?? true;

  Future<void> setFirstLaunchComplete() async {
    await _prefs.setBool(keyFirstLaunch, false);
  }

  // Last Sync Time
  DateTime? get lastSyncTime {
    final timestamp = _prefs.getInt(keyLastSyncTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setInt(keyLastSyncTime, time.millisecondsSinceEpoch);
  }

  // Notifications
  bool get notificationsEnabled => _prefs.getBool(keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(keyNotificationsEnabled, value);
  }

  // Language
  String get language => _prefs.getString(keyLanguage) ?? 'en';

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(keyLanguage, languageCode);
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
