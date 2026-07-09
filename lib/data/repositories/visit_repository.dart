import '../datasources/contracts.dart';
import '../models/enums.dart';
import '../models/visit.dart';

class VisitRepository {
  VisitRepository(this._dataSource);

  final VisitDataSource _dataSource;

  Future<Visit> startVisit({
    required String farmId,
    required String farmName,
    required String executiveId,
    required String executiveName,
    required double latitude,
    required double longitude,
  }) =>
      _dataSource.startVisit(
        farmId: farmId,
        farmName: farmName,
        executiveId: executiveId,
        executiveName: executiveName,
        latitude: latitude,
        longitude: longitude,
      );

  Future<Visit> submitVisit({
    required String visitId,
    required List<String> photos,
    required double checkoutLat,
    required double checkoutLng,
    String? voiceNotePath,
    String? textNote,
    Map<String, String>? mcqAnswers,
    FarmHealthStatus? condition,
  }) =>
      _dataSource.submitVisit(
        visitId: visitId,
        photos: photos,
        checkoutLat: checkoutLat,
        checkoutLng: checkoutLng,
        voiceNotePath: voiceNotePath,
        textNote: textNote,
        mcqAnswers: mcqAnswers,
        condition: condition,
      );

  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter) =>
      _dataSource.getMyVisits(executiveId, filter);

  Future<Visit?> getOngoingVisit(String executiveId) =>
      _dataSource.getOngoingVisit(executiveId);
}
