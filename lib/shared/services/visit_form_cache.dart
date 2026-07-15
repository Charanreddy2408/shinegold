import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/visit_form.dart';

/// Caches the latest visit form template JSON so the report form can be
/// filled while offline. Refreshed on every successful online fetch.
class VisitFormCache {
  VisitFormCache._();
  static final instance = VisitFormCache._();

  static const _templateKey = 'cached_visit_form_template';

  Future<void> saveTemplateJson(Map<String, dynamic> templateJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_templateKey, jsonEncode(templateJson));
    } catch (e) {
      debugPrint('VisitFormCache save failed: $e');
    }
  }

  Future<VisitFormTemplate?> loadTemplate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_templateKey);
      if (raw == null) return null;
      return VisitFormTemplate.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('VisitFormCache load failed: $e');
      return null;
    }
  }
}
