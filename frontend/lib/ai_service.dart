import 'package:arth/api_client.dart';
import 'package:arth/rich_ai_models.dart';
import 'package:arth/ai_models.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final ApiClient _client = ApiClient();

  /// Send message to AI — returns rich response with financial data
  /// POST /ai/process  body: { user_id, text, language }
  Future<RichAiResponse> processMessage({
    required String userId,
    required String text,
    String language = 'english',
  }) async {
    final json = await _client.post('/ai/process', {
      'user_id': userId,
      'text': text,
      'language': language,
    });
    return RichAiResponse.fromJson(json);
  }

  /// Fetch dashboard insights
  /// GET /ai/insights/{user_id}
  Future<List<InsightModel>> getInsights(String userId,
      {String language = 'english'}) async {
    final json = await _client.get('/ai/insights/$userId');
    final List<InsightModel> results = [];

    final summary = json['summary']?.toString() ?? '';
    if (summary.isNotEmpty) {
      results.add(InsightModel(
        title: 'Financial Summary',
        description: summary.trim(),
        category: 'summary',
      ));
    }

    final insights = json['insights']?.toString() ?? '';
    if (insights.isNotEmpty) {
      results.add(InsightModel(
        title: 'AI Insights',
        description: insights.trim(),
        category: 'insights',
      ));
    }

    if (results.isEmpty && json['insights'] is List) {
      for (final e in json['insights'] as List) {
        results.add(InsightModel.fromJson(e, language: language));
      }
    }

    return results;
  }
}
