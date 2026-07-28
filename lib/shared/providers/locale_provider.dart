import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleCode = 'app_locale';
const _kLanguagePromptDone = 'language_prompt_done';

/// Supported app languages: English, Telugu, Kannada.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleCode);
    if (code == null || code.isEmpty) return;
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCode, locale.languageCode);
  }

  static Future<bool> isLanguagePromptDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLanguagePromptDone) ?? false;
  }

  static Future<void> markLanguagePromptDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLanguagePromptDone, true);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

const supportedAppLocales = [
  Locale('en'),
  Locale('te'),
  Locale('kn'),
];
