import '../../../core/config/app_config.dart';
import '../../models/enums.dart';
import '../../models/farm.dart';
import '../../models/visit.dart';
import '../../models/visit_form.dart';
import '../contracts.dart';
import 'mock_farm_datasource.dart';
import 'mock_seed_data.dart';

class MockVisitDataSource implements VisitDataSource {
  MockVisitDataSource(this._farmDataSource)
      : _visits = List.of(MockSeedData.visits);

  final MockFarmDataSource _farmDataSource;
  final List<Visit> _visits;
  final Map<String, List<FormAnswerEntry>> _savedAnswers = {};

  @override
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

  @override
  Future<VisitFormContext> getVisitFormContext(String visitId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final visit = _visits.firstWhere((v) => v.id == visitId);
    final farm = await _farmDataSource.getFarmById(visit.farmId);
    return MockSeedData.mockVisitFormContext(
      executiveName: visit.executiveName,
      farmLocation: farm?.location ?? visit.farmName,
      farmerName: farm?.farmer.name ?? '—',
      checkinTime: visit.startedAt,
    );
  }

  @override
  Future<void> saveVisitForm({
    required String visitId,
    List<FormAnswerEntry>? formAnswers,
    List<String>? photoPaths,
    String? voiceNotePath,
    double? capturedLat,
    double? capturedLng,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    if (formAnswers != null) {
      _savedAnswers[visitId] = formAnswers;
    }
  }

  @override
  Future<Visit?> getVisitById(String visitId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    try {
      return _visits.firstWhere((v) => v.id == visitId);
    } catch (_) {
      return null;
    }
  }

  @override
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
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index < 0) throw Exception('Visit not found');

    final answers = formAnswers ?? _savedAnswers[visitId] ?? [];
    final actionPlan = answers
        .where((a) => a.questionKey == 'action_plan')
        .map((a) => a.answer)
        .firstOrNull;

    final visit = _visits[index].copyWith(
      endedAt: DateTime.now(),
      status: VisitStatus.completed,
      photos: photos,
      voiceNotePath: voiceNotePath,
      textNote: textNote ?? actionPlan,
      mcqAnswers: mcqAnswers ?? {},
      formAnswers: answers
          .map(
            (a) => FormAnswerDisplay(
              questionKey: a.questionKey,
              questionLabel: a.questionKey,
              questionType: FormQuestionType.text,
              answer: a.answer,
              answerJson: a.answerJson,
            ),
          )
          .toList(),
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
        report: visit.textNote ?? condition?.label,
        photoUrls: photos,
        voiceNoteUrl: voiceNotePath,
      ),
    );

    return visit;
  }

  @override
  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    var result = _visits.where((v) => v.executiveId == executiveId).toList();

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

  @override
  Future<List<Visit>> getExecutiveVisits(
    String userId,
    VisitFilter filter,
  ) =>
      getMyVisits(userId, filter);

  @override
  Future<Visit?> getOngoingVisit(String executiveId) async {
    try {
      return _visits.firstWhere(
        (v) => v.executiveId == executiveId && v.status == VisitStatus.ongoing,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelVisit(String visitId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index == -1) return;
    final visit = _visits[index];
    _visits[index] = visit.copyWith(status: VisitStatus.cancelled);
    await _farmDataSource.updateFarmStatus(visit.farmId, FarmVisitStatus.pending);
  }

  int get totalVisits =>
      _visits.where((v) => v.status == VisitStatus.completed).length;
}
