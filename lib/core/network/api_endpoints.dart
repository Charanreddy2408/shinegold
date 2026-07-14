/// Shine Gold API v1 paths (relative to [AppConfig.baseUrl]).
class ApiEndpoints {
  ApiEndpoints._();

  static const _v1 = '/api/v1';

  // Auth
  static const login = '$_v1/auth/login';
  static const logout = '$_v1/auth/logout';
  static const refresh = '$_v1/auth/refresh';
  static const authMe = '$_v1/auth/me';
  static const changePassword = '$_v1/auth/change-password';
  static const forgotPassword = '$_v1/auth/forgot-password';
  static const passwordResetRequests = '$_v1/auth/password-reset-requests';
  static const passwordResetStatus = '$_v1/auth/password-reset-requests/status';
  static String approvePasswordReset(String id) =>
      '$_v1/auth/password-reset-requests/$id/approve';

  // Uploads
  static const uploadPresign = '$_v1/uploads/presign';

  // Dashboard
  static const dashboardExecutive = '$_v1/dashboard/executive';
  static const dashboardAdmin = '$_v1/dashboard/admin';

  // Users
  static const users = '$_v1/users';
  static const usersMe = '$_v1/users/me';
  static const usersMeSetupLocation = '$_v1/users/me/setup-location';
  static String userById(String id) => '$_v1/users/$id';
  static String userVisits(String id) => '$_v1/users/$id/visits';
  static String blockUser(String id) => '$_v1/users/$id/block';

  // Farms
  static const farms = '$_v1/farms';
  static const farmsAdmin = '$_v1/farms/admin';
  static const farmInvitations = '$_v1/farms/invitations';
  static String farmById(String id) => '$_v1/farms/$id';
  static String assignFarm(String id) => '$_v1/farms/$id/assign';
  static String acceptFarm(String id) => '$_v1/farms/$id/accept';

  // Visits
  static const visitCheckin = '$_v1/visits/checkin';
  static const myVisits = '$_v1/visits/mine';
  static String visitById(String id) => '$_v1/visits/$id';
  static String visitForm(String id) => '$_v1/visits/$id/form';
  static String visitSubmit(String id) => '$_v1/visits/$id/submit';
  static String visitCancel(String id) => '$_v1/visits/$id/cancel';

  // Visit forms
  static const visitFormsActive = '$_v1/visit-forms/active';
  static String visitFormContext(String visitId) =>
      '$_v1/visit-forms/visits/$visitId/context';
  static const visitFormTemplates = '$_v1/visit-forms/templates';

  // Farmers
  static const farmers = '$_v1/farmers';
  static String farmerById(String id) => '$_v1/farmers/$id';

  // Harvests
  static const harvestsCalendar = '$_v1/harvests/calendar';
  static const harvestsReminders = '$_v1/harvests/reminders';

  static const health = '/health';
}
