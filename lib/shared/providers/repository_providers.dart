import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/upload_service.dart';
import '../../data/datasources/contracts.dart';
import '../../data/datasources/mock/mock_admin_datasource.dart';
import '../../data/datasources/mock/mock_auth_datasource.dart';
import '../../data/datasources/mock/mock_farm_datasource.dart';
import '../../data/datasources/mock/mock_seed_data.dart';
import '../../data/datasources/mock/mock_visit_datasource.dart';
import '../../data/datasources/remote/api_auth_datasource.dart';
import '../../data/datasources/remote/api_dashboard_datasource.dart';
import '../../data/datasources/remote/api_executive_datasource.dart';
import '../../data/datasources/remote/api_farm_datasource.dart';
import '../../data/datasources/remote/api_farmer_datasource.dart';
import '../../data/datasources/remote/api_harvest_datasource.dart';
import '../../data/datasources/remote/api_interaction_datasource.dart';
import '../../data/datasources/remote/api_visit_datasource.dart';
import '../../data/datasources/mock/mock_interaction_datasource.dart';
import '../../data/models/visit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/executive_repository.dart';
import '../../data/repositories/farm_repository.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../data/repositories/harvest_repository.dart';
import '../../data/repositories/interaction_repository.dart';
import '../../data/repositories/visit_repository.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(dioClientProvider));
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (AppConfig.useMockData) return MockAuthDataSource();
  return ApiAuthDataSource(ref.watch(dioClientProvider));
});

final farmDataSourceProvider = Provider<FarmDataSource>((ref) {
  if (AppConfig.useMockData) return MockFarmDataSource();
  return ApiFarmDataSource(
    ref.watch(dioClientProvider),
    ref.watch(uploadServiceProvider),
  );
});

final visitDataSourceProvider = Provider<VisitDataSource>((ref) {
  if (AppConfig.useMockData) {
    return MockVisitDataSource(ref.watch(farmDataSourceProvider) as MockFarmDataSource);
  }
  return ApiVisitDataSource(
    ref.watch(dioClientProvider),
    ref.watch(uploadServiceProvider),
  );
});

final executiveDataSourceProvider = Provider<ExecutiveDataSource>((ref) {
  if (AppConfig.useMockData) return MockExecutiveDataSource();
  return ApiExecutiveDataSource(ref.watch(dioClientProvider));
});

final farmerDataSourceProvider = Provider<FarmerDataSource>((ref) {
  if (AppConfig.useMockData) {
    return MockFarmerDataSource(ref.watch(farmDataSourceProvider));
  }
  return ApiFarmerDataSource(ref.watch(dioClientProvider));
});

final harvestDataSourceProvider = Provider<HarvestDataSource>((ref) {
  if (AppConfig.useMockData) return MockHarvestDataSource();
  return ApiHarvestDataSource(ref.watch(dioClientProvider));
});

final interactionDataSourceProvider = Provider<InteractionDataSource>((ref) {
  if (AppConfig.useMockData) return MockInteractionDataSource();
  return ApiInteractionDataSource(ref.watch(dioClientProvider));
});

final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  if (AppConfig.useMockData) {
    final farmDs = ref.watch(farmDataSourceProvider) as MockFarmDataSource;
    final execDs = ref.watch(executiveDataSourceProvider) as MockExecutiveDataSource;
    final visitDs = ref.watch(visitDataSourceProvider) as MockVisitDataSource;
    return MockDashboardDataSource(
      farmCount: () => farmDs.totalFarms,
      executiveCount: () => execDs.totalExecutives,
      visitCount: () => visitDs.totalVisits,
      onboardedCount: () => 8,
    );
  }
  return ApiDashboardDataSource(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authDataSourceProvider));
});

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepository(ref.watch(farmDataSourceProvider));
});

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(ref.watch(visitDataSourceProvider));
});

final executiveRepositoryProvider = Provider<ExecutiveRepository>((ref) {
  return ExecutiveRepository(ref.watch(executiveDataSourceProvider));
});

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  return FarmerRepository(ref.watch(farmerDataSourceProvider));
});

final harvestRepositoryProvider = Provider<HarvestRepository>((ref) {
  return HarvestRepository(ref.watch(harvestDataSourceProvider));
});

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(ref.watch(interactionDataSourceProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardDataSourceProvider));
});

final mcqQuestionsProvider = Provider<List<McqQuestion>>((ref) {
  return MockSeedData.mcqQuestions;
});
