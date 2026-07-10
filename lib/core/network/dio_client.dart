import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'json_helpers.dart';

typedef TokenRefreshCallback = Future<String?> Function();
typedef AuthFailureCallback = Future<void> Function();

class DioClient {
  DioClient({String? token}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final refresh = onRefreshToken;

          if (status == 401 &&
              refresh != null &&
              !path.contains('/auth/login') &&
              !path.contains('/auth/refresh') &&
              error.requestOptions.extra['_authRetried'] != true &&
              !_refreshing) {
            _refreshing = true;
            try {
              final newToken = await refresh();
              if (newToken != null && newToken.isNotEmpty) {
                updateToken(newToken);
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                opts.extra['_authRetried'] = true;
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
              // Fall through.
            } finally {
              _refreshing = false;
            }
          }

          if (status == 401 &&
              onAuthFailure != null &&
              !_authFailureHandled) {
            _authFailureHandled = true;
            await onAuthFailure!();
            _authFailureHandled = false;
          }

          final message = apiErrorMessage(error.response?.data);
          final apiEx = ApiException(
            message != null && message.isNotEmpty
                ? message
                : (error.response?.statusCode != null
                    ? 'Request failed (${error.response!.statusCode})'
                    : 'Network error'),
            statusCode: status,
          );
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: apiEx,
            ),
          );
        },
      ),
    );
  }

  late final Dio _dio;
  TokenRefreshCallback? onRefreshToken;
  AuthFailureCallback? onAuthFailure;
  bool _refreshing = false;
  bool _authFailureHandled = false;

  Dio get dio => _dio;

  void updateToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
