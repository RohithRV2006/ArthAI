import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/app_strings.dart';
import 'package:provider/provider.dart';

class TranslationProvider extends ChangeNotifier {
  // ── Change this to your actual backend base URL ───────────────────────────
  static const String _baseUrl = 'http://10.132.185.222:8000';
  // ─────────────────────────────────────────────────────────────────────────

  static const _prefKeyLanguage = 'arth_app_language';
  static const _prefKeyCacheVersion = 'arth_translation_cache_v';
  // Bump this number whenever you add/remove keys in AppStrings.all
  // so users automatically get a fresh translation fetch.
  static const int _cacheVersion = 1;

  String _language = 'english';
  bool _isTranslating = false;
  String? _translationError;
  Map<String, String> _translations = {};

  String get language => _language;
  bool get isTranslating => _isTranslating;
  String? get translationError => _translationError;

  // ── Core translate function ───────────────────────────────────────────────
  /// Returns the translated string for [key], falling back to English.
  String t(String key) {
    if (_language == 'english') return AppStrings.all[key] ?? key;
    return _translations[key] ?? AppStrings.all[key] ?? key;
  }

  // ── Init: called once in main() before runApp ─────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_prefKeyLanguage) ?? 'english';

    if (_language == 'tamil') {
      await _loadFromCache(prefs);
    }
    // No notifyListeners here — init() is called before runApp, so
    // the first build always gets the correct state.
  }

  // ── Called by the language toggle in ProfileScreen ────────────────────────
  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;

    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLanguage, lang);

    if (lang == 'tamil') {
      // Try cache first; fetch from backend only if cache is stale/missing
      final loaded = await _loadFromCache(prefs);
      if (!loaded) {
        await _fetchAllTranslations();
      }
    } else {
      // Switching back to English is instant — no API call needed
      _translations = {};
      _translationError = null;
    }

    notifyListeners();
  }

  // ── Load cached Tamil translations ────────────────────────────────────────
  Future<bool> _loadFromCache(SharedPreferences prefs) async {
    final savedVersion = prefs.getInt(_prefKeyCacheVersion) ?? 0;
    if (savedVersion != _cacheVersion) {
      // Cache is from an older version — strings may have changed
      await _clearCache(prefs);
      return false;
    }

    final raw = prefs.getString('arth_translations_tamil');
    if (raw == null) return false;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _translations = decoded.map((k, v) => MapEntry(k, v.toString()));
      return _translations.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Fetch all strings from your backend one-by-one ────────────────────────
  // Your backend /translate endpoint takes a single text + target_lang.
  // We batch requests concurrently (10 at a time) to stay fast but not spam.
  Future<void> _fetchAllTranslations() async {
    _isTranslating = true;
    _translationError = null;
    notifyListeners();

    try {
      final allEntries = AppStrings.all.entries.toList();
      final Map<String, String> result = {};

      // Process in concurrent batches of 10
      const batchSize = 10;
      for (int i = 0; i < allEntries.length; i += batchSize) {
        final batch = allEntries.sublist(
          i,
          (i + batchSize) > allEntries.length ? allEntries.length : i + batchSize,
        );

        // Fire all requests in the batch concurrently
        final futures = batch.map((entry) => _translateOne(entry.value));
        final translated = await Future.wait(futures);

        for (int j = 0; j < batch.length; j++) {
          result[batch[j].key] = translated[j];
        }
      }

      _translations = result;

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arth_translations_tamil', jsonEncode(result));
      await prefs.setInt(_prefKeyCacheVersion, _cacheVersion);
    } catch (e) {
      _translationError = 'Translation failed. Using English.';
      _language = 'english'; // Graceful fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, 'english');
      debugPrint('[TranslationProvider] Error: $e');
    }

    _isTranslating = false;
    notifyListeners();
  }

  // ── Single-string translation via your backend ────────────────────────────
  Future<String> _translateOne(String text) async {
    try {
      final response = await http
          .post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'target_lang': 'tamil'}),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? text;
      }
    } catch (e) {
      debugPrint('[TranslationProvider] Failed to translate "$text": $e');
    }
    return text; // Return original if this one fails
  }

  // ── Force re-fetch (call when AppStrings.all changes in development) ──────
  Future<void> refreshTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearCache(prefs);
    if (_language == 'tamil') {
      await _fetchAllTranslations();
    }
  }

  Future<void> _clearCache(SharedPreferences prefs) async {
    await prefs.remove('arth_translations_tamil');
    await prefs.remove(_prefKeyCacheVersion);
    _translations = {};
  }
}

// ── Convenience extension ──────────────────────────────────────────────────
// Usage anywhere: context.t('home')  or  context.tr.language
extension TranslationX on BuildContext {
  TranslationProvider get tr => read<TranslationProvider>();
  String t(String key) => read<TranslationProvider>().t(key);
}