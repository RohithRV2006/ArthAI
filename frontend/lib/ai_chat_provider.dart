import 'package:flutter/material.dart';
import 'package:arth/ai_service.dart';
import 'package:arth/rich_ai_models.dart';
import 'package:arth/ai_models.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/chat_history_service.dart';
import 'package:arth/app_localizations.dart';

class ActiveSession {
  String id;
  String title;
  List<RichChatMessage> messages;
  ActiveSession({required this.id, required this.title, required this.messages});
}

class AiChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final ChatHistoryService _historyService = ChatHistoryService();

  final List<ActiveSession> _sessions = [];
  String? _activeSessionId;
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  String _language = 'english';
  String? _userId;

  List<RichChatMessage> get messages {
    if (_activeSessionId == null || _sessions.isEmpty) return [];
    return List.unmodifiable(_sessions.firstWhere((s) => s.id == _activeSessionId).messages);
  }

  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  String get language => _language;

  List<ActiveSession> get filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    return _sessions.where((s) =>
    s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.messages.any((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  AppLocalizations get loc => AppLocalizations(_language);
  List<String> get quickPrompts => loc.quickPrompts;
  String get voiceLocale => _language == 'tamil' ? 'ta_IN' : 'en_IN';

  AiChatProvider() {
    _init();
  }

  Future<void> _init() async {
    _language = await LocalStorage.getLanguage();
    _userId = await LocalStorage.getUserId();
    notifyListeners();
    await _loadHistory();
  }

  Future<void> refreshForCurrentUser() async {
    final freshId = await LocalStorage.getUserId();
    if (_userId != freshId) {
      _userId = freshId;
      await _loadHistory();
    }
  }

  // ── History ───────────────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    // 🔥 THE FIX: Pass the specific User ID!
    final uid = _userId ?? 'guest';
    final localSessions = await _historyService.loadLocal(uid);
    _sessions.clear();

    if (localSessions.isNotEmpty) {
      for (var s in localSessions) {
        _sessions.add(ActiveSession(
          id: s.id,
          title: s.title,
          messages: s.messages.map((m) => RichChatMessage(text: m.text, isUser: m.isUser)).toList(),
        ));
      }
      _activeSessionId = _sessions.first.id;
    } else {
      _createNewSession();
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  void _createNewSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessions.insert(0, ActiveSession(
        id: newId,
        title: 'New Chat',
        messages: [RichChatMessage(text: loc.chatWelcome, isUser: false)]
    ));
    _activeSessionId = newId;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final uid = _userId ?? 'guest';
    final toSave = _sessions.map((s) => ChatSessionModel(
      id: s.id,
      title: s.title,
      messages: s.messages.map((m) => ChatMessage(text: m.text, isUser: m.isUser)).toList(),
    )).toList();

    // 🔥 THE FIX: Save to this specific user's folder
    await _historyService.saveLocal(uid, toSave);
  }

  void startNewChat() {
    _createNewSession();
    _persistHistory();
  }

  void switchChat(String id) {
    _activeSessionId = id;
    notifyListeners();
  }

  void searchChats(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String editMessage(int index) {
    final session = _sessions.firstWhere((s) => s.id == _activeSessionId);
    if (index < 0 || index >= session.messages.length) return '';

    final text = session.messages[index].text;
    session.messages.removeRange(index, session.messages.length);
    notifyListeners();
    _persistHistory();
    return text;
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _userId ??= await LocalStorage.getUserId();
    if (_userId == null) {
      _errorMessage = loc.errorNotLoggedIn;
      notifyListeners();
      return;
    }

    final session = _sessions.firstWhere((s) => s.id == _activeSessionId);

    if (session.messages.length == 1) {
      session.title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    }

    session.messages.add(RichChatMessage(text: text, isUser: true));

    _sessions.remove(session);
    _sessions.insert(0, session);

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String promptToSend = text;
      final lowerText = text.toLowerCase();

      final isQuestion = lowerText.contains('how much') || lowerText.contains('evvalavu') ||
          lowerText.contains('total') || lowerText.contains('tell me') || lowerText.contains('sollu') ||
          lowerText.contains('what') || lowerText.contains('enna') || lowerText.contains('epdi') ||
          lowerText.contains('summary') || lowerText.contains('balance') || lowerText.contains('savings') ||
          text.contains('?');

      if (isQuestion && session.messages.length > 1) {
        final pastMessages = session.messages.sublist(0, session.messages.length - 1);
        final chatLog = pastMessages.map((m) => '${m.isUser ? 'User' : 'Arth AI'}: ${m.text}').join('\n');

        promptToSend = '''
[SYSTEM STRICT INSTRUCTION]
The user is asking a QUESTION.
1. Do NOT trigger any functions to log expenses.
2. Answer based on conversation history and user financial data.
3. Reply in ${_language == 'tamil' ? 'Tanglish (Tamil words in English script)' : 'English'}.
--- HISTORY ---
$chatLog
---
User: "$text"
''';
      }

      final response = await _aiService.processMessage(
        userId: _userId!,
        text: promptToSend,
        language: _language,
      );

      final replyText = response.displayText.isNotEmpty ? response.displayText : loc.errorFallback;

      session.messages.add(RichChatMessage(
        text: replyText,
        isUser: false,
        richResponse: response,
      ));
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      String userMessage = loc.errorGeneral;
      if (errStr.contains('timeout')) userMessage = loc.errorTimeout;
      if (errStr.contains('socket')) userMessage = loc.errorNetwork;

      session.messages.add(RichChatMessage(text: userMessage, isUser: false));
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      await _persistHistory();
    }
  }

  void toggleLanguage() async {
    _language = _language == 'english' ? 'tamil' : 'english';
    await LocalStorage.setLanguage(_language);
    final session = _sessions.firstWhere((s) => s.id == _activeSessionId);
    session.messages.add(RichChatMessage(
      text: _language == 'tamil' ? 'Tanglish mode on! Naan ipo Tamil-la pesuven 🎉' : 'Switched to English mode!',
      isUser: false,
    ));
    notifyListeners();
  }

  void clearChat() async {
    _sessions.clear();
    _createNewSession();
    final uid = _userId ?? 'guest';
    await _historyService.clearLocal(uid); // 🔥 Clears only this user's chat
    notifyListeners();
  }
}

class RichChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final RichAiResponse? richResponse;

  RichChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.richResponse,
  }) : timestamp = timestamp ?? DateTime.now();
}