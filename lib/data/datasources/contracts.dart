import '../models/enums.dart';
import '../models/executive.dart';
import '../models/farm.dart';
import '../models/user.dart';
import '../models/visit.dart';

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
  Future<void> setNewPassword(String employeeId, String newPassword);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
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
    FarmHealthStatus? condition,
  });

  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter);

  Future<Visit?> getOngoingVisit(String executiveId);
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
