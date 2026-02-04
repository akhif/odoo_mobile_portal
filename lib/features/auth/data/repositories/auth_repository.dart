import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final OdooRpcClient _rpcClient;
  final SecureStorageService _storage;

  AuthRepository({
    OdooRpcClient? rpcClient,
    SecureStorageService? storage,
  })  : _rpcClient = rpcClient ?? OdooRpcClient.instance,
        _storage = storage ?? SecureStorageService.instance;

  // Test connection to server
  Future<ServerConfig> testConnection(String serverUrl) async {
    try {
      final result = await _rpcClient.testConnection(serverUrl);
      final version = result['server_version'] ?? 'Unknown';

      return ServerConfig(
        serverUrl: serverUrl,
        database: '',
        serverVersion: version.toString(),
        isConnected: true,
      );
    } catch (e) {
      throw NetworkException(
        message: 'Unable to connect to server. Please check the URL.',
      );
    }
  }

  // Get available databases
  Future<List<String>> getDatabases(String serverUrl) async {
    return await _rpcClient.getDatabaseList(serverUrl);
  }

  // Authenticate user
  Future<UserModel> login({
    required String serverUrl,
    required String database,
    required String username,
    required String password,
  }) async {
    // Authenticate with Odoo
    final authResult = await _rpcClient.authenticate(
      serverUrl: serverUrl,
      database: database,
      username: username,
      password: password,
    );

    // Get user roles based on groups
    final roles = await _fetchUserRoles(authResult.groupIds);

    // Create user model
    final user = UserModel(
      id: authResult.uid,
      username: username,
      name: authResult.name,
      employeeId: authResult.employeeId != null
          ? int.tryParse(authResult.employeeId!)
          : null,
      employeeName: authResult.employeeName,
      roles: roles,
    );

    // Save session
    await _saveSession(
      serverUrl: serverUrl,
      database: database,
      userId: authResult.uid,
      username: username,
      password: password,
      user: user,
    );

    return user;
  }

  // Fetch user roles based on group IDs
  Future<UserRoles> _fetchUserRoles(List<int> groupIds) async {
    bool hasSalesAccess = false;
    bool hasPurchaseAccess = false;
    bool hasProjectAccess = false;

    // First, try to fetch groups if we have group IDs
    if (groupIds.isNotEmpty) {
      try {
        final mobileGroups = await _rpcClient.searchRead(
          model: AppConstants.modelGroups,
          domain: [
            ['id', 'in', groupIds],
          ],
          fields: ['name', 'full_name'],
        );

        for (final group in mobileGroups) {
          final fullName = group['full_name']?.toString().toLowerCase() ?? '';
          final name = group['name']?.toString().toLowerCase() ?? '';

          // Check for sales access
          if (fullName.contains('sales') ||
              name.contains('sales') ||
              name.contains('salesman') ||
              name.contains('salesperson') ||
              fullName.contains('sale_salesman') ||
              fullName.contains('sale_manager') ||
              fullName.contains('account.group_account')) {
            hasSalesAccess = true;
          }

          // Check for purchase access
          if (fullName.contains('purchase') || name.contains('purchase')) {
            hasPurchaseAccess = true;
          }

          // Check for project access
          if (fullName.contains('project') || name.contains('project')) {
            hasProjectAccess = true;
          }
        }
      } catch (_) {
        // Groups not accessible, try model access detection below
      }
    }

    // If we couldn't determine roles from groups, try model access detection
    // This is useful for portal users who can't read res.groups
    if (!hasSalesAccess && !hasPurchaseAccess && !hasProjectAccess) {
      // Try to detect sales access by checking if user can read invoices
      try {
        await _rpcClient.searchRead(
          model: AppConstants.modelInvoice,
          domain: [
            ['move_type', '=', 'out_invoice'],
          ],
          fields: ['id'],
          limit: 1,
        );
        hasSalesAccess = true;
      } catch (_) {
        // No sales access
      }

      // Try to detect purchase access by checking if user can read purchase orders
      try {
        await _rpcClient.searchRead(
          model: 'purchase.order',
          domain: [],
          fields: ['id'],
          limit: 1,
        );
        hasPurchaseAccess = true;
      } catch (_) {
        // No purchase access
      }

      // Try to detect project access by checking if user can read projects/tasks
      try {
        await _rpcClient.searchRead(
          model: 'project.task',
          domain: [],
          fields: ['id'],
          limit: 1,
        );
        hasProjectAccess = true;
      } catch (_) {
        // No project access
      }
    }

    return UserRoles(
      hasHrAccess: true, // All employees have HR access
      hasSalesAccess: hasSalesAccess,
      hasPurchaseAccess: hasPurchaseAccess,
      hasProjectAccess: hasProjectAccess,
      groupIds: groupIds,
    );
  }

  // Save session to secure storage
  Future<void> _saveSession({
    required String serverUrl,
    required String database,
    required int userId,
    required String username,
    required String password,
    required UserModel user,
  }) async {
    await _storage.saveServerConfig(
      serverUrl: serverUrl,
      database: database,
    );

    await _storage.saveSession(
      userId: userId,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      employeeId: user.employeeId?.toString(),
      employeeName: user.employeeName,
      userRoles: jsonEncode(user.roles.toJson()),
    );
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.hasSession();
  }

  // Check if server is configured
  Future<bool> hasServerConfig() async {
    return await _storage.hasServerConfig();
  }

  // Get stored server config
  Future<ServerConfig?> getStoredServerConfig() async {
    final serverUrl = await _storage.getServerUrl();
    final database = await _storage.getDatabase();

    if (serverUrl == null || database == null) return null;

    return ServerConfig(
      serverUrl: serverUrl,
      database: database,
    );
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final userId = await _storage.getUserId();
    final username = await _storage.getUsername();
    final employeeName = await _storage.getEmployeeName();
    final employeeId = await _storage.getEmployeeId();
    final rolesJson = await _storage.getUserRoles();

    if (userId == null || username == null) return null;

    UserRoles roles;
    if (rolesJson != null) {
      roles = UserRoles.fromJson(jsonDecode(rolesJson));
    } else {
      roles = UserRoles(hasHrAccess: true);
    }

    return UserModel(
      id: userId,
      username: username,
      name: employeeName ?? username,
      employeeId: employeeId != null ? int.tryParse(employeeId) : null,
      employeeName: employeeName,
      roles: roles,
    );
  }

  // Restore credentials from storage (without re-authenticating)
  // This is used for fast app startup
  Future<void> restoreCredentialsFromStorage() async {
    final serverUrl = await _storage.getServerUrl();
    final database = await _storage.getDatabase();
    final userId = await _storage.getUserId();
    final password = await _storage.getPassword();

    if (serverUrl != null && database != null && userId != null && password != null) {
      // Use the method that also sets the server URL to ensure DioClient is configured
      _rpcClient.updateCredentialsWithServer(
        serverUrl: serverUrl,
        database: database,
        uid: userId,
        password: password,
      );
    }
  }

  // Restore session (re-authenticate with stored credentials)
  Future<UserModel?> restoreSession() async {
    final serverUrl = await _storage.getServerUrl();
    final database = await _storage.getDatabase();
    final username = await _storage.getUsername();
    final password = await _storage.getPassword();

    if (serverUrl == null ||
        database == null ||
        username == null ||
        password == null) {
      return null;
    }

    try {
      return await login(
        serverUrl: serverUrl,
        database: database,
        username: username,
        password: password,
      );
    } catch (e) {
      // Return cached user if re-auth fails
      return await getCurrentUser();
    }
  }

  // Logout
  Future<void> logout() async {
    _rpcClient.clearCredentials();
    await _storage.clearSession();
  }

  // Clear all data (including server config)
  Future<void> clearAllData() async {
    _rpcClient.clearCredentials();
    await _storage.clearAll();
  }

  // Update server config
  Future<void> updateServerConfig({
    required String serverUrl,
    required String database,
  }) async {
    await _storage.saveServerConfig(
      serverUrl: serverUrl,
      database: database,
    );
  }
}
