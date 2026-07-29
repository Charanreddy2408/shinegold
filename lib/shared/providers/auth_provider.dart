import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/enums.dart';
import '../../data/models/password_reset_request.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/notification_service.dart';
import 'repository_providers.dart';

const _sessionKey = 'auth_session';
const _lastEmployeeIdKey = 'last_employee_id';

/// True only for a real 401 — everything else (offline, timeout, 5xx) must
/// leave the stored session alone.
bool _isUnauthorized(Object error) {
  if (error is ApiException) return error.isUnauthorized;
  if (error is DioException) {
    final nested = error.error;
    if (nested is ApiException) return nested.isUnauthorized;
    return error.response?.statusCode == 401;
  }
  return false;
}

class AuthNotifier extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthNotifier(this._repository, this._dio)
      : super(const AsyncValue.loading()) {
    _loadSession();
  }

  final AuthRepository _repository;
  final DioClient _dio;

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionKey);
      if (json == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final session = AuthSession.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      if (session.token.startsWith('mock-token')) {
        await prefs.remove(_sessionKey);
        state = const AsyncValue.data(null);
        return;
      }

      _dio.updateToken(session.token);
      // Trust the stored session straight away: this is an app, not a website,
      // so a cold start resumes where the user left off instead of waiting on
      // (or being logged out by) a /users/me round trip.
      state = AsyncValue.data(session);

      // Refresh the cached user in the background where possible.
      try {
        final user = await _repository.getMe();
        final valid = AuthSession(
          token: session.token,
          refreshToken: session.refreshToken,
          user: user,
        );
        await _persistSession(valid);
        state = AsyncValue.data(valid);
        return;
      } catch (e) {
        // Offline / server hiccup: keep the session and carry on.
        if (!_isUnauthorized(e)) return;
      }

      // A real 401 that survived the interceptor's refresh — try once more
      // with the stored refresh token before giving up on the session.
      final refresh = session.refreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        try {
          final refreshed = await _repository.refreshSession(refresh);
          await _persistSession(refreshed);
          state = AsyncValue.data(refreshed);
          return;
        } catch (e) {
          if (!_isUnauthorized(e)) return;
        }
      }

      await prefs.remove(_sessionKey);
      _dio.updateToken(null);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _dio.updateToken(null);
    state = const AsyncValue.data(null);
    try {
      await NotificationService.instance.clearAll();
    } catch (_) {}
  }

  Future<void> _persistSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    _dio.updateToken(session.token);
  }

  /// Refresh token straight from disk — the notifier's own state is still
  /// `loading` during startup, so the interceptor can't read it from there.
  static Future<String?> loadStoredRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_sessionKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final token = map['refreshToken'] ?? map['refresh_token'];
      return token is String && token.isNotEmpty ? token : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> loadLastEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmployeeIdKey);
  }

  static Future<void> saveLastEmployeeId(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastEmployeeIdKey, employeeId.trim());
  }

  Future<void> login(String employeeId, String password) async {
    try {
      final session = await _repository.login(employeeId, password);
      await saveLastEmployeeId(employeeId);
      await _persistSession(session);
      // Login user payload lacks stats — refresh from /users/me.
      final user = await _repository.getMe();
      final updated = AuthSession(
        token: session.token,
        refreshToken: session.refreshToken,
        user: user,
      );
      await _persistSession(updated);
      state = AsyncValue.data(updated);
    } catch (e) {
      // Keep auth unauthenticated; don't set global loading/error — that
      // redirects away from the login screen via go_router.
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.valueOrNull?.refreshToken;
    await _repository.logout(refreshToken: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _dio.updateToken(null);
    state = const AsyncValue.data(null);
    try {
      await NotificationService.instance.clearAll();
    } catch (_) {}
  }

  Future<void> requestPasswordReset(String employeeId) =>
      _repository.requestPasswordReset(employeeId);

  Future<PasswordResetStatusInfo> checkPasswordResetStatus(String employeeId) =>
      _repository.checkPasswordResetStatus(employeeId);

  Future<void> setNewPassword({
    required String employeeId,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _repository.setNewPassword(
        employeeId: employeeId,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<void> changeAdminPassword({
    required String newPassword,
    required String confirmPassword,
  }) =>
      _repository.changeAdminPassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<void> refreshUser() async {
    final session = state.valueOrNull;
    if (session == null) return;
    final user = await _repository.getMe();
    final updated = AuthSession(
      token: session.token,
      refreshToken: session.refreshToken,
      user: user,
    );
    await _persistSession(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateProfile({
    String? name,
    String? address,
    String? mobileNumber,
  }) async {
    final session = state.valueOrNull;
    if (session == null) return;

    final user = await _repository.updateProfile(
      name: name,
      address: address,
      mobileNumber: mobileNumber,
    );
    final updated = AuthSession(
      token: session.token,
      refreshToken: session.refreshToken,
      user: user,
    );
    await _persistSession(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> applyRefreshedSession(AuthSession session) async {
    await _persistSession(session);
    state = AsyncValue.data(session);
  }

  Future<void> setupHomeLocationIfNeeded({
    double? homeLat,
    double? homeLng,
  }) async {
    final session = state.valueOrNull;
    if (session == null || !session.user.requiresLocationSetup) return;

    final user = await _repository.setupHomeLocation(
      homeLat: homeLat ?? session.user.homeLat ?? 17.3850,
      homeLng: homeLng ?? session.user.homeLng ?? 78.4867,
      address: session.user.address,
    );
    final updated = AuthSession(
      token: session.token,
      refreshToken: session.refreshToken,
      user: user,
    );
    await _persistSession(updated);
    state = AsyncValue.data(updated);
  }

  /// Updates home GPS + address anytime from profile.
  Future<void> updateHomeLocation({
    required double homeLat,
    required double homeLng,
    String? address,
  }) async {
    final session = state.valueOrNull;
    if (session == null) return;

    final user = await _repository.updateProfile(
      address: address,
      homeLat: homeLat,
      homeLng: homeLng,
    );
    final updated = AuthSession(
      token: session.token,
      refreshToken: session.refreshToken,
      user: user,
    );
    await _persistSession(updated);
    state = AsyncValue.data(updated);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthSession?>>((ref) {
  final dio = ref.watch(dioClientProvider);
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    dio,
  );
  dio.onRefreshToken = () async {
    final refresh = notifier.state.valueOrNull?.refreshToken ??
        await AuthNotifier.loadStoredRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final updated =
          await ref.read(authRepositoryProvider).refreshSession(refresh);
      await notifier.applyRefreshedSession(updated);
      return updated.token;
    } catch (_) {
      return null;
    }
  };
  dio.onAuthFailure = () async {
    // Nothing left to refresh — drop the session and let the router land the
    // user on the login screen. No interstitial.
    await notifier.clearSession();
  };
  return notifier;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull?.user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});
