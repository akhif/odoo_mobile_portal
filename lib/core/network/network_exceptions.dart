import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'NetworkException: $message (status: $statusCode)';

  factory NetworkException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: null,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Request timeout. Please try again.',
          statusCode: null,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Server took too long to respond. Please try again.',
          statusCode: null,
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Invalid SSL certificate. Please contact support.',
          statusCode: null,
        );
      case DioExceptionType.badResponse:
        return NetworkException(
          message: _getMessageFromStatusCode(e.response?.statusCode),
          statusCode: e.response?.statusCode,
          data: e.response?.data,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled.',
          statusCode: null,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Unable to connect to server. Please check your internet connection.',
          statusCode: null,
        );
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection.',
            statusCode: null,
          );
        }
        return NetworkException(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: null,
        );
    }
  }

  static String _getMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

class SessionExpiredException implements Exception {
  final String message;

  SessionExpiredException([this.message = 'Session has expired. Please login again.']);

  @override
  String toString() => 'SessionExpiredException: $message';
}

class OdooRpcException implements Exception {
  final String message;
  final int? code;
  final dynamic data;

  OdooRpcException({
    required this.message,
    this.code,
    this.data,
  });

  @override
  String toString() => 'OdooRpcException: $message (code: $code)';

  factory OdooRpcException.fromResponse(Map<String, dynamic> error) {
    final data = error['data'];
    String message = 'Unknown Odoo error';
    int? code;

    if (data is Map) {
      message = data['message'] ?? data['name'] ?? message;
      code = data['code'];
    } else if (error['message'] != null) {
      message = error['message'];
    }

    return OdooRpcException(
      message: message,
      code: code,
      data: data,
    );
  }
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class OfflineException implements Exception {
  final String message;

  OfflineException([this.message = 'No internet connection. Please check your network settings.']);

  @override
  String toString() => 'OfflineException: $message';
}
