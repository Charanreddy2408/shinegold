import '../../../core/config/app_config.dart';
import '../../../core/network/json_helpers.dart';
import '../../models/password_reset_request.dart';
import '../../models/user.dart';
import '../contracts.dart';
import 'mock_seed_data.dart';

class MockAuthDataSource implements AuthDataSource {
  bool _passwordResetApproved = false;
  String? _pendingResetEmployeeId;
  final List<PasswordResetRequestItem> _resetRequests = [];

  @override
  Future<AuthSession> login(String employeeId, String password) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    if (password != MockSeedData.demoPassword) {
      throw Exception('Invalid employee ID or password');
    }

    if (employeeId.toUpperCase() == 'ADMIN001') {
      return AuthSession(
        token: 'mock-token-admin',
        user: MockSeedData.superAdminUser,
      );
    }

    if (employeeId.toUpperCase() == 'EXEC001' ||
        employeeId.toUpperCase() == 'EMP001') {
      return AuthSession(
        token: 'mock-token-exec',
        user: MockSeedData.executiveUser,
      );
    }

    throw Exception('Invalid employee ID or password');
  }

  @override
  Future<void> requestPasswordReset(String employeeId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    _pendingResetEmployeeId = employeeId;
    _passwordResetApproved = false;
    _resetRequests.removeWhere(
      (r) =>
          r.employeeId.toUpperCase() == employeeId.toUpperCase() &&
          r.isPending,
    );
    _resetRequests.insert(
      0,
      PasswordResetRequestItem(
        id: 'mock-reset-${_resetRequests.length + 1}',
        userId: MockSeedData.executiveUser.id,
        employeeId: employeeId,
        userName: MockSeedData.executiveUser.name,
        status: 'pending',
        requestedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> checkPasswordResetApproved(String employeeId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (_pendingResetEmployeeId?.toUpperCase() == employeeId.toUpperCase()) {
      _passwordResetApproved = true;
      return true;
    }
    return _passwordResetApproved;
  }

  @override
  Future<PaginatedResult<PasswordResetRequestItem>> listPasswordResetRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final filtered = status == null
        ? _resetRequests
        : _resetRequests.where((r) => r.status == status).toList();
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final items = start < filtered.length
        ? filtered.sublist(start, end)
        : <PasswordResetRequestItem>[];
    return PaginatedResult(
      items: items,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> approvePasswordReset({
    required String requestId,
    required String tempPassword,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (tempPassword.length < 6) {
      throw Exception('Temporary password must be at least 6 characters');
    }
    final index = _resetRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('Password reset request not found');
    }
    final item = _resetRequests[index];
    if (!item.isPending) {
      throw Exception('Password reset request is no longer pending');
    }
    _resetRequests[index] = PasswordResetRequestItem(
      id: item.id,
      userId: item.userId,
      employeeId: item.employeeId,
      userName: item.userName,
      status: 'approved',
      requestedAt: item.requestedAt,
    );
    _passwordResetApproved = true;
    _pendingResetEmployeeId = item.employeeId;
  }

  @override
  Future<void> setNewPassword(String employeeId, String newPassword) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (!_passwordResetApproved) {
      throw Exception('Password reset not yet approved by super admin');
    }
    _passwordResetApproved = false;
    _pendingResetEmployeeId = null;
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return AuthSession(
      token: 'mock-refreshed-token',
      refreshToken: refreshToken,
      user: MockSeedData.executiveUser,
    );
  }

  @override
  Future<User> getMe() async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return MockSeedData.executiveUser;
  }

  @override
  Future<User> setupHomeLocation({
    required double homeLat,
    required double homeLng,
    String? address,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return MockSeedData.executiveUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (currentPassword != MockSeedData.demoPassword) {
      throw Exception('Current password is incorrect');
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? address,
    String? mobileNumber,
    String? profilePhotoUrl,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final user = MockSeedData.executiveUser;
    return User(
      id: user.id,
      employeeId: user.employeeId,
      name: name ?? user.name,
      role: user.role,
      profilePhotoUrl: profilePhotoUrl ?? user.profilePhotoUrl,
      address: address ?? user.address,
      mobile: mobileNumber ?? user.mobile,
      homeLat: user.homeLat,
      homeLng: user.homeLng,
      farmsVisitedCount: user.farmsVisitedCount,
      onboardingCount: user.onboardingCount,
      requiresLocationSetup: user.requiresLocationSetup,
    );
  }
}
