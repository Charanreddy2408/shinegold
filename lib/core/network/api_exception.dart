import 'package:dio/dio.dart';

import 'json_helpers.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

/// Extract a user-facing message from any API / network failure.
String userFacingErrorMessage(Object error) {
  if (error is ApiException) return error.message;

  if (error is DioException) {
    final nested = error.error;
    if (nested is ApiException) return nested.message;

    if (error.response?.statusCode == 401) {
      return 'Session expired. Please sign in again.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Unable to reach the server. Check your connection and try again.';
    }

    final apiMsg = apiErrorMessage(error.response?.data);
    if (apiMsg != null && apiMsg.isNotEmpty) {
      return _polishApiMessage(apiMsg, error.response?.statusCode);
    }

    final status = error.response?.statusCode;
    if (status != null) {
      return _defaultMessageForStatus(status);
    }

    // Avoid raw "DioException [unknown]: null" in UI.
    return 'Something went wrong. Please try again.';
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

String _polishApiMessage(String message, int? statusCode) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) {
    return statusCode != null
        ? _defaultMessageForStatus(statusCode)
        : 'Something went wrong. Please try again.';
  }
  // Plain-text 500 bodies from proxies / old servers.
  if (trimmed.toLowerCase() == 'internal server error') {
    return 'Server error. Please try again in a moment.';
  }
  return trimmed;
}

String _defaultMessageForStatus(int status) {
  switch (status) {
    case 400:
      return 'Invalid request. Please check your input and try again.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'The requested resource was not found.';
    case 409:
      return 'This action conflicts with the current state. Please refresh and try again.';
    case 422:
      return 'Some fields are invalid. Please review and try again.';
    case >= 500:
      return 'Server error ($status). Please try again in a moment.';
    default:
      return 'Request failed ($status). Please try again.';
  }
}

/// Build [ApiException] from a Dio error response.
ApiException apiExceptionFromDio(DioException error) {
  final status = error.response?.statusCode;
  final message = apiErrorMessage(error.response?.data);
  return ApiException(
    message != null && message.isNotEmpty
        ? _polishApiMessage(message, status)
        : _defaultMessageForStatus(status ?? 0),
    statusCode: status,
  );
}
