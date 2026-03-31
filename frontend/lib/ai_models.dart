import 'package:arth/app_localizations.dart';

class AiResponse {
  final String displayText;
  final bool isDataSaved;
  final Map<String, dynamic>? metadata;

  AiResponse({
    required this.displayText,
    this.isDataSaved = false,
    this.metadata,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json,
      {String language = 'english'}) {
    final loc = AppLocalizations(language);
    final type = json['type'] as String? ?? '';
    String text = '';
    bool saved = false;

    // ── multi_data_saved ─────────────────────────────────────────────────
    if (type == 'multi_data_saved') {
      saved = true;
      final txns = json['transactions'];
      if (txns is List && txns.isNotEmpty) {
        final lines = txns.map((t) {
          final intent = t['intent']?.toString() ?? 'transaction';
          final amount = t['amount']?.toString() ?? '';
          final category = t['category']?.toString() ?? '';
          final alert = t['alert']?.toString() ?? '';
          String line = loc.recordedTransaction(intent, amount, category);
          if (alert.isNotEmpty) line += ' ⚠️ $alert';
          return line;
        }).join('\n');
        text = lines;
      } else {
        text = loc.dataSaved;
      }
    }

    // ── data_saved ───────────────────────────────────────────────────────
    else if (type == 'data_saved') {
      saved = true;
      final details = json['details'];
      if (details is Map) {
        final intent = details['intent']?.toString() ?? 'transaction';
        final amount = details['amount']?.toString() ?? '';
        final category = details['category']?.toString() ?? '';
        text = loc.recordedTransaction(intent, amount, category);
      } else {
        text = loc.dataSaved;
      }
    }

    // ── insight / query ──────────────────────────────────────────────────
    // Backend returns: { "type": "insight", "response": { "insight": "..." } }
    else if (type == 'insight' || type == 'query') {
      final raw = json['response'];
      if (raw is Map) {
        text = raw['insight']?.toString() ??
            raw['message']?.toString() ??
            raw['text']?.toString() ??
            raw['summary']?.toString() ??
            (raw.values.whereType<String>().firstOrNull ?? '');
      } else if (raw is String) {
        text = raw;
      }
      // Top-level fallbacks
      if (text.isEmpty) {
        text = json['insight']?.toString() ??
            json['insights']?.toString() ??
            json['summary']?.toString() ??
            json['message']?.toString() ??
            '';
      }
    }

    // ── summary+insights (from /ai/insights endpoint) ────────────────────
    else if (json.containsKey('summary') || json.containsKey('insights')) {
      text = json['insights']?.toString() ??
          json['summary']?.toString() ??
          '';
    }

    // ── error ────────────────────────────────────────────────────────────
    else if (type == 'error') {
      text = json['message']?.toString() ?? loc.errorGeneral;
    }

    // ── fallback ─────────────────────────────────────────────────────────
    else {
      final raw = json['response'];
      if (raw is Map) {
        text = raw['insight']?.toString() ??
            raw['message']?.toString() ??
            (raw.values.whereType<String>().firstOrNull ?? '');
      } else if (raw is String) {
        text = raw;
      }
      if (text.isEmpty) {
        text = json['message']?.toString() ??
            json['insights']?.toString() ??
            json['summary']?.toString() ??
            'Done!';
      }
    }

    return AiResponse(
      displayText: text.trim(),
      isDataSaved: saved,
      metadata: json,
    );
  }
}

class InsightModel {
  final String title;
  final String description;
  final String? category;

  InsightModel({
    required this.title,
    required this.description,
    this.category,
  });

  factory InsightModel.fromJson(Map<String, dynamic> json,
      {String language = 'english'}) {
    final loc = AppLocalizations(language);

    if (json.containsKey('insights') || json.containsKey('summary')) {
      return InsightModel(
        title: loc.aiInsightsCard,
        description: json['insights']?.toString() ??
            json['summary']?.toString() ??
            '',
        category: 'general',
      );
    }
    return InsightModel(
      title: json['title']?.toString() ?? 'Insight',
      description: json['description']?.toString() ??
          json['response']?.toString() ??
          '',
      category: json['category']?.toString(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AiResponse? aiResponse;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.aiResponse,
  }) : timestamp = timestamp ?? DateTime.now();

  // ── JSON serialization for chat history persistence ───────────────────────
  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text']?.toString() ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
