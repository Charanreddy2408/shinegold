import 'enums.dart';

class User {
  const User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
    this.profilePhotoUrl,
    this.address,
    this.mobile,
    this.homeLat,
    this.homeLng,
    this.requiresLocationSetup = false,
    this.farmsVisitedCount = 0,
    this.onboardingCount = 0,
  });

  final String id;
  final String employeeId;
  final String name;
  final UserRole role;
  final String? profilePhotoUrl;
  final String? address;
  final String? mobile;
  final double? homeLat;
  final double? homeLng;
  final bool requiresLocationSetup;
  final int farmsVisitedCount;
  final int onboardingCount;

  factory User.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'];
    return User(
      id: json['id'].toString(),
      employeeId: json['employee_id'] as String,
      name: json['name'] as String,
      role: json['role'] is String
          ? _parseRole(json['role'] as String)
          : UserRole.executive,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      address: json['address'] as String?,
      mobile: json['mobile'] as String? ?? json['mobile_number'] as String?,
      homeLat: (json['home_lat'] as num?)?.toDouble(),
      homeLng: (json['home_lng'] as num?)?.toDouble(),
      requiresLocationSetup: json['requires_location_setup'] as bool? ?? false,
      farmsVisitedCount: stats is Map
          ? stats['total_farms_visited'] as int? ?? 0
          : json['farms_visited_count'] as int? ??
              json['total_farms_visited'] as int? ??
              0,
      onboardingCount: stats is Map
          ? stats['onboarding_farms_count'] as int? ?? 0
          : json['onboarding_count'] as int? ??
              json['onboarding_farms_count'] as int? ??
              0,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'executive':
        return UserRole.executive;
      default:
        return UserRole.values.byName(role);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'name': name,
        'role': role == UserRole.superAdmin ? 'super_admin' : role.name,
        'profile_photo_url': profilePhotoUrl,
        'address': address,
        'mobile': mobile,
        'farms_visited_count': farmsVisitedCount,
        'onboarding_count': onboardingCount,
      };

  User copyWith({
    String? name,
    String? address,
    String? profilePhotoUrl,
    int? farmsVisitedCount,
    int? onboardingCount,
  }) =>
      User(
        id: id,
        employeeId: employeeId,
        name: name ?? this.name,
        role: role,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        address: address ?? this.address,
        mobile: mobile,
        farmsVisitedCount: farmsVisitedCount ?? this.farmsVisitedCount,
        onboardingCount: onboardingCount ?? this.onboardingCount,
      );
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  final String token;
  final String? refreshToken;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String? ??
            json['access_token'] as String? ??
            '',
        refreshToken: json['refresh_token'] as String?,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  factory AuthSession.fromLoginResponse(Map<String, dynamic> json) =>
      AuthSession(
        token: json['access_token'] as String? ?? json['token'] as String,
        refreshToken: json['refresh_token'] as String?,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'access_token': token,
        if (refreshToken != null) 'refresh_token': refreshToken,
        'user': user.toJson(),
      };
}
