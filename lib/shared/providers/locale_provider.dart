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

  /// Last known value of the prompt flag, so the go_router redirect (which is
  /// synchronous) can gate on it. `null` until the first read.
  static bool? _promptDoneCache;

  static bool? get languagePromptDoneCached => _promptDoneCache;

  static Future<bool> isLanguagePromptDone() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kLanguagePromptDone) ?? false;
    _promptDoneCache = done;
    return done;
  }

  static Future<void> markLanguagePromptDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLanguagePromptDone, true);
    _promptDoneCache = true;
  }

  /// Cleared on a deliberate logout so the next sign-in asks for the language
  /// again. The chosen locale itself is kept — only the prompt is re-armed.
  static Future<void> resetLanguagePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLanguagePromptDone);
    _promptDoneCache = false;
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

const supportedAppLocales = [
  Locale('en'),
  Locale('te'),
  Locale('kn'),
];
