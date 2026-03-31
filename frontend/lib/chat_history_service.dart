import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/ai_models.dart';

class ChatSessionModel {
  final String id;
  String title;
  final List<ChatMessage> messages;

  ChatSessionModel({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => {
      'text': m.text,
      'isUser': m.isUser,
    }).toList(),
  };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List).map((m) => ChatMessage(
        text: m['text'] ?? '',
        isUser: m['isUser'] ?? false,
      )).toList(),
    );
  }
}

class ChatHistoryService {
  // 🔥 THE FIX: Dynamic keys based on who is logged in!
  String _getKey(String userId) => 'arth_local_chat_sessions_$userId';

  // ── 1. Load Sessions ──────────────────────────────────────────────────────
  Future<List<ChatSessionModel>> loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_getKey(userId));

    if (data == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(data);
      return decodedList.map((item) => ChatSessionModel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── 2. Save Sessions ──────────────────────────────────────────────────────
  Future<void> saveLocal(String userId, List<ChatSessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> serializedList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_getKey(userId), jsonEncode(serializedList));
  }

  // ── 3. Clear History ──────────────────────────────────────────────────────
  Future<void> clearLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(userId));
  }

  // ── 4. Backend Sync Placeholders ──────────────────────────────────────────
  Future<List<ChatMessage>> fetchFromBackend(String userId) async {
    return [];
  }

  Future<void> syncToBackend(String userId, List<ChatMessage> messages) async {
  }
}