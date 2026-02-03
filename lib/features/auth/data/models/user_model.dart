import 'dart:convert';

class UserModel {
  final int id;
  final String username;
  final String name;
  final String? email;
  final int? employeeId;
  final String? employeeName;
  final UserRoles roles;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.employeeId,
    this.employeeName,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      employeeId: json['employee_id'] as int?,
      employeeName: json['employee_name'] as String?,
      roles: UserRoles.fromJson(json['roles'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'roles': roles.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString));
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    int? employeeId,
    String? employeeName,
    UserRoles? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      roles: roles ?? this.roles,
    );
  }

  String get displayName => employeeName ?? name;
}

class UserRoles {
  final bool hasHrAccess;
  final bool hasSalesAccess;
  final bool hasPurchaseAccess;
  final bool hasProjectAccess;
  final List<int> groupIds;

  UserRoles({
    this.hasHrAccess = true, // All employees have HR access
    this.hasSalesAccess = false,
    this.hasPurchaseAccess = false,
    this.hasProjectAccess = false,
    this.groupIds = const [],
  });

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      hasHrAccess: json['has_hr_access'] as bool? ?? true,
      hasSalesAccess: json['has_sales_access'] as bool? ?? false,
      hasPurchaseAccess: json['has_purchase_access'] as bool? ?? false,
      hasProjectAccess: json['has_project_access'] as bool? ?? false,
      groupIds: (json['group_ids'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_hr_access': hasHrAccess,
      'has_sales_access': hasSalesAccess,
      'has_purchase_access': hasPurchaseAccess,
      'has_project_access': hasProjectAccess,
      'group_ids': groupIds,
    };
  }

  factory UserRoles.fromGroupIds(List<int> groupIds, Map<String, int> groupMapping) {
    return UserRoles(
      hasHrAccess: true, // All employees
      hasSalesAccess: groupIds.any((id) =>
          id == groupMapping['sales_user'] || id == groupMapping['sales_manager']),
      hasPurchaseAccess: groupIds.any((id) =>
          id == groupMapping['purchase_user'] || id == groupMapping['purchase_manager']),
      hasProjectAccess: groupIds.any((id) =>
          id == groupMapping['project_user'] || id == groupMapping['project_manager']),
      groupIds: groupIds,
    );
  }

  bool get hasAnyAccess => hasHrAccess || hasSalesAccess || hasPurchaseAccess || hasProjectAccess;

  List<String> get accessibleModules {
    final modules = <String>[];
    if (hasHrAccess) modules.add('hr');
    if (hasSalesAccess) modules.add('sales');
    if (hasPurchaseAccess) modules.add('purchase');
    if (hasProjectAccess) modules.add('project');
    return modules;
  }
}
