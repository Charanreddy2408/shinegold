import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../models/user.dart';
import '../contracts.dart';

class ApiAuthDataSource implements AuthDataSource {
  ApiAuthDataSource(this._client);

  final DioClient _client;

  @override
  Future<AuthSession> login(String employeeId, String password) async {
    final response = await _client.dio.post(
      ApiEndpoints.login,
      data: {'employee_id': employeeId, 'password': password},
    );
    return AuthSession.fromLoginResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.logout,
        data: refreshToken != null ? {'refresh_token': refreshToken} : null,
      );
    } catch (_) {}
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    final response = await _client.dio.post(
      ApiEndpoints.refresh,
      data: {'refresh_token': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    final newToken = data['access_token'] as String;
    _client.updateToken(newToken);
    final user = await getMe();
    return AuthSession(
      token: newToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  @override
  Future<User> getMe() async {
    final response = await _client.dio.get(ApiEndpoints.usersMe);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<User> setupHomeLocation({
    required double homeLat,
    required double homeLng,
    String? address,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.usersMeSetupLocation,
      data: {
        'home_lat': homeLat,
        'home_lng': homeLng,
        if (address != null) 'address': address,
      },
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> requestPasswordReset(String employeeId) async {
    await _client.dio.post(
      ApiEndpoints.forgotPassword,
      data: {'employee_id': employeeId},
    );
  }

  @override
  Future<bool> checkPasswordResetApproved(String employeeId) async {
    final response = await _client.dio.get(
      ApiEndpoints.passwordResetStatus,
      queryParameters: {'employee_id': employeeId},
    );
    final data = response.data as Map<String, dynamic>;
    return data['approved'] as bool? ?? false;
  }

  @override
  Future<void> setNewPassword(String employeeId, String newPassword) async {
    throw UnsupportedError(
      'Password reset must be approved by admin before setting a new password.',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.dio.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? address,
    String? mobileNumber,
    String? profilePhotoUrl,
  }) async {
    final response = await _client.dio.patch(
      ApiEndpoints.usersMe,
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      },
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
