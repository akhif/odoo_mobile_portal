import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'network_exceptions.dart';

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late Dio _dio;
  String? _baseUrl;
  String? _sessionId;

  Dio get dio => _dio;

  Future<void> init() async {
    _dio = Dio();

    // Get stored server URL
    _baseUrl = await SecureStorageService.instance.getServerUrl();
    _sessionId = await SecureStorageService.instance.getSessionId();

    _configureOptions();
    _configureInterceptors();
  }

  void _configureOptions() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl ?? '',
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    );
  }

  void _configureInterceptors() {
    // Clear existing interceptors
    _dio.interceptors.clear();

    // Add session interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add session cookie if available
        if (_sessionId != null && _sessionId!.isNotEmpty) {
          options.headers['Cookie'] = 'session_id=$_sessionId';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Extract and store session cookie from response
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (final cookie in cookies) {
            if (cookie.contains('session_id=')) {
              final sessionId = _extractSessionId(cookie);
              if (sessionId != null) {
                _sessionId = sessionId;
              }
            }
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // Handle session expiration
        if (error.response?.statusCode == 401) {
          // Session expired - this will be handled by the auth flow
        }
        return handler.next(error);
      },
    ));

    // Add logger in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ));
    }
  }

  String? _extractSessionId(String cookie) {
    final match = RegExp(r'session_id=([^;]+)').firstMatch(cookie);
    return match?.group(1);
  }

  // Update base URL (used when changing server)
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  // Update session ID
  void updateSessionId(String? sessionId) {
    _sessionId = sessionId;
  }

  // Clear session
  void clearSession() {
    _sessionId = null;
  }

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  // Upload file
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileName,
    Map<String, dynamic>? extraData,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        ...?extraData,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  // Download file
  Future<Response> downloadFile(
    String url,
    String savePath, {
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}
