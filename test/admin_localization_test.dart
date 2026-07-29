import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The admin screens were localized late: the ARB keys existed but the widgets
/// still held English literals, so switching language left half the admin in
/// English. These guard both halves of that — no literals left in the widgets,
/// and every locale carries a real translation for the keys they use.
void main() {
  final uiDirs = [
    Directory('lib/features/super_admin'),
    Directory('lib/features/executive'),
    Directory('lib/features/visits'),
  ];

  Map<String, dynamic> arb(String locale) => jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  test('screens hold no hardcoded user-facing strings', () {
    // Literals that are protocol values, formats or lookups, not UI copy.
    // Crop names are the values persisted and sent to the API — the labels the
    // user reads go through _cropLabel(). 'Farm location' is the stored
    // fallback for a farm's location field, not a rendered string.
    const allowed = {
      "'replace'",
      "'India'",
      "'pending'",
      "'approved'",
      "'rejected'",
      "'location'",
      "'Cotton'",
      "'Paddy'",
      "'Wheat'",
      "'Maize'",
      "'Groundnut'",
      "'Sugarcane'",
      "'Chilli'",
      "'Turmeric'",
      "'Vegetables'",
      "'Millets'",
      "'Other'",
      "'Farm location'",
      "'Polygon'",
      "'coordinates'",
      "'columns'",
      "'notes'",
      "'label'",
      "'audio/wav'",
      "'blob:'",
      "'local-'",
    };
    final uiLiteral = RegExp(r"'[A-Za-z][A-Za-z0-9 ,.!?·—:()/-]{4,}'");

    final offenders = <String>[];
    for (final file in uiDirs
        .expand((d) => d.listSync(recursive: true))
        .whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') ||
            trimmed.startsWith('import ') ||
            line.contains('context.l10n') ||
            line.contains('RegExp(') ||
            line.contains('DateFormat(')) {
          continue;
        }
        for (final match in uiLiteral.allMatches(line)) {
          if (allowed.contains(match.group(0))) continue;
          offenders.add('${file.path}:${i + 1}  ${match.group(0)}');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'Move these into the ARB files:\n'
        '${offenders.join('\n')}');
  });

  test('every English key is translated in Telugu and Kannada', () {
    final en = arb('en');
    final te = arb('te');
    final kn = arb('kn');

    final keys = en.keys.where((k) => !k.startsWith('@')).toList();

    final missing = <String>[];
    final untranslated = <String>[];
    for (final key in keys) {
      for (final entry in {'te': te, 'kn': kn}.entries) {
        final value = entry.value[key];
        if (value == null) {
          missing.add('${entry.key}: $key');
        } else if (value == en[key] && !_sharedAcrossLocales.contains(key)) {
          untranslated.add('${entry.key}: $key');
        }
      }
    }

    expect(missing, isEmpty, reason: 'Keys absent from a locale');
    expect(untranslated, isEmpty, reason: 'Keys left in English');
  });
}

/// Names and codes that are deliberately identical in every locale.
const _sharedAcrossLocales = {
  'english',
  'telugu',
  'kannada',
  'employeeIdHint',
  'whatsapp',
  'ok',
  'pdfLabel',
};
