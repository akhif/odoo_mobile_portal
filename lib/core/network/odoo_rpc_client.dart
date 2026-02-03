import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'dio_client.dart';
import 'network_exceptions.dart';

class OdooRpcClient {
  OdooRpcClient._();
  static final OdooRpcClient instance = OdooRpcClient._();

  final DioClient _dioClient = DioClient.instance;
  int _requestId = 0;

  String? _database;
  int? _uid;
  String? _password;

  int get _nextId => ++_requestId;

  Future<void> init() async {
    await _dioClient.init();
    _database = await SecureStorageService.instance.getDatabase();
    _uid = await SecureStorageService.instance.getUserId();
    _password = await SecureStorageService.instance.getPassword();
  }

  // Update credentials after login
  void updateCredentials({
    required String database,
    required int uid,
    required String password,
  }) {
    _database = database;
    _uid = uid;
    _password = password;
  }

  // Clear credentials on logout
  void clearCredentials() {
    _database = null;
    _uid = null;
    _password = null;
    _dioClient.clearSession();
  }

  // Build JSON-RPC request payload
  Map<String, dynamic> _buildRpcPayload({
    required String service,
    required String method,
    required List<dynamic> args,
  }) {
    return {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'service': service,
        'method': method,
        'args': args,
      },
      'id': _nextId,
    };
  }

  // Execute JSON-RPC call
  Future<dynamic> _rpcCall({
    required String service,
    required String method,
    required List<dynamic> args,
  }) async {
    final payload = _buildRpcPayload(
      service: service,
      method: method,
      args: args,
    );

    final response = await _dioClient.post(
      ApiConstants.jsonRpcEndpoint,
      data: payload,
    );

    final data = response.data;

    if (data['error'] != null) {
      throw OdooRpcException.fromResponse(data['error']);
    }

    return data['result'];
  }

  // Test connection to Odoo server
  Future<Map<String, dynamic>> testConnection(String serverUrl) async {
    _dioClient.updateBaseUrl(serverUrl);

    final result = await _rpcCall(
      service: ApiConstants.serviceCommon,
      method: ApiConstants.methodVersion,
      args: [],
    );

    return Map<String, dynamic>.from(result);
  }

  // Get list of databases
  Future<List<String>> getDatabaseList(String serverUrl) async {
    _dioClient.updateBaseUrl(serverUrl);

    try {
      final result = await _rpcCall(
        service: ApiConstants.serviceDb,
        method: ApiConstants.methodList,
        args: [],
      );

      return List<String>.from(result);
    } catch (e) {
      // Database list might be disabled on server
      return [];
    }
  }

  // Authenticate user
  Future<AuthResult> authenticate({
    required String serverUrl,
    required String database,
    required String username,
    required String password,
  }) async {
    _dioClient.updateBaseUrl(serverUrl);

    final result = await _rpcCall(
      service: ApiConstants.serviceCommon,
      method: ApiConstants.methodAuthenticate,
      args: [database, username, password, {}],
    );

    if (result == false) {
      throw AuthenticationException('Invalid username or password');
    }

    final uid = result as int;

    // Store credentials for future calls
    updateCredentials(
      database: database,
      uid: uid,
      password: password,
    );

    // Get user info
    final userInfo = await searchRead(
      model: 'res.users',
      domain: [
        ['id', '=', uid]
      ],
      fields: ['name', 'login', 'partner_id', 'employee_ids', 'groups_id'],
    );

    String? employeeId;
    String? employeeName;

    if (userInfo.isNotEmpty && userInfo[0]['employee_ids'] != null) {
      final employeeIds = List<int>.from(userInfo[0]['employee_ids']);
      if (employeeIds.isNotEmpty) {
        final employee = await searchRead(
          model: 'hr.employee',
          domain: [
            ['id', '=', employeeIds[0]]
          ],
          fields: ['id', 'name'],
        );
        if (employee.isNotEmpty) {
          employeeId = employee[0]['id'].toString();
          employeeName = employee[0]['name'];
        }
      }
    }

    return AuthResult(
      uid: uid,
      username: username,
      name: userInfo.isNotEmpty ? userInfo[0]['name'] : username,
      employeeId: employeeId,
      employeeName: employeeName,
      groupIds: userInfo.isNotEmpty ? List<int>.from(userInfo[0]['groups_id'] ?? []) : [],
    );
  }

  // Search and read records
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int? limit,
    int? offset,
    String? order,
  }) async {
    _ensureAuthenticated();

    final kwargs = <String, dynamic>{
      if (fields.isNotEmpty) 'fields': fields,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (order != null) 'order': order,
    };

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormSearchRead,
        [domain],
        kwargs,
      ],
    );

    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // Search record IDs
  Future<List<int>> search({
    required String model,
    List<dynamic> domain = const [],
    int? limit,
    int? offset,
    String? order,
  }) async {
    _ensureAuthenticated();

    final kwargs = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (order != null) 'order': order,
    };

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormSearch,
        [domain],
        kwargs,
      ],
    );

    return List<int>.from(result);
  }

  // Read specific records
  Future<List<Map<String, dynamic>>> read({
    required String model,
    required List<int> ids,
    List<String> fields = const [],
  }) async {
    _ensureAuthenticated();

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormRead,
        [ids],
        {'fields': fields},
      ],
    );

    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // Create a new record
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    _ensureAuthenticated();

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormCreate,
        [values],
      ],
    );

    return result as int;
  }

  // Update existing record(s)
  Future<bool> write({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    _ensureAuthenticated();

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormWrite,
        [ids, values],
      ],
    );

    return result as bool;
  }

  // Delete record(s)
  Future<bool> unlink({
    required String model,
    required List<int> ids,
  }) async {
    _ensureAuthenticated();

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormUnlink,
        [ids],
      ],
    );

    return result as bool;
  }

  // Count records
  Future<int> searchCount({
    required String model,
    List<dynamic> domain = const [],
  }) async {
    _ensureAuthenticated();

    final result = await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        ApiConstants.ormSearchCount,
        [domain],
      ],
    );

    return result as int;
  }

  // Call custom model method
  Future<dynamic> callMethod({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    _ensureAuthenticated();

    return await _rpcCall(
      service: ApiConstants.serviceObject,
      method: ApiConstants.methodExecuteKw,
      args: [
        _database,
        _uid,
        _password,
        model,
        method,
        args,
        kwargs,
      ],
    );
  }

  // Upload attachment
  Future<int> uploadAttachment({
    required String model,
    required int resId,
    required String filename,
    required Uint8List data,
    String? description,
  }) async {
    _ensureAuthenticated();

    final base64Data = base64Encode(data);

    return await create(
      model: 'ir.attachment',
      values: {
        'name': filename,
        'datas': base64Data,
        'res_model': model,
        'res_id': resId,
        if (description != null) 'description': description,
      },
    );
  }

  // Download attachment
  Future<Uint8List> downloadAttachment(int attachmentId) async {
    _ensureAuthenticated();

    final result = await read(
      model: 'ir.attachment',
      ids: [attachmentId],
      fields: ['datas'],
    );

    if (result.isEmpty || result[0]['datas'] == null) {
      throw OdooRpcException(message: 'Attachment not found');
    }

    return base64Decode(result[0]['datas']);
  }

  // Get attachment info
  Future<Map<String, dynamic>?> getAttachmentInfo(int attachmentId) async {
    _ensureAuthenticated();

    final result = await read(
      model: 'ir.attachment',
      ids: [attachmentId],
      fields: ['name', 'mimetype', 'file_size', 'create_date'],
    );

    return result.isNotEmpty ? result[0] : null;
  }

  // Call mobile API endpoint
  Future<dynamic> callMobileApi({
    required String endpoint,
    Map<String, dynamic> params = const {},
  }) async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
      'id': _nextId,
    };

    final response = await _dioClient.post(
      endpoint,
      data: payload,
    );

    final data = response.data;

    if (data['error'] != null) {
      throw OdooRpcException.fromResponse(data['error']);
    }

    return data['result'];
  }

  void _ensureAuthenticated() {
    if (_database == null || _uid == null || _password == null) {
      throw SessionExpiredException();
    }
  }
}

class AuthResult {
  final int uid;
  final String username;
  final String name;
  final String? employeeId;
  final String? employeeName;
  final List<int> groupIds;

  AuthResult({
    required this.uid,
    required this.username,
    required this.name,
    this.employeeId,
    this.employeeName,
    required this.groupIds,
  });
}
