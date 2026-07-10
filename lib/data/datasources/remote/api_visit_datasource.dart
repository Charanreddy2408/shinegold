import 'dart:io';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/upload_service.dart';
import '../../models/enums.dart';
import '../../models/visit.dart';
import '../../models/visit_form.dart';
import '../contracts.dart';

class ApiVisitDataSource implements VisitDataSource {
  ApiVisitDataSource(this._client, this._uploads);

  final DioClient _client;
  final UploadService _uploads;

  @override
  Future<Visit> startVisit({
    required String farmId,
    required String farmName,
    required String executiveId,
    required String executiveName,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.visitCheckin,
      data: {
        'farm_id': farmId,
        'checkin_lat': latitude,
        'checkin_lng': longitude,
      },
    );
    return Visit.fromCheckin(
      response.data as Map<String, dynamic>,
      farmName: farmName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<VisitFormContext> getVisitFormContext(String visitId) async {
    final response = await _client.dio.get(
      ApiEndpoints.visitFormContext(visitId),
    );
    return VisitFormContext.fromJson(response.data as Map<String, dynamic>);
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
    final payload = <String, dynamic>{};

    if (formAnswers != null && formAnswers.isNotEmpty) {
      payload['form_answers'] = formAnswers.map((e) => e.toJson()).toList();
    }

    if (photoPaths != null && photoPaths.isNotEmpty) {
      final now = DateTime.now().toUtc().toIso8601String();
      final lat = capturedLat ?? 0.0;
      final lng = capturedLng ?? 0.0;
      final photoEntries = <Map<String, dynamic>>[];
      for (final path in photoPaths) {
        if (path.startsWith('http')) {
          photoEntries.add({
            'photo_url': path,
            'captured_lat': lat,
            'captured_lng': lng,
            'captured_at': now,
          });
          continue;
        }
        final file = File(path);
        if (!await file.exists()) continue;
        final url = await _uploads.uploadFile(
          localPath: path,
          context: 'visit_photo',
        );
        photoEntries.add({
          'photo_url': url,
          'captured_lat': lat,
          'captured_lng': lng,
          'captured_at': now,
        });
      }
      if (photoEntries.isNotEmpty) payload['photos'] = photoEntries;
    }

    if (voiceNotePath != null && voiceNotePath.isNotEmpty) {
      if (voiceNotePath.startsWith('http')) {
        payload['voice_note_url'] = voiceNotePath;
      } else if (await File(voiceNotePath).exists()) {
        payload['voice_note_url'] = await _uploads.uploadFile(
          localPath: voiceNotePath,
          context: 'visit_voice',
        );
      }
    }

    if (payload.isEmpty) return;
    await _client.dio.patch(ApiEndpoints.visitForm(visitId), data: payload);
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
    await saveVisitForm(
      visitId: visitId,
      formAnswers: formAnswers,
      photoPaths: photos,
      voiceNotePath: voiceNotePath,
      capturedLat: checkoutLat,
      capturedLng: checkoutLng,
    );

    if (textNote != null && textNote.isNotEmpty) {
      await _client.dio.patch(
        ApiEndpoints.visitForm(visitId),
        data: {'text_note': textNote},
      );
    }

    final response = await _client.dio.post(
      ApiEndpoints.visitSubmit(visitId),
      data: {
        'checkout_lat': checkoutLat,
        'checkout_lng': checkoutLng,
      },
    );

    final submitData = response.data as Map<String, dynamic>;
    final visit = await getVisitById(visitId);
    if (visit == null) throw Exception('Visit not found after submit');
    if (visit.endedAt == null && submitData['checkout_time'] != null) {
      return visit.copyWith(
        endedAt: DateTime.parse(submitData['checkout_time'] as String),
        status: VisitStatus.completed,
      );
    }
    return visit;
  }

  @override
  Future<Visit?> getVisitById(String visitId) async {
    final response = await _client.dio.get(ApiEndpoints.visitById(visitId));
    return Visit.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Visit>> getMyVisits(
    String executiveId,
    VisitFilter filter,
  ) async {
    final params = _visitQueryParams(filter);
    final response = await _client.dio.get(
      ApiEndpoints.myVisits,
      queryParameters: params,
    );
    return parseList(response.data, Visit.fromJson);
  }

  @override
  Future<List<Visit>> getExecutiveVisits(
    String userId,
    VisitFilter filter,
  ) async {
    final params = _visitQueryParams(filter);
    final response = await _client.dio.get(
      ApiEndpoints.userVisits(userId),
      queryParameters: params,
    );
    return parseList(response.data, Visit.fromJson);
  }

  Map<String, dynamic> _visitQueryParams(VisitFilter filter) => queryParams({
        if (filter.search.isNotEmpty) 'farm_name': filter.search,
        if (filter.status != null) 'status': visitStatusToApi(filter.status!),
        if (filter.fromDate != null)
          'date_from': filter.fromDate!.toIso8601String().split('T').first,
        if (filter.toDate != null)
          'date_to': filter.toDate!.toIso8601String().split('T').first,
        'page': filter.page,
        'page_size': filter.pageSize,
      });

  @override
  Future<Visit?> getOngoingVisit(String executiveId) async {
    final visits = await getMyVisits(
      executiveId,
      const VisitFilter(status: VisitStatus.ongoing),
    );
    if (visits.isEmpty) return null;
    return visits.first;
  }

  @override
  Future<void> cancelVisit(String visitId) async {
    await _client.dio.post(ApiEndpoints.visitCancel(visitId));
  }
}
