import '../../../core/config/app_config.dart';
import '../../models/enums.dart';
import '../../models/farm.dart';
import '../../models/visit.dart';
import '../contracts.dart';
import 'mock_farm_datasource.dart';
import 'mock_seed_data.dart';

class MockVisitDataSource implements VisitDataSource {
  MockVisitDataSource(this._farmDataSource)
      : _visits = List.of(MockSeedData.visits);

  final MockFarmDataSource _farmDataSource;
  final List<Visit> _visits;

  Future<Visit> startVisit({
    required String farmId,
    required String farmName,
    required String executiveId,
    required String executiveName,
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    final visit = Visit(
      id: 'visit-${DateTime.now().millisecondsSinceEpoch}',
      farmId: farmId,
      farmName: farmName,
      executiveId: executiveId,
      executiveName: executiveName,
      startedAt: DateTime.now(),
      status: VisitStatus.ongoing,
      latitude: latitude,
      longitude: longitude,
    );

    _visits.add(visit);
    await _farmDataSource.updateFarmStatus(farmId, FarmVisitStatus.ongoing);
    return visit;
  }

  Future<Visit> submitVisit({
    required String visitId,
    required List<String> photos,
    required double checkoutLat,
    required double checkoutLng,
    String? voiceNotePath,
    String? textNote,
    Map<String, String>? mcqAnswers,
    FarmHealthStatus? condition,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index < 0) throw Exception('Visit not found');

    final visit = _visits[index].copyWith(
      endedAt: DateTime.now(),
      status: VisitStatus.completed,
      photos: photos,
      voiceNotePath: voiceNotePath,
      textNote: textNote,
      mcqAnswers: mcqAnswers ?? {},
      condition: condition,
      syncStatus: SyncStatus.synced,
    );

    _visits[index] = visit;

    await _farmDataSource.addVisitLog(
      visit.farmId,
      VisitLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        farmId: visit.farmId,
        date: visit.endedAt!,
        durationMinutes: visit.durationMinutes ?? 0,
        visitedBy: visit.executiveName,
        report: textNote ?? condition?.label,
        photoUrls: photos,
        voiceNoteUrl: voiceNotePath,
      ),
    );

    return visit;
  }

  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    var result =
        _visits.where((v) => v.executiveId == executiveId).toList();

    if (filter.status != null) {
      result = result.where((v) => v.status == filter.status).toList();
    }

    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      result =
          result.where((v) => v.farmName.toLowerCase().contains(q)).toList();
    }

    if (filter.fromDate != null) {
      result = result
          .where((v) => !v.startedAt.isBefore(filter.fromDate!))
          .toList();
    }

    if (filter.toDate != null) {
      result = result
          .where((v) => !v.startedAt.isAfter(filter.toDate!))
          .toList();
    }

    result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return result;
  }

  Future<Visit?> getOngoingVisit(String executiveId) async {
    try {
      return _visits.firstWhere(
        (v) => v.executiveId == executiveId && v.status == VisitStatus.ongoing,
      );
    } catch (_) {
      return null;
    }
  }

  int get totalVisits =>
      _visits.where((v) => v.status == VisitStatus.completed).length;
}
