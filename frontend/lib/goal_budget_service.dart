import 'package:arth/api_client.dart';
import 'package:arth/goal_budget_models.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  final ApiClient _client = ApiClient();

  // ── GET /goal/{user_id} ───────────────────────────────────────────────────
  Future<List<GoalModel>> getGoals(String userId) async {
    final data = await _client.get('/goal/$userId');
    if (data is List) {
      return data.map((e) => GoalModel.fromJson(e)).toList();
    }
    return [];
  }

  // ── GET /goal/alerts/{user_id} ────────────────────────────────────────────
  Future<List<String>> getAlerts(String userId) async {
    final data = await _client.get('/goal/alerts/$userId');
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ── POST /goal/create ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createGoal({
    required String userId,
    required String goalName,
    required double targetAmount,
    required String deadline,
  }) async {
    return await _client.post('/goal/create', {
      'user_id': userId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'deadline': deadline,
    });
  }

  // ── POST /goal/add ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addMoney({
    required String userId,
    required String goalName,
    required double amount,
  }) async {
    return await _client.post('/goal/add', {
      'user_id': userId,
      'goal_name': goalName,
      'amount': amount,
    });
  }
}

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final ApiClient _client = ApiClient();

  // ── GET /budget/status/{user_id} ──────────────────────────────────────────
  Future<List<BudgetStatusModel>> getBudgetStatus(String userId) async {
    final data = await _client.get('/budget/status/$userId');
    if (data is List) {
      return data.map((e) => BudgetStatusModel.fromJson(e)).toList();
    }
    return [];
  }

  // ── GET /budget/health/{user_id} ──────────────────────────────────────────
  Future<BudgetHealthModel> getBudgetHealth(String userId) async {
    final data = await _client.get('/budget/health/$userId');
    return BudgetHealthModel.fromJson(data);
  }

  // ── GET /budget/suggest/{user_id} ─────────────────────────────────────────
  Future<List<BudgetSuggestionModel>> getSuggestions(String userId) async {
    final data = await _client.get('/budget/suggest/$userId');
    if (data is List) {
      return data.map((e) => BudgetSuggestionModel.fromJson(e)).toList();
    }
    return [];
  }

  // ── POST /budget/set ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> setBudget({
    required String userId,
    required String category,
    required double limit,
  }) async {
    return await _client.post('/budget/set', {
      'user_id': userId,
      'category': category,
      'limit': limit,
    });
  }
}
