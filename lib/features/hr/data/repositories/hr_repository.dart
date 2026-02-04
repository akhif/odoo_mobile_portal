import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../models/attendance_model.dart';
import '../models/hr_document_model.dart';
import '../models/leave_request_model.dart';
import '../models/payslip_model.dart';

class HrRepository {
  final OdooRpcClient _rpcClient;
  final SecureStorageService _storage;

  HrRepository({
    OdooRpcClient? rpcClient,
    SecureStorageService? storage,
  })  : _rpcClient = rpcClient ?? OdooRpcClient.instance,
        _storage = storage ?? SecureStorageService.instance;

  Future<int?> get _employeeId async {
    final id = await _storage.getEmployeeId();
    if (id != null) {
      final parsed = int.tryParse(id);
      if (parsed != null) return parsed;
    }
    // Try to find employee by user_id
    return await _findEmployeeByUserId();
  }

  Future<int?> get _userId async {
    return await _storage.getUserId();
  }

  // Helper to find employee record by user_id
  Future<int?> _findEmployeeByUserId() async {
    final userId = await _userId;
    if (userId == null) return null;

    try {
      final result = await _rpcClient.searchRead(
        model: 'hr.employee',
        domain: [
          ['user_id', '=', userId],
        ],
        fields: ['id', 'name'],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final empId = result[0]['id'] as int;
        // Cache the employee ID for future use
        await _storage.updateEmployeeInfo(
          employeeId: empId.toString(),
          employeeName: result[0]['name']?.toString() ?? '',
        );
        return empId;
      }
    } catch (_) {
      // Employee lookup failed
    }
    return null;
  }

  // ==================== PAYSLIPS ====================

  Future<List<PayslipModel>> getPayslips({
    int limit = 20,
    int offset = 0,
  }) async {
    final employeeId = await _employeeId;
    if (employeeId == null) return [];

    final result = await _rpcClient.searchRead(
      model: AppConstants.modelPayslip,
      domain: [
        ['employee_id', '=', employeeId],
        ['state', 'in', ['done', 'verify']],
      ],
      fields: [
        'name',
        'number',
        'date_from',
        'date_to',
        'net_wage',
        'gross_wage',
        'state',
        'employee_id',
        'struct_id',
      ],
      limit: limit,
      offset: offset,
      order: 'date_from desc',
    );

    return result.map((json) => PayslipModel.fromJson(json)).toList();
  }

  Future<PayslipModel?> getPayslip(int id) async {
    final result = await _rpcClient.read(
      model: AppConstants.modelPayslip,
      ids: [id],
      fields: [
        'name',
        'number',
        'date_from',
        'date_to',
        'net_wage',
        'gross_wage',
        'state',
        'employee_id',
        'struct_id',
      ],
    );

    return result.isNotEmpty ? PayslipModel.fromJson(result[0]) : null;
  }

  Future<List<PayslipLineModel>> getPayslipLines(int payslipId) async {
    final result = await _rpcClient.searchRead(
      model: 'hr.payslip.line',
      domain: [
        ['slip_id', '=', payslipId]
      ],
      fields: ['name', 'code', 'amount', 'total', 'category_id', 'sequence'],
      order: 'sequence',
    );

    return result.map((json) => PayslipLineModel.fromJson(json)).toList();
  }

  Future<Uint8List?> getPayslipPdf(int payslipId) async {
    try {
      // Get report action
      final result = await _rpcClient.callMethod(
        model: AppConstants.modelPayslip,
        method: 'action_print_payslip',
        args: [
          [payslipId]
        ],
      );

      if (result != null && result['report_type'] == 'qweb-pdf') {
        // Download the PDF
        final attachments = await _rpcClient.searchRead(
          model: AppConstants.modelAttachment,
          domain: [
            ['res_model', '=', AppConstants.modelPayslip],
            ['res_id', '=', payslipId],
          ],
          fields: ['datas'],
          limit: 1,
          order: 'create_date desc',
        );

        if (attachments.isNotEmpty && attachments[0]['datas'] != null) {
          return await _rpcClient.downloadAttachment(attachments[0]['id']);
        }
      }
    } catch (e) {
      // Fallback: try to get any PDF attachment
    }
    return null;
  }

