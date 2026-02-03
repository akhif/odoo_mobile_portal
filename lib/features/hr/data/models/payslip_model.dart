import '../../../../core/utils/date_utils.dart';

class PayslipModel {
  final int id;
  final String name;
  final String? number;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double netWage;
  final double grossWage;
  final String state;
  final int? employeeId;
  final String? employeeName;
  final int? structId;
  final String? structName;
  final String? pdfUrl;

  PayslipModel({
    required this.id,
    required this.name,
    this.number,
    this.dateFrom,
    this.dateTo,
    required this.netWage,
    required this.grossWage,
    required this.state,
    this.employeeId,
    this.employeeName,
    this.structId,
    this.structName,
    this.pdfUrl,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      number: json['number'] as String?,
      dateFrom: AppDateUtils.parseOdooDate(json['date_from']),
      dateTo: AppDateUtils.parseOdooDate(json['date_to']),
      netWage: (json['net_wage'] as num?)?.toDouble() ?? 0.0,
      grossWage: (json['gross_wage'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] as String? ?? 'draft',
      employeeId: json['employee_id'] is List
          ? (json['employee_id'] as List)[0] as int
          : json['employee_id'] as int?,
      employeeName: json['employee_id'] is List && (json['employee_id'] as List).length > 1
          ? (json['employee_id'] as List)[1] as String
          : null,
      structId: json['struct_id'] is List
          ? (json['struct_id'] as List)[0] as int
          : json['struct_id'] as int?,
      structName: json['struct_id'] is List && (json['struct_id'] as List).length > 1
          ? (json['struct_id'] as List)[1] as String
          : null,
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  String get displayPeriod {
    if (dateFrom == null || dateTo == null) return name;
    return '${AppDateUtils.formatDisplayDate(dateFrom)} - ${AppDateUtils.formatDisplayDate(dateTo)}';
  }

  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'Draft';
      case 'verify':
        return 'Waiting';
      case 'done':
        return 'Done';
      case 'cancel':
        return 'Cancelled';
      default:
        return state;
    }
  }

  bool get isDone => state == 'done';
}

class PayslipLineModel {
  final int id;
  final String name;
  final String code;
  final double amount;
  final double total;
  final int? categoryId;
  final String? categoryName;
  final int sequence;

  PayslipLineModel({
    required this.id,
    required this.name,
    required this.code,
    required this.amount,
    required this.total,
    this.categoryId,
    this.categoryName,
    required this.sequence,
  });

  factory PayslipLineModel.fromJson(Map<String, dynamic> json) {
    return PayslipLineModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['category_id'] is List
          ? (json['category_id'] as List)[0] as int
          : json['category_id'] as int?,
      categoryName: json['category_id'] is List && (json['category_id'] as List).length > 1
          ? (json['category_id'] as List)[1] as String
          : null,
      sequence: json['sequence'] as int? ?? 0,
    );
  }
}
