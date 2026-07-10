import '../../../core/config/app_config.dart';
import '../../models/user.dart';
import '../contracts.dart';
import 'mock_seed_data.dart';

class MockAuthDataSource implements AuthDataSource {
  bool _passwordResetApproved = false;
  String? _pendingResetEmployeeId;

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

    if (employeeId.toUpperCase() == 'EMP001') {
      return AuthSession(
        token: 'mock-token-exec',
        user: MockSeedData.executiveUser,
      );
    }

    throw Exception('Invalid employee ID or password');
  }

  Future<void> requestPasswordReset(String employeeId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    _pendingResetEmployeeId = employeeId;
    _passwordResetApproved = false;
  }

  Future<bool> checkPasswordResetApproved(String employeeId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (_pendingResetEmployeeId?.toUpperCase() == employeeId.toUpperCase()) {
      _passwordResetApproved = true;
      return true;
    }
    return _passwordResetApproved;
  }

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
