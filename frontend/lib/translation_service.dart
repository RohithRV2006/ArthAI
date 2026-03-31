import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  // 🔥 Paste your live Render URL right here!
  // It should look something like: 'https://arth-backend-xyz.onrender.com/translate'
  static const String _backendUrl = 'http://10.132.185.222:8000/translate';

  /// Translates [text] into the [targetLang] using your secure Python Backend
  static Future<String> translate(String text, String targetLang) async {
    // 1. Skip if empty or if the user wants English
    if (text.trim().isEmpty) return text;
    if (targetLang.toLowerCase() == 'english') return text;

    try {
      // 2. Send the text to your Python server on Render
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target_lang': targetLang,
        }),
      );

      // 3. Grab the Tamil text from the Python response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'];
      } else {
        debugPrint('Backend Translation Error: ${response.statusCode} - ${response.body}');
        return text; // Fallback to original text if there is a server error
      }
    } catch (e) {
      debugPrint('Translation Exception: $e');
      return text; // Fallback to original text if the phone has no internet
    }
  }
}