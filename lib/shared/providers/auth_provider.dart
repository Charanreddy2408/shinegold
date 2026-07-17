import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../../data/models/enums.dart';
import '../../data/models/password_reset_request.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/notification_service.dart';
import 'repository_providers.dart';

const _sessionKey = 'auth_session';
const _lastEmployeeIdKey = 'last_employee_id';

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

      // Validate stored credentials; stale tokens cause blank screens after splash.
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
      } catch (_) {
        final refresh = session.refreshToken;
        if (refresh != null && refresh.isNotEmpty) {
          try {
            final refreshed = await _repository.refreshSession(refresh);
            await _persistSession(refreshed);
            state = AsyncValue.data(refreshed);
            return;
          } catch (_) {
            // Fall through to clear session.
          }
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
    final session = notifier.state.valueOrNull;
    final refresh = session?.refreshToken;
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
  dio.onAuthFailure = () => notifier.clearSession();
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
