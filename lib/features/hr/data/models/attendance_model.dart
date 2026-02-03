import '../../../../core/utils/date_utils.dart';
import '../../../../core/constants/app_constants.dart';

class AttendanceModel {
  final int id;
  final int? employeeId;
  final String? employeeName;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double? workedHours;

  AttendanceModel({
    required this.id,
    this.employeeId,
    this.employeeName,
    required this.checkIn,
    this.checkOut,
    this.workedHours,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      employeeId: json['employee_id'] is List
          ? (json['employee_id'] as List)[0] as int
          : json['employee_id'] as int?,
      employeeName: json['employee_id'] is List && (json['employee_id'] as List).length > 1
          ? (json['employee_id'] as List)[1] as String
          : null,
      checkIn: AppDateUtils.parseOdooDate(json['check_in']) ?? DateTime.now(),
      checkOut: AppDateUtils.parseOdooDate(json['check_out']),
      workedHours: (json['worked_hours'] as num?)?.toDouble(),
    );
  }

  bool get isCheckedOut => checkOut != null;

  String get workedHoursFormatted {
    if (workedHours == null) return '-';
    final hours = workedHours!.floor();
    final minutes = ((workedHours! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  String get checkInFormatted => AppDateUtils.formatDisplayDateTime(checkIn);
  String get checkOutFormatted => checkOut != null ? AppDateUtils.formatDisplayDateTime(checkOut) : '-';
}

class RemoteAttendanceModel {
  final int id;
  final int? employeeId;
  final String? employeeName;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double latitude;
  final double longitude;
  final double? gpsAccuracy;
  final String? photoUrl;
  final String? deviceInfo;
  final bool isMockLocation;
  final String state;

  RemoteAttendanceModel({
    required this.id,
    this.employeeId,
    this.employeeName,
    required this.checkIn,
    this.checkOut,
    required this.latitude,
    required this.longitude,
    this.gpsAccuracy,
    this.photoUrl,
    this.deviceInfo,
    this.isMockLocation = false,
    required this.state,
  });

  factory RemoteAttendanceModel.fromJson(Map<String, dynamic> json) {
    return RemoteAttendanceModel(
      id: json['id'] as int,
      employeeId: json['employee_id'] is List
          ? (json['employee_id'] as List)[0] as int
          : json['employee_id'] as int?,
      employeeName: json['employee_id'] is List && (json['employee_id'] as List).length > 1
          ? (json['employee_id'] as List)[1] as String
          : null,
      checkIn: AppDateUtils.parseOdooDate(json['check_in']) ?? DateTime.now(),
      checkOut: AppDateUtils.parseOdooDate(json['check_out']),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      gpsAccuracy: (json['gps_accuracy'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      deviceInfo: json['device_info'] as String?,
      isMockLocation: json['is_mock_location'] as bool? ?? false,
      state: json['state'] as String? ?? AppConstants.attendanceStateDraft,
    );
  }

  bool get isCheckedOut => checkOut != null;

  String get stateLabel {
    switch (state) {
      case AppConstants.attendanceStateDraft:
        return 'Pending';
      case AppConstants.attendanceStateConfirmed:
        return 'Confirmed';
      case AppConstants.attendanceStateRejected:
        return 'Rejected';
      default:
        return state;
    }
  }
}
