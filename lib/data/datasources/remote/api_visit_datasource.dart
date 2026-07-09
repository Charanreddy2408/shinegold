import 'dart:io';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/upload_service.dart';
import '../../models/enums.dart';
import '../../models/visit.dart';
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
  Future<Visit> submitVisit({
    required String visitId,
    required List<String> photos,
    String? voiceNotePath,
    String? textNote,
    Map<String, String>? mcqAnswers,
    FarmHealthStatus? condition,
    required double checkoutLat,
    required double checkoutLng,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final photoEntries = <Map<String, dynamic>>[];

    for (final path in photos) {
      if (path.startsWith('http')) {
        photoEntries.add({
          'photo_url': path,
          'captured_lat': checkoutLat,
          'captured_lng': checkoutLng,
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
        'captured_lat': checkoutLat,
        'captured_lng': checkoutLng,
        'captured_at': now,
      });
    }

    String? voiceUrl;
    if (voiceNotePath != null && voiceNotePath.isNotEmpty) {
      if (voiceNotePath.startsWith('http')) {
        voiceUrl = voiceNotePath;
      } else if (await File(voiceNotePath).exists()) {
        voiceUrl = await _uploads.uploadFile(
          localPath: voiceNotePath,
          context: 'visit_voice',
        );
      }
    }

    final answers = <Map<String, String>>{};
    if (mcqAnswers != null) answers.addAll(mcqAnswers);
    if (condition != null) {
      answers['farm_condition'] = condition.name;
    }

    final formPayload = <String, dynamic>{};
    if (photoEntries.isNotEmpty) formPayload['photos'] = photoEntries;
    if (voiceUrl != null) formPayload['voice_note_url'] = voiceUrl;
    if (textNote != null && textNote.isNotEmpty) {
      formPayload['text_note'] = textNote;
    }
    if (answers.isNotEmpty) {
      formPayload['mcq_answers'] = answers.entries
          .map((e) => {'question_key': e.key, 'answer': e.value})
          .toList();
    }

    if (formPayload.isNotEmpty) {
      await _client.dio.patch(
        ApiEndpoints.visitForm(visitId),
        data: formPayload,
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
    final detail = await _client.dio.get(ApiEndpoints.visitById(visitId));
    final visit = Visit.fromJson(detail.data as Map<String, dynamic>);
    if (visit.endedAt == null && submitData['checkout_time'] != null) {
      return visit.copyWith(
        endedAt: DateTime.parse(submitData['checkout_time'] as String),
        status: VisitStatus.completed,
      );
    }
    return visit;
  }

  @override
  Future<List<Visit>> getMyVisits(
    String executiveId,
    VisitFilter filter,
  ) async {
    final params = queryParams({
      if (filter.search.isNotEmpty) 'farm_name': filter.search,
      if (filter.status != null) 'status': visitStatusToApi(filter.status!),
      if (filter.fromDate != null)
        'date_from': filter.fromDate!.toIso8601String().split('T').first,
      if (filter.toDate != null)
        'date_to': filter.toDate!.toIso8601String().split('T').first,
      'page': filter.page,
      'page_size': filter.pageSize,
    });

    final response = await _client.dio.get(
      ApiEndpoints.myVisits,
      queryParameters: params,
    );
    return parseList(response.data, Visit.fromJson);
  }

  @override
  Future<Visit?> getOngoingVisit(String executiveId) async {
    final visits = await getMyVisits(
      executiveId,
      const VisitFilter(status: VisitStatus.ongoing),
    );
    if (visits.isEmpty) return null;
    return visits.first;
  }
}
