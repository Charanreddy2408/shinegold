import '../../core/network/json_helpers.dart';
import '../models/enums.dart';
import '../models/executive.dart';
import '../models/farm.dart';
import '../models/password_reset_request.dart';
import '../models/user.dart';
import '../models/visit.dart';
import '../models/visit_form.dart';

abstract class AuthDataSource {
  Future<AuthSession> login(String employeeId, String password);
  Future<void> logout({String? refreshToken});
  Future<AuthSession> refreshSession(String refreshToken);
  Future<User> getMe();
  Future<User> setupHomeLocation({
    required double homeLat,
    required double homeLng,
    String? address,
  });
  Future<void> requestPasswordReset(String employeeId);
  Future<bool> checkPasswordResetApproved(String employeeId);
  Future<PaginatedResult<PasswordResetRequestItem>> listPasswordResetRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> approvePasswordReset({
    required String requestId,
    required String tempPassword,
  });
  Future<void> setNewPassword(String employeeId, String newPassword);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<User> updateProfile({
    String? name,
    String? address,
    String? mobileNumber,
    String? profilePhotoUrl,
  });
}

abstract class FarmDataSource {
  Future<List<Farm>> getFarms(
    FarmFilter filter, {
    double? userLat,
    double? userLng,
  });

  Future<Farm?> getFarmById(String id);

  Future<Farm> onboardFarm(
    OnboardFarmRequest request,
    String executiveId,
    String executiveName,
  );

  Future<List<FarmInvitation>> getFarmInvitations({
    double? lat,
    double? lng,
    int page = 1,
    int pageSize = 50,
  });

  Future<void> acceptFarmInvitation(String farmId);

  Future<Farm> createFarmAsAdmin(
    OnboardFarmRequest request, {
    List<String> executiveIds = const [],
  });

  Future<List<String>> assignFarmExecutives(
    String farmId, {
    required List<String> executiveIds,
    String mode = 'replace',
  });
}

abstract class VisitDataSource {
  Future<Visit> startVisit({
    required String farmId,
    required String farmName,
    required String executiveId,
    required String executiveName,
    required double latitude,
    required double longitude,
  });

  Future<Visit> submitVisit({
    required String visitId,
    required List<String> photos,
    required double checkoutLat,
    required double checkoutLng,
    String? voiceNotePath,
    String? textNote,
    Map<String, String>? mcqAnswers,
    List<FormAnswerEntry>? formAnswers,
    FarmHealthStatus? condition,
  });

  Future<void> saveVisitForm({
    required String visitId,
    List<FormAnswerEntry>? formAnswers,
    List<String>? photoPaths,
    String? voiceNotePath,
    double? capturedLat,
    double? capturedLng,
  });

  Future<Visit?> getVisitById(String visitId);

  Future<VisitFormContext> getVisitFormContext(String visitId);

  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter);

  Future<List<Visit>> getExecutiveVisits(
    String userId,
    VisitFilter filter,
  );

  Future<Visit?> getOngoingVisit(String executiveId);

  Future<void> cancelVisit(String visitId);
}

abstract class ExecutiveDataSource {
  Future<List<Executive>> list();
  Future<Executive> create(CreateExecutiveRequest request);
  Future<Executive> toggleBlock(String id);
  Future<List<Farm>> getVisitHistoryFarms(String executiveId);
}

abstract class FarmerDataSource {
  Future<List<FarmerWithFarms>> list();
  Future<FarmerWithFarms?> getById(String id);
}

abstract class HarvestDataSource {
  Future<List<Harvest>> getByMonth(DateTime month);
  Future<List<Harvest>> getAll();
}

abstract class DashboardDataSource {
  Future<DashboardStats> getStats(DashboardFilter filter);
  Future<ExecutiveDashboard> getExecutiveDashboard();
}
