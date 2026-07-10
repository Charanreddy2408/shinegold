import '../datasources/contracts.dart';
import '../models/enums.dart';
import '../models/visit.dart';
import '../models/visit_form.dart';

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

  Future<VisitFormContext> getVisitFormContext(String visitId) =>
      _dataSource.getVisitFormContext(visitId);

  Future<void> saveVisitForm({
    required String visitId,
    List<FormAnswerEntry>? formAnswers,
    List<String>? photoPaths,
    String? voiceNotePath,
    double? capturedLat,
    double? capturedLng,
  }) =>
      _dataSource.saveVisitForm(
        visitId: visitId,
        formAnswers: formAnswers,
        photoPaths: photoPaths,
        voiceNotePath: voiceNotePath,
        capturedLat: capturedLat,
        capturedLng: capturedLng,
      );

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
  }) =>
      _dataSource.submitVisit(
        visitId: visitId,
        photos: photos,
        checkoutLat: checkoutLat,
        checkoutLng: checkoutLng,
        voiceNotePath: voiceNotePath,
        textNote: textNote,
        mcqAnswers: mcqAnswers,
        formAnswers: formAnswers,
        condition: condition,
      );

  Future<Visit?> getVisitById(String visitId) =>
      _dataSource.getVisitById(visitId);

  Future<List<Visit>> getMyVisits(String executiveId, VisitFilter filter) =>
      _dataSource.getMyVisits(executiveId, filter);

  Future<List<Visit>> getExecutiveVisits(
    String userId,
    VisitFilter filter,
  ) =>
      _dataSource.getExecutiveVisits(userId, filter);

  Future<Visit?> getOngoingVisit(String executiveId) =>
      _dataSource.getOngoingVisit(executiveId);

  Future<void> cancelVisit(String visitId) => _dataSource.cancelVisit(visitId);
}
