import 'dart:convert';

class SessionModel {
  final String serverUrl;
  final String database;
  final int userId;
  final String sessionId;
  final String username;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SessionModel({
    required this.serverUrl,
    required this.database,
    required this.userId,
    required this.sessionId,
    required this.username,
    required this.createdAt,
    this.expiresAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      serverUrl: json['server_url'] as String,
      database: json['database'] as String,
      userId: json['user_id'] as int,
      sessionId: json['session_id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_url': serverUrl,
      'database': database,
      'user_id': userId,
      'session_id': sessionId,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory SessionModel.fromJsonString(String jsonString) {
    return SessionModel.fromJson(jsonDecode(jsonString));
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class ServerConfig {
  final String serverUrl;
  final String database;
  final String? serverVersion;
  final bool isConnected;

  ServerConfig({
    required this.serverUrl,
    required this.database,
    this.serverVersion,
    this.isConnected = false,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['server_url'] as String,
      database: json['database'] as String,
      serverVersion: json['server_version'] as String?,
      isConnected: json['is_connected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_url': serverUrl,
      'database': database,
      'server_version': serverVersion,
      'is_connected': isConnected,
    };
  }

  ServerConfig copyWith({
    String? serverUrl,
    String? database,
    String? serverVersion,
    bool? isConnected,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      database: database ?? this.database,
      serverVersion: serverVersion ?? this.serverVersion,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