  // ==================== LEAVE REQUESTS ====================

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    try {
      // Try with basic fields that should exist in all Odoo versions
      final result = await _rpcClient.searchRead(
        model: AppConstants.modelLeaveType,
        domain: [
          ['active', '=', true],
        ],
        fields: ['name', 'color'],
      );

      return result.map((json) => LeaveTypeModel.fromJson(json)).toList();
    } catch (e) {
      // Fallback: try without domain filter
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelLeaveType,
          domain: [],
          fields: ['name'],
        );
        return result.map((json) => LeaveTypeModel.fromJson(json)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<LeaveRequestModel>> getLeaveRequests({
    int limit = 20,
    int offset = 0,
    bool vacationOnly = false,
  }) async {
    final employeeId = await _employeeId;
    final userId = await _userId;

    // Try with employee_id first
    if (employeeId != null) {
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelLeave,
          domain: [
            ['employee_id', '=', employeeId],
          ],
          fields: [
            'name',
            'display_name',
            'holiday_status_id',
            'date_from',
            'date_to',
            'number_of_days',
            'state',
            'notes',
            'employee_id',
            'create_date',
            'attachment_ids',
          ],
          limit: limit,
          offset: offset,
          order: 'create_date desc',
        );

        if (result.isNotEmpty) {
          return result.map((json) => LeaveRequestModel.fromJson(json)).toList();
        }
      } catch (_) {
        // Try fallback
      }
    }

    // Fallback: try to query by user_id
    if (userId != null) {
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelLeave,
          domain: [
            ['user_id', '=', userId],
          ],
          fields: [
            'name',
            'display_name',
            'holiday_status_id',
            'date_from',
            'date_to',
            'number_of_days',
            'state',
            'notes',
            'employee_id',
            'create_date',
            'attachment_ids',
          ],
          limit: limit,
          offset: offset,
          order: 'create_date desc',
        );

