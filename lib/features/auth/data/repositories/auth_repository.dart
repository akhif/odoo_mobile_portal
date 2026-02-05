import 'dart:convert';

import 'package:flutter/foundation.dart';

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

    // Get employee info - try multiple strategies
    int? employeeId = authResult.employeeId != null
        ? int.tryParse(authResult.employeeId!)
        : null;
    String? employeeName = authResult.employeeName;

    // If employee ID not found from auth, try to find it directly
    if (employeeId == null) {
      if (kDebugMode) {
        debugPrint('Employee ID not found from auth, trying direct lookup for user ${authResult.uid}');
      }
      try {
        // Try to find employee by user_id (use .id to get the relation ID)
        final employees = await _rpcClient.searchRead(
          model: 'hr.employee',
          domain: [
            ['user_id', '=', authResult.uid],
          ],
          fields: ['id', 'name', 'user_id'],
          limit: 1,
        );
        if (employees.isNotEmpty) {
          employeeId = employees[0]['id'] as int;
          employeeName = employees[0]['name'] as String?;
          if (kDebugMode) {
            debugPrint('Found employee: id=$employeeId, name=$employeeName');
          }
        } else {
          if (kDebugMode) {
            debugPrint('No employee found with user_id = ${authResult.uid}');
          }
        }
      } catch (e) {
        // hr.employee access denied - that's OK for portal users
        if (kDebugMode) {
          debugPrint('Employee lookup failed: $e');
        }
      }
    }

    // Also try to query using res.users employee_id field as last resort
    if (employeeId == null) {
      if (kDebugMode) {
        debugPrint('Trying employee lookup via res.users employee_id field');
      }
      try {
        final userInfo = await _rpcClient.searchRead(
          model: 'res.users',
          domain: [
            ['id', '=', authResult.uid],
          ],
          fields: ['employee_id'],
          limit: 1,
        );
        if (userInfo.isNotEmpty && userInfo[0]['employee_id'] != null) {
          // employee_id can be [id, name] tuple or just false
          final empData = userInfo[0]['employee_id'];
          if (empData is List && empData.isNotEmpty) {
            employeeId = empData[0] as int;
            if (empData.length > 1) {
              employeeName = empData[1] as String?;
            }
            if (kDebugMode) {
              debugPrint('Found employee from res.users: id=$employeeId, name=$employeeName');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('res.users employee_id lookup failed: $e');
        }
      }
    }

    // Create user model
    final user = UserModel(
      id: authResult.uid,
      username: username,
      name: authResult.name,
      employeeId: employeeId,
      employeeName: employeeName,
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
    bool hasHrAccess = false;
    bool hasSalesAccess = false;
    bool hasPurchaseAccess = false;
    bool hasProjectAccess = false;
    bool foundMobileGroups = false;

    if (kDebugMode) {
      debugPrint('Fetching user roles for groupIds: $groupIds');
    }

    // First, try to fetch groups if we have group IDs
    if (groupIds.isNotEmpty) {
      try {
        final userGroups = await _rpcClient.searchRead(
          model: AppConstants.modelGroups,
          domain: [
            ['id', 'in', groupIds],
          ],
          fields: ['name', 'full_name', 'category_id'],
        );

        if (kDebugMode) {
          debugPrint('Found ${userGroups.length} groups');
          for (final g in userGroups) {
            debugPrint('  Group: name="${g['name']}", full_name="${g['full_name']}"');
          }
        }

        for (final group in userGroups) {
          final fullName = group['full_name']?.toString().toLowerCase() ?? '';
          final name = group['name']?.toString().toLowerCase() ?? '';

          // Priority 1: Check for Mobile Portal specific groups
          // These are the groups from our custom mobile_portal Odoo module
          // Match various naming patterns: "Mobile HR Access", "Mobile Sales Access", etc.
          if (fullName.contains('mobile') || name.contains('mobile')) {
            foundMobileGroups = true;
            if (kDebugMode) {
              debugPrint('  -> Mobile group found: $name');
            }
            if (name.contains('hr') || fullName.contains('hr')) {
              hasHrAccess = true;
              if (kDebugMode) debugPrint('    -> HR access granted');
            }
            if (name.contains('sales') || fullName.contains('sales') ||
                name.contains('sale') || fullName.contains('sale')) {
              hasSalesAccess = true;
              if (kDebugMode) debugPrint('    -> Sales access granted');
            }
            if (name.contains('purchase') || fullName.contains('purchase')) {
              hasPurchaseAccess = true;
              if (kDebugMode) debugPrint('    -> Purchase access granted');
            }
            if (name.contains('project') || fullName.contains('project')) {
              hasProjectAccess = true;
              if (kDebugMode) debugPrint('    -> Project access granted');
            }
          }
        }

        // If mobile portal groups were found, use ONLY those for access control
        // Don't fall back to standard Odoo groups - mobile access should be explicit
        if (foundMobileGroups) {
          if (kDebugMode) {
            debugPrint('Using Mobile Portal groups. HR=$hasHrAccess, Sales=$hasSalesAccess, Purchase=$hasPurchaseAccess, Project=$hasProjectAccess');
          }
          return UserRoles(
            hasHrAccess: hasHrAccess,
            hasSalesAccess: hasSalesAccess,
            hasPurchaseAccess: hasPurchaseAccess,
            hasProjectAccess: hasProjectAccess,
            groupIds: groupIds,
          );
        }

        // No mobile portal groups found - fall back to standard Odoo group detection
        if (kDebugMode) {
          debugPrint('No mobile groups found, checking standard Odoo groups');
        }
        for (final group in userGroups) {
          final fullName = group['full_name']?.toString().toLowerCase() ?? '';
          final name = group['name']?.toString().toLowerCase() ?? '';

          // Check for standard Sales groups
          if (fullName.contains('sales_team.group_sale') ||
              fullName.contains('sale.group') ||
              name == 'salesman' ||
              name == 'sales manager') {
            hasSalesAccess = true;
          }

          // Check for standard Purchase groups
          if (fullName.contains('purchase.group_purchase') ||
              name == 'purchase user' ||
              name == 'purchase manager') {
            hasPurchaseAccess = true;
          }

          // Check for standard Project groups
          if (fullName.contains('project.group_project') ||
              name == 'project user' ||
              name == 'project manager') {
            hasProjectAccess = true;
          }

          // Check for standard HR groups
          if (fullName.contains('hr.group_hr') ||
              name.contains('employee') ||
              name.contains('hr user')) {
            hasHrAccess = true;
          }
        }
      } catch (e) {
        // Groups not accessible - portal users often can't read res.groups
        if (kDebugMode) {
          debugPrint('Error fetching groups: $e');
          debugPrint('Granting default HR access');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('No group IDs provided');
      }
    }

    // If no groups found at all, give HR access by default
    // (all employees should have basic HR access)
    if (!hasHrAccess && !hasSalesAccess && !hasPurchaseAccess && !hasProjectAccess) {
      hasHrAccess = true;
    }

    if (kDebugMode) {
      debugPrint('Final roles: HR=$hasHrAccess, Sales=$hasSalesAccess, Purchase=$hasPurchaseAccess, Project=$hasProjectAccess');
    }

    return UserRoles(
      hasHrAccess: hasHrAccess,
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
