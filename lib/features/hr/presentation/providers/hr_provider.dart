import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attendance_model.dart';
import '../../data/models/hr_document_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/payslip_model.dart';
import '../../data/repositories/hr_repository.dart';

// Repository provider
final hrRepositoryProvider = Provider<HrRepository>((ref) {
  return HrRepository();
});

// ==================== PAYSLIPS ====================

final payslipsProvider = FutureProvider.autoDispose<List<PayslipModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getPayslips();
});

final payslipDetailProvider =
    FutureProvider.autoDispose.family<PayslipModel?, int>((ref, id) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getPayslip(id);
});

final payslipLinesProvider =
    FutureProvider.autoDispose.family<List<PayslipLineModel>, int>((ref, payslipId) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getPayslipLines(payslipId);
});

// ==================== LEAVE REQUESTS ====================

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveTypeModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getLeaveTypes();
});

final leaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getLeaveRequests();
});

final vacationRequestsProvider = FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getLeaveRequests(vacationOnly: true);
});

// Leave request state
class LeaveRequestState {
  final bool isLoading;
  final String? error;
  final int? createdId;

  const LeaveRequestState({
    this.isLoading = false,
    this.error,
    this.createdId,
  });

  LeaveRequestState copyWith({
    bool? isLoading,
    String? error,
    int? createdId,
  }) {
    return LeaveRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdId: createdId ?? this.createdId,
    );
  }
}

class LeaveRequestNotifier extends StateNotifier<LeaveRequestState> {
  final HrRepository _repository;

  LeaveRequestNotifier(this._repository) : super(const LeaveRequestState());

  Future<bool> createLeaveRequest({
    required int holidayStatusId,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final id = await _repository.createLeaveRequest(
        holidayStatusId: holidayStatusId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        notes: notes,
      );

      state = state.copyWith(isLoading: false, createdId: id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelLeaveRequest(int leaveId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.cancelLeaveRequest(leaveId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const LeaveRequestState();
  }
}

final leaveRequestNotifierProvider =
    StateNotifierProvider<LeaveRequestNotifier, LeaveRequestState>((ref) {
  final repository = ref.watch(hrRepositoryProvider);
  return LeaveRequestNotifier(repository);
});

// ==================== ATTENDANCE ====================

final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getAttendanceHistory();
});

final currentAttendanceProvider =
    FutureProvider.autoDispose<AttendanceModel?>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getCurrentAttendance();
});

// Attendance state
class AttendanceState {
  final bool isLoading;
  final String? error;
  final bool? success;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.success,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final HrRepository _repository;

  AttendanceNotifier(this._repository) : super(const AttendanceState());

  Future<bool> checkIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    required Uint8List photo,
    required String deviceInfo,
    required bool isMockLocation,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: null);

    try {
      await _repository.createRemoteAttendance(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        photo: photo,
        deviceInfo: deviceInfo,
        isMockLocation: isMockLocation,
        isCheckOut: false,
      );

      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> checkOut({
    required double latitude,
    required double longitude,
    required double accuracy,
    required Uint8List photo,
    required String deviceInfo,
    required bool isMockLocation,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: null);

    try {
      await _repository.createRemoteAttendance(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        photo: photo,
        deviceInfo: deviceInfo,
        isMockLocation: isMockLocation,
        isCheckOut: true,
      );

      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const AttendanceState();
  }
}

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final repository = ref.watch(hrRepositoryProvider);
  return AttendanceNotifier(repository);
});

// ==================== HR DOCUMENTS ====================

final hrDocumentsProvider = FutureProvider.autoDispose<List<HrDocumentModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getHrDocuments();
});

final documentTypesProvider = FutureProvider.autoDispose<List<DocumentTypeModel>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return await repository.getDocumentTypes();
});
