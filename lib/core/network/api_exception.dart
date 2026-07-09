import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// User-readable message from API / network failures.
String userFacingErrorMessage(Object error) {
  if (error is ApiException) return error.message;

  if (error is DioException) {
    final nested = error.error;
    if (nested is ApiException) return nested.message;
    if (nested is ApiException && nested.isUnauthorized) {
      return 'Session expired. Please sign in again.';
    }
    if (error.response?.statusCode == 401) {
      return 'Session expired. Please sign in again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Unable to reach the server. Check your connection and try again.';
    }
    return error.message ?? 'Something went wrong. Please try again.';
  }

  final text = error.toString();
  return text
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiException: ', '');
}

/// Maps API failures to UI copy — only treats real 401s as session expiry.
String formatApiError(Object error) {
  if (error is DioException && error.error is ApiException) {
    final api = error.error as ApiException;
    if (api.isUnauthorized) {
      return 'Session expired. Please sign in again.';
    }
    return api.message;
  }
  if (error is ApiException) {
    if (error.isUnauthorized) {
      return 'Session expired. Please sign in again.';
    }
    return error.message;
  }
  return userFacingErrorMessage(error);
}
