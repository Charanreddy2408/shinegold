import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../models/password_reset_request.dart';
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
  Future<PasswordResetStatusInfo> checkPasswordResetStatus(
    String employeeId,
  ) async {
    final response = await _client.dio.get(
      ApiEndpoints.passwordResetStatus,
      queryParameters: {'employee_id': employeeId},
    );
    return PasswordResetStatusInfo.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<PaginatedResult<PasswordResetRequestItem>> listPasswordResetRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.passwordResetRequests,
      queryParameters: queryParams({
        if (status != null) 'status': status,
        'page': page,
        'page_size': pageSize,
      }),
    );
    return parsePaginated(
      response.data,
      PasswordResetRequestItem.fromJson,
    );
  }

  @override
  Future<void> approvePasswordReset({
    required String requestId,
  }) async {
    await _client.dio.post(
      ApiEndpoints.approvePasswordReset(requestId),
    );
  }

  @override
  Future<void> setNewPassword({
    required String employeeId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.dio.post(
      ApiEndpoints.setPasswordAfterReset,
      data: {
        'employee_id': employeeId,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
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
  Future<void> changeAdminPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.dio.post(
      ApiEndpoints.adminChangePassword,
      data: {
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
    double? homeLat,
    double? homeLng,
  }) async {
    final response = await _client.dio.patch(
      ApiEndpoints.usersMe,
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
        if (homeLat != null) 'home_lat': homeLat,
        if (homeLng != null) 'home_lng': homeLng,
      },
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
