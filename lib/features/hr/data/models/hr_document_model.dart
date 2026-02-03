import '../../../../core/utils/date_utils.dart';

class HrDocumentModel {
  final int id;
  final String name;
  final int? documentTypeId;
  final String? documentTypeName;
  final String? description;
  final String state;
  final int? employeeId;
  final String? employeeName;
  final DateTime? submissionDate;
  final DateTime? approvalDate;
  final List<int> attachmentIds;
  final DateTime? createDate;

  HrDocumentModel({
    required this.id,
    required this.name,
    this.documentTypeId,
    this.documentTypeName,
    this.description,
    required this.state,
    this.employeeId,
    this.employeeName,
    this.submissionDate,
    this.approvalDate,
    this.attachmentIds = const [],
    this.createDate,
  });

  factory HrDocumentModel.fromJson(Map<String, dynamic> json) {
    return HrDocumentModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      documentTypeId: json['document_type_id'] is List
          ? (json['document_type_id'] as List)[0] as int
          : json['document_type_id'] as int?,
      documentTypeName: json['document_type_id'] is List && (json['document_type_id'] as List).length > 1
          ? (json['document_type_id'] as List)[1] as String
          : null,
      description: json['description'] as String?,
      state: json['state'] as String? ?? 'requested',
      employeeId: json['employee_id'] is List
          ? (json['employee_id'] as List)[0] as int
          : json['employee_id'] as int?,
      employeeName: json['employee_id'] is List && (json['employee_id'] as List).length > 1
          ? (json['employee_id'] as List)[1] as String
          : null,
      submissionDate: AppDateUtils.parseOdooDate(json['submission_date']),
      approvalDate: AppDateUtils.parseOdooDate(json['approval_date']),
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      createDate: AppDateUtils.parseOdooDate(json['create_date']),
    );
  }

  String get stateLabel {
    switch (state) {
      case 'requested':
        return 'Requested';
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return state;
    }
  }

  bool get isRequested => state == 'requested';
  bool get isSubmitted => state == 'submitted';
  bool get isApproved => state == 'approved';
  bool get isRejected => state == 'rejected';
  bool get canSubmit => state == 'requested';
  bool get hasAttachments => attachmentIds.isNotEmpty;
}

class DocumentTypeModel {
  final int id;
  final String name;
  final String? description;
  final bool isRequired;

  DocumentTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.isRequired = false,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isRequired: json['is_required'] as bool? ?? false,
    );
  }
}
