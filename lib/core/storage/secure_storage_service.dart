import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  late FlutterSecureStorage _storage;
  bool _initialized = false;

  // Storage Keys
  static const String keyServerUrl = 'server_url';
  static const String keyDatabase = 'database';
  static const String keyUserId = 'user_id';
  static const String keySessionId = 'session_id';
  static const String keyPassword = 'password';
  static const String keyUsername = 'username';
  static const String keyUserRoles = 'user_roles';
  static const String keyEmployeeId = 'employee_id';
  static const String keyEmployeeName = 'employee_name';

  Future<void> init() async {
    if (_initialized) return;

    // Note: Do NOT use encryptedSharedPreferences: true as it causes data loss on some devices
    // flutter_secure_storage already encrypts data using Android Keystore
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
    );
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    );
    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
    _initialized = true;

    // Debug: Print stored data on init
    if (kDebugMode) {
      debugPrint('SecureStorage initialized');
      final data = await getAllSessionData();
      debugPrint('Stored data: $data');
    }
  }

  // Server Configuration
  Future<void> saveServerConfig({
    required String serverUrl,
    required String database,
  }) async {
    try {
      await _storage.write(key: keyServerUrl, value: serverUrl);
      await _storage.write(key: keyDatabase, value: database);
      if (kDebugMode) {
        debugPrint('Saved server config: $serverUrl, $database');
      }
    } catch (e) {
      debugPrint('Error saving server config: $e');
      rethrow;
    }
  }

  Future<String?> getServerUrl() async {
    try {
      final value = await _storage.read(key: keyServerUrl);
      if (kDebugMode) {
        debugPrint('Read serverUrl: $value');
      }
      return value;
    } catch (e) {
      debugPrint('Error reading serverUrl: $e');
      return null;
    }
  }

  Future<String?> getDatabase() async {
    try {
      final value = await _storage.read(key: keyDatabase);
      if (kDebugMode) {
        debugPrint('Read database: $value');
      }
      return value;
    } catch (e) {
      debugPrint('Error reading database: $e');
      return null;
    }
  }

  // Session Management
  Future<void> saveSession({
    required int userId,
    required String sessionId,
    required String username,
    required String password,
    String? employeeId,
    String? employeeName,
    String? userRoles,
  }) async {
    try {
      await _storage.write(key: keyUserId, value: userId.toString());
      await _storage.write(key: keySessionId, value: sessionId);
      await _storage.write(key: keyUsername, value: username);
      await _storage.write(key: keyPassword, value: password);
      if (employeeId != null) {
        await _storage.write(key: keyEmployeeId, value: employeeId);
      }
      if (employeeName != null) {
        await _storage.write(key: keyEmployeeName, value: employeeName);
      }
      if (userRoles != null) {
        await _storage.write(key: keyUserRoles, value: userRoles);
      }
      if (kDebugMode) {
        debugPrint('Session saved for userId: $userId, username: $username');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      rethrow;
    }
  }

  Future<int?> getUserId() async {
    try {
      final value = await _storage.read(key: keyUserId);
      if (kDebugMode) {
        debugPrint('Read userId: $value');
      }
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      debugPrint('Error reading userId: $e');
      return null;
    }
  }

  Future<String?> getSessionId() async {
    try {
      return await _storage.read(key: keySessionId);
    } catch (e) {
      debugPrint('Error reading sessionId: $e');
      return null;
    }
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: keyUsername);
    } catch (e) {
      debugPrint('Error reading username: $e');
      return null;
    }
  }

  Future<String?> getPassword() async {
    try {
      return await _storage.read(key: keyPassword);
    } catch (e) {
      debugPrint('Error reading password: $e');
      return null;
    }
  }

  Future<String?> getEmployeeId() async {
    try {
      return await _storage.read(key: keyEmployeeId);
    } catch (e) {
      debugPrint('Error reading employeeId: $e');
      return null;
    }
  }

  Future<String?> getEmployeeName() async {
    try {
      return await _storage.read(key: keyEmployeeName);
    } catch (e) {
      debugPrint('Error reading employeeName: $e');
      return null;
    }
  }

  Future<String?> getUserRoles() async {
    try {
      return await _storage.read(key: keyUserRoles);
    } catch (e) {
      debugPrint('Error reading userRoles: $e');
      return null;
    }
  }

  Future<void> updateUserRoles(String roles) async {
    await _storage.write(key: keyUserRoles, value: roles);
  }

  Future<void> updateEmployeeInfo({
    required String employeeId,
    required String employeeName,
  }) async {
    await _storage.write(key: keyEmployeeId, value: employeeId);
    await _storage.write(key: keyEmployeeName, value: employeeName);
  }

  // Check if session exists
  Future<bool> hasSession() async {
    try {
      final userId = await getUserId();
      final sessionId = await getSessionId();
      final serverUrl = await getServerUrl();
      final password = await getPassword();
      final result = userId != null && sessionId != null && serverUrl != null && password != null;
      if (kDebugMode) {
        debugPrint('hasSession check: userId=$userId, sessionId=${sessionId != null}, serverUrl=${serverUrl != null}, password=${password != null} => $result');
      }
      return result;
    } catch (e) {
      debugPrint('Error checking hasSession: $e');
      return false;
    }
  }

  // Check if server is configured
  Future<bool> hasServerConfig() async {
    try {
      final serverUrl = await getServerUrl();
      final database = await getDatabase();
      final result = serverUrl != null && serverUrl.isNotEmpty && database != null && database.isNotEmpty;
      if (kDebugMode) {
        debugPrint('hasServerConfig check: serverUrl=$serverUrl, database=$database => $result');
      }
      return result;
    } catch (e) {
      debugPrint('Error checking hasServerConfig: $e');
      return false;
    }
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    await _storage.delete(key: keyUserId);
    await _storage.delete(key: keySessionId);
    await _storage.delete(key: keyPassword);
    await _storage.delete(key: keyUsername);
    await _storage.delete(key: keyUserRoles);
    await _storage.delete(key: keyEmployeeId);
    await _storage.delete(key: keyEmployeeName);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Get all session data for debugging (remove in production)
  Future<Map<String, String?>> getAllSessionData() async {
    return {
      'serverUrl': await getServerUrl(),
      'database': await getDatabase(),
      'userId': (await getUserId())?.toString(),
      'sessionId': await getSessionId(),
      'username': await getUsername(),
      'employeeId': await getEmployeeId(),
      'employeeName': await getEmployeeName(),
      'userRoles': await getUserRoles(),
    };
  }
}
