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
        // Render free tier can cold-start slowly.
        connectTimeout: Duration(seconds: AppConfig.isProduction ? 60 : 30),
        receiveTimeout: Duration(seconds: AppConfig.isProduction ? 60 : 30),
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
        onRequest: (options, handler) {
          // Requests to third-party hosts (e.g. Nominatim) opt out of our
          // Authorization header — some providers reject unexpected auth.
          if (options.extra['_skipAuth'] == true) {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final refresh = onRefreshToken;
          // A 401 from an unauthenticated endpoint (wrong password on login,
          // an expired reset link) is an answer, not a dead session — it must
          // reach the calling screen instead of logging the user out.
          final isPublicAuthCall = _isPublicAuthPath(path) ||
              error.requestOptions.extra['_skipAuth'] == true;

          if (status == 401 &&
              refresh != null &&
              !isPublicAuthCall &&
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
              !isPublicAuthCall &&
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

/// Endpoints callable without a session; their 401s mean "bad credentials",
/// not "your session died".
bool _isPublicAuthPath(String path) {
  return path.contains('/auth/login') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/set-password-after-reset') ||
      path.contains('/auth/password-reset-requests/status');
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
