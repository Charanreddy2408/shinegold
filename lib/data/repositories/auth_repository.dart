import '../datasources/contracts.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._dataSource);

  final AuthDataSource _dataSource;

  Future<AuthSession> login(String employeeId, String password) =>
      _dataSource.login(employeeId, password);

  Future<void> logout({String? refreshToken}) =>
      _dataSource.logout(refreshToken: refreshToken);

  Future<AuthSession> refreshSession(String refreshToken) =>
      _dataSource.refreshSession(refreshToken);

  Future<User> getMe() => _dataSource.getMe();

  Future<User> setupHomeLocation({
    required double homeLat,
    required double homeLng,
    String? address,
  }) =>
      _dataSource.setupHomeLocation(
        homeLat: homeLat,
        homeLng: homeLng,
        address: address,
      );

  Future<void> requestPasswordReset(String employeeId) =>
      _dataSource.requestPasswordReset(employeeId);

  Future<bool> checkPasswordResetApproved(String employeeId) =>
      _dataSource.checkPasswordResetApproved(employeeId);

  Future<void> setNewPassword(String employeeId, String newPassword) =>
      _dataSource.setNewPassword(employeeId, newPassword);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<User> updateProfile({
    String? name,
    String? address,
    String? mobileNumber,
    String? profilePhotoUrl,
  }) =>
      _dataSource.updateProfile(
        name: name,
        address: address,
        mobileNumber: mobileNumber,
        profilePhotoUrl: profilePhotoUrl,
      );
}