        return result.map((json) => LeaveRequestModel.fromJson(json)).toList();
      } catch (_) {
        // user_id field might not exist
      }
    }

    // Final fallback: try without filter (will return all user's leaves if access rights permit)
    if (userId != null) {
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelLeave,
          domain: [],
          fields: [
            'name',
            'display_name',
            'holiday_status_id',
            'date_from',
            'date_to',
            'number_of_days',
            'state',
            'notes',
            'employee_id',
            'create_date',
            'attachment_ids',
          ],
          limit: limit,
          offset: offset,
          order: 'create_date desc',
        );

        return result.map((json) => LeaveRequestModel.fromJson(json)).toList();
      } catch (_) {
        // No access
      }
    }

    return [];
  }

  Future<int> createLeaveRequest({
    required int holidayStatusId,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? notes,
  }) async {
    final employeeId = await _employeeId;
    if (employeeId == null) throw Exception('Employee ID not found');

    return await _rpcClient.create(
      model: AppConstants.modelLeave,
      values: {
        'holiday_status_id': holidayStatusId,
        'employee_id': employeeId,
        'date_from': AppDateUtils.toOdooDateTime(dateFrom),
        'date_to': AppDateUtils.toOdooDateTime(dateTo),
        'notes': notes,
        'request_date_from': AppDateUtils.toOdooDate(dateFrom),
        'request_date_to': AppDateUtils.toOdooDate(dateTo),
      },
    );
  }

  Future<bool> cancelLeaveRequest(int leaveId) async {
    return await _rpcClient.callMethod(
      model: AppConstants.modelLeave,
      method: 'action_refuse',
      args: [
        [leaveId]
      ],
    );
  }

  // ==================== ATTENDANCE ====================

  Future<List<AttendanceModel>> getAttendanceHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final employeeId = await _employeeId;
    if (employeeId == null) {
      throw Exception('Employee ID not found. Please contact your administrator to link your user account to an employee record.');
    }

    final result = await _rpcClient.searchRead(
      model: AppConstants.modelAttendance,
      domain: [
        ['employee_id', '=', employeeId]
      ],
      fields: ['id', 'employee_id', 'check_in', 'check_out', 'worked_hours'],
      limit: limit,
      offset: offset,
      order: 'check_in desc',
    );

    return result.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  Future<AttendanceModel?> getCurrentAttendance() async {
    final employeeId = await _employeeId;
    if (employeeId == null) {
      throw Exception('Employee ID not found');
    }

    final result = await _rpcClient.searchRead(
      model: AppConstants.modelAttendance,
      domain: [
        ['employee_id', '=', employeeId],
        ['check_out', '=', false],
      ],
      fields: ['id', 'employee_id', 'check_in', 'check_out', 'worked_hours'],
      limit: 1,
      order: 'check_in desc',
    );

    return result.isNotEmpty ? AttendanceModel.fromJson(result[0]) : null;
  }

  Future<int> createRemoteAttendance({
    required double latitude,
    required double longitude,
    required double accuracy,
    required Uint8List photo,
    required String deviceInfo,
    required bool isMockLocation,
    bool isCheckOut = false,
  }) async {
    final employeeId = await _employeeId;
    if (employeeId == null) {
      throw Exception('Employee ID not found. Please contact your administrator to link your user account to an employee record.');
    }

    final now = DateTime.now();

    // First, try using custom hr.remote.attendance model
    try {
      return await _rpcClient.create(
        model: AppConstants.modelRemoteAttendance,
        values: {
          'employee_id': employeeId,
          isCheckOut ? 'check_out' : 'check_in': AppDateUtils.toOdooDateTime(now),
          'latitude': latitude,
          'longitude': longitude,
          'gps_accuracy': accuracy,
          'device_info': deviceInfo,
          'is_mock_location': isMockLocation,
          'state': 'draft',
        },
      );
    } catch (_) {
      // Fallback to standard hr.attendance model
    }

    // Fallback: Use standard hr.attendance model
    if (isCheckOut) {
      // For check-out, find the open attendance and update it
      final currentAttendance = await getCurrentAttendance();
      if (currentAttendance != null) {
        await _rpcClient.write(
          model: AppConstants.modelAttendance,
          ids: [currentAttendance.id],
          values: {
            'check_out': AppDateUtils.toOdooDateTime(now),
          },
        );
        return currentAttendance.id;
      } else {
        throw Exception('No open attendance record found to check out');
      }
    } else {
      // For check-in, create a new attendance record
      return await _rpcClient.create(
        model: AppConstants.modelAttendance,
        values: {
          'employee_id': employeeId,
          'check_in': AppDateUtils.toOdooDateTime(now),
        },
      );
    }
  }

  // ==================== HR DOCUMENTS ====================

  Future<List<HrDocumentModel>> getHrDocuments({
    int limit = 20,
    int offset = 0,
  }) async {
    final employeeId = await _employeeId;
    if (employeeId == null) return [];

    final result = await _rpcClient.searchRead(
      model: AppConstants.modelEmployeeDocument,
      domain: [
        ['employee_id', '=', employeeId]
      ],
      fields: [
        'name',
        'document_type_id',
        'description',
        'state',
        'employee_id',
        'submission_date',
        'approval_date',
        'attachment_ids',
        'create_date',
      ],
      limit: limit,
      offset: offset,
      order: 'create_date desc',
    );

    return result.map((json) => HrDocumentModel.fromJson(json)).toList();
  }

  Future<int> uploadDocument({
    required int documentId,
    required String filename,
    required Uint8List data,
  }) async {
    // Upload attachment
    final attachmentId = await _rpcClient.uploadAttachment(
      model: AppConstants.modelEmployeeDocument,
      resId: documentId,
      filename: filename,
      data: data,
    );

    // Update document state
    await _rpcClient.write(
      model: AppConstants.modelEmployeeDocument,
      ids: [documentId],
      values: {
        'state': 'submitted',
        'submission_date': AppDateUtils.toOdooDateTime(DateTime.now()),
      },
    );

    return attachmentId;
  }

  Future<List<DocumentTypeModel>> getDocumentTypes() async {
    final result = await _rpcClient.searchRead(
      model: 'hr.document.type',
      domain: [],
      fields: ['name', 'description', 'is_required'],
    );

    return result.map((json) => DocumentTypeModel.fromJson(json)).toList();
  }
}
