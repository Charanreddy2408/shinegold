import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/visit.dart';
import '../../data/models/visit_form.dart';
import '../utils/media_url.dart';

/// Builds and shares a visit report PDF (answers + photos, no audio).
class VisitReportPdfService {
  VisitReportPdfService._();

  static final instance = VisitReportPdfService._();

  Future<void> download({
    required Visit visit,
    VisitFormTemplate? template,
  }) async {
    final bytes = await buildPdf(visit: visit, template: template);
    final safeFarm = visit.farmName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(visit.startedAt.toLocal());
    final name = 'visit_report_${safeFarm.isEmpty ? visit.id : safeFarm}_$stamp.pdf';

    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  Future<Uint8List> buildPdf({
    required Visit visit,
    VisitFormTemplate? template,
  }) async {
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a');
    final photoImages = await _loadPhotoImages(visit.photos);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Shine Gold · Visit Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              visit.farmName,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _sectionTitle('Visit summary'),
          _kv('Farm', visit.farmName),
          _kv('Executive', visit.executiveName),
          _kv('Status', visit.status.name),
          _kv('Check-in', dateFmt.format(visit.startedAt.toLocal())),
          if (visit.endedAt != null)
            _kv('Check-out', dateFmt.format(visit.endedAt!.toLocal())),
          _kv('Duration', _durationLabel(visit)),
          pw.SizedBox(height: 16),
          _sectionTitle('Field report'),
          if (visit.formAnswers.isEmpty &&
              (visit.textNote == null || visit.textNote!.trim().isEmpty))
            pw.Text(
              'No structured report answers were saved for this visit.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else ...[
            ...visit.formAnswers.map((a) {
              if (a.questionType == FormQuestionType.sectionHeader) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  child: pw.Text(
                    a.questionLabel,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                );
              }
              return _answerBlock(a, template);
            }),
            if (visit.textNote != null && visit.textNote!.trim().isNotEmpty)
              _answerBlock(
                FormAnswerDisplay(
                  questionKey: 'notes',
                  questionLabel: 'Additional notes',
                  questionType: FormQuestionType.textarea,
                  answer: visit.textNote,
                ),
                template,
              ),
          ],
          if (photoImages.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Photos (${photoImages.length})'),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final img in photoImages)
                  pw.Container(
                    width: 160,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  ),
              ],
            ),
          ] else if (visit.photos.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Photos (${visit.photos.length})'),
            pw.Text(
              'Photo files could not be embedded. Count: ${visit.photos.length}.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _kv(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  pw.Widget _answerBlock(
    FormAnswerDisplay answer,
    VisitFormTemplate? template,
  ) {
    if (answer.questionType == FormQuestionType.matrix) {
      final entries = answer.matrixEntries(template: template);
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              answer.questionLabel,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 6),
            if (entries.isEmpty)
              pw.Text('—', style: const pw.TextStyle(fontSize: 11))
            else
              ...entries.entries.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    '${e.key}: ${e.value}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            answer.questionLabel,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            answer.displayValue(template: template),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _durationLabel(Visit visit) {
    final mins = visit.durationMinutes;
    if (mins == null || mins <= 0) {
      if (visit.endedAt == null) return '—';
      final seconds = visit.endedAt!.difference(visit.startedAt).inSeconds;
      return _formatMinutes((seconds / 60).round());
    }
    return _formatMinutes(mins);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  Future<List<pw.MemoryImage>> _loadPhotoImages(List<String> photos) async {
    final images = <pw.MemoryImage>[];
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        responseType: ResponseType.bytes,
      ),
    );
    for (final path in photos.take(12)) {
      try {
        final url = resolveMediaUrl(path);
        final response = await dio.get<List<int>>(url);
        final bytes = response.data;
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300 &&
            bytes != null &&
            bytes.isNotEmpty) {
          images.add(pw.MemoryImage(Uint8List.fromList(bytes)));
        }
      } catch (_) {
        // Skip photos that fail to download.
      }
    }
    return images;
  }
}
