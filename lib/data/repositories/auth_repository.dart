import '../../core/network/json_helpers.dart';
import '../datasources/contracts.dart';
import '../models/password_reset_request.dart';
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

  Future<PasswordResetStatusInfo> checkPasswordResetStatus(String employeeId) =>
      _dataSource.checkPasswordResetStatus(employeeId);

  Future<PaginatedResult<PasswordResetRequestItem>> listPasswordResetRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) =>
      _dataSource.listPasswordResetRequests(
        status: status,
        page: page,
        pageSize: pageSize,
      );

  Future<void> approvePasswordReset({
    required String requestId,
  }) =>
      _dataSource.approvePasswordReset(requestId: requestId);

  Future<void> setNewPassword({
    required String employeeId,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _dataSource.setNewPassword(
        employeeId: employeeId,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

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
    double? homeLat,
    double? homeLng,
  }) =>
      _dataSource.updateProfile(
        name: name,
        address: address,
        mobileNumber: mobileNumber,
        profilePhotoUrl: profilePhotoUrl,
        homeLat: homeLat,
        homeLng: homeLng,
      );
}
