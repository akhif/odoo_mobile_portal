import '../../../../core/utils/date_utils.dart';
import '../../../../core/constants/app_constants.dart';

class LeaveRequestModel {
  final int id;
  final String name;
  final int? holidayStatusId;
  final String? holidayStatusName;
  final DateTime dateFrom;
  final DateTime dateTo;
  final double numberOfDays;
  final String state;
  final String? notes;
  final int? employeeId;
  final String? employeeName;
  final DateTime? createDate;
  final List<int> attachmentIds;

  LeaveRequestModel({
    required this.id,
    required this.name,
    this.holidayStatusId,
    this.holidayStatusName,
    required this.dateFrom,
    required this.dateTo,
    required this.numberOfDays,
    required this.state,
    this.notes,
    this.employeeId,
    this.employeeName,
    this.createDate,
    this.attachmentIds = const [],
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['display_name'] as String? ?? '',
      holidayStatusId: json['holiday_status_id'] is List
          ? (json['holiday_status_id'] as List)[0] as int
          : json['holiday_status_id'] as int?,
      holidayStatusName: json['holiday_status_id'] is List && (json['holiday_status_id'] as List).length > 1
          ? (json['holiday_status_id'] as List)[1] as String
          : null,
      dateFrom: AppDateUtils.parseOdooDate(json['date_from']) ?? DateTime.now(),
      dateTo: AppDateUtils.parseOdooDate(json['date_to']) ?? DateTime.now(),
      numberOfDays: (json['number_of_days'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      employeeId: json['employee_id'] is List
          ? (json['employee_id'] as List)[0] as int
          : json['employee_id'] as int?,
      employeeName: json['employee_id'] is List && (json['employee_id'] as List).length > 1
          ? (json['employee_id'] as List)[1] as String
          : null,
      createDate: AppDateUtils.parseOdooDate(json['create_date']),
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  String get displayPeriod {
    return '${AppDateUtils.formatDisplayDate(dateFrom)} - ${AppDateUtils.formatDisplayDate(dateTo)}';
  }

  String get stateLabel {
    switch (state) {
      case AppConstants.leaveStateDraft:
        return 'To Submit';
      case AppConstants.leaveStateConfirm:
        return 'To Approve';
      case AppConstants.leaveStateRefuse:
        return 'Refused';
      case AppConstants.leaveStateValidate1:
        return 'Second Approval';
      case AppConstants.leaveStateValidate:
        return 'Approved';
      default:
        return state;
    }
  }

  bool get isPending => state == AppConstants.leaveStateDraft || state == AppConstants.leaveStateConfirm;
  bool get isApproved => state == AppConstants.leaveStateValidate;
  bool get isRefused => state == AppConstants.leaveStateRefuse;
  bool get canCancel => state == AppConstants.leaveStateDraft || state == AppConstants.leaveStateConfirm;
}

class LeaveTypeModel {
  final int id;
  final String name;
  final String? color;
  final double? maxDays;
  final bool requiresAllocation;
  final double? remainingDays;

  LeaveTypeModel({
    required this.id,
    required this.name,
    this.color,
    this.maxDays,
    this.requiresAllocation = false,
    this.remainingDays,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      maxDays: (json['max_days'] as num?)?.toDouble(),
      requiresAllocation: json['requires_allocation'] as bool? ?? false,
      remainingDays: (json['remaining_days'] as num?)?.toDouble(),
    );
  }
}
