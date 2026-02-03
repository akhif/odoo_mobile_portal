import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  late FlutterSecureStorage _storage;

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
    const options = AndroidOptions(
      encryptedSharedPreferences: true,
    );
    _storage = const FlutterSecureStorage(aOptions: options);
  }

  // Server Configuration
  Future<void> saveServerConfig({
    required String serverUrl,
    required String database,
  }) async {
    await _storage.write(key: keyServerUrl, value: serverUrl);
    await _storage.write(key: keyDatabase, value: database);
  }

  Future<String?> getServerUrl() async {
    return await _storage.read(key: keyServerUrl);
  }

  Future<String?> getDatabase() async {
    return await _storage.read(key: keyDatabase);
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
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: keySessionId);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: keyUsername);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: keyPassword);
  }

  Future<String?> getEmployeeId() async {
    return await _storage.read(key: keyEmployeeId);
  }

  Future<String?> getEmployeeName() async {
    return await _storage.read(key: keyEmployeeName);
  }

  Future<String?> getUserRoles() async {
    return await _storage.read(key: keyUserRoles);
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
    final userId = await getUserId();
    final sessionId = await getSessionId();
    final serverUrl = await getServerUrl();
    return userId != null && sessionId != null && serverUrl != null;
  }

  // Check if server is configured
  Future<bool> hasServerConfig() async {
    final serverUrl = await getServerUrl();
    final database = await getDatabase();
    return serverUrl != null && serverUrl.isNotEmpty && database != null && database.isNotEmpty;
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
