import 'package:arth/api_client.dart';
import 'package:arth/local_storage.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiClient _client = ApiClient();

  // Helper: load language from stored UserModel
  Future<String> _getLanguage() async {
    final user = await LocalStorage.loadUser();
    return user?.language ?? 'english'; // 🔥 now works — UserModel has language
  }

  // GET /alerts/{user_id}?language=...
  Future<List<AlertModel>> getAlerts(String userId) async {
    try {
      final language = await _getLanguage();
      final data = await _client.get('/alerts/$userId?language=$language');
      if (data is List) {
        return data.map((e) => AlertModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET /budget/status/{user_id} — no language needed (numbers only)
  Future<List<BudgetStatusItem>> getBudgetStatus(String userId) async {
    try {
      final data = await _client.get('/budget/status/$userId');
      if (data is List) {
        return data.map((e) => BudgetStatusItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET /goals/{user_id} — no language needed (numbers only)
  Future<List<GoalSnapshot>> getGoals(String userId) async {
    try {
      final data = await _client.get('/goals/$userId');
      if (data is List) {
        return data.map((e) => GoalSnapshot.fromJson(e)).toList();
      }
      final data2 = await _client.get('/goal/$userId');
      if (data2 is List) {
        return data2.map((e) => GoalSnapshot.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET /behavior/{user_id}?language=...  ← AI text, needs language
  Future<List<BehaviorInsight>> getBehavior(String userId) async {
    try {
      final language = await _getLanguage();
      final data = await _client.get('/behavior/$userId?language=$language');
      if (data is List) {
        return data.map((e) => BehaviorInsight.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET /ai/insights/{user_id}?language=...  ← AI text, needs language
  Future<SummaryStats?> getSummaryStats(String userId) async {
    try {
      final language = await _getLanguage();
      final data = await _client.get('/ai/insights/$userId?language=$language');
      if (data is Map<String, dynamic>) {
        return SummaryStats.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class AlertModel {
  final String message;
  final String severity;
  final String category;

  AlertModel({
    required this.message,
    required this.severity,
    required this.category,
  });

  factory AlertModel.fromJson(dynamic json) {
    if (json is String) {
      return AlertModel(
        message: json,
        severity: json.contains('🚨') ? 'high' : 'medium',
        category: 'general',
      );
    }
    final map = Map<String, dynamic>.from(json as Map);
    return AlertModel(
      message: map['message']?.toString() ?? map['alert']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'medium',
      category: map['category']?.toString() ?? 'general',
    );
  }

  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
}

class BudgetStatusItem {
  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final double usagePercent;
  final double dailyAvgSpend;
  final double predictedMonthEnd;
  final bool willExceed;

  BudgetStatusItem({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.usagePercent,
    required this.dailyAvgSpend,
    required this.predictedMonthEnd,
    required this.willExceed,
  });

  factory BudgetStatusItem.fromJson(Map<String, dynamic> json) {
    return BudgetStatusItem(
      category: json['category']?.toString() ?? '',
      limit: (json['limit'] ?? 0).toDouble(),
      spent: (json['spent'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      usagePercent: (json['usage_percent'] ?? 0).toDouble(),
      dailyAvgSpend: (json['daily_avg_spend'] ?? 0).toDouble(),
      predictedMonthEnd: (json['predicted_month_end'] ?? 0).toDouble(),
      willExceed: json['will_exceed'] as bool? ?? false,
    );
  }
}

class GoalSnapshot {
  final String goalName;
  final double targetAmount;
  final double savedAmount;
  final double progressPercent;
  final String status;
  final String deadline;

  GoalSnapshot({
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    required this.progressPercent,
    required this.status,
    required this.deadline,
  });

  factory GoalSnapshot.fromJson(Map<String, dynamic> json) {
    return GoalSnapshot(
      goalName: json['goal_name']?.toString() ?? '',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      savedAmount: (json['saved_amount'] ?? 0).toDouble(),
      progressPercent: (json['progress_percent'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'On Track',
      deadline: json['deadline']?.toString() ?? '',
    );
  }

  bool get isCompleted => status == 'Completed';
  bool get isAtRisk => status == 'At Risk';
}

class BehaviorInsight {
  final String insight;
  final String severity;
  final String category;

  BehaviorInsight({
    required this.insight,
    required this.severity,
    required this.category,
  });

  factory BehaviorInsight.fromJson(dynamic json) {
    if (json is String) {
      return BehaviorInsight(
        insight: json,
        severity: 'medium',
        category: 'general',
      );
    }
    final map = Map<String, dynamic>.from(json as Map);
    return BehaviorInsight(
      insight: map['insight']?.toString() ??
          map['message']?.toString() ??
          map['pattern']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'medium',
      category: map['category']?.toString() ?? 'general',
    );
  }
}

class SummaryStats {
  final double income;
  final double expense;
  final double savings;
  final Map<String, double> categoryBreakdown;

  SummaryStats({
    required this.income,
    required this.expense,
    required this.savings,
    required this.categoryBreakdown,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    double income = 0, expense = 0, savings = 0;
    Map<String, double> breakdown = {};

    final summaryStr = json['summary']?.toString() ?? '';
    final incomeMatch = RegExp(r'Income:\s*₹?([\d.]+)').firstMatch(summaryStr);
    final expenseMatch = RegExp(r'Expense:\s*₹?([\d.]+)').firstMatch(summaryStr);
    final savingsMatch = RegExp(r'Savings:\s*₹?(-?[\d.]+)').firstMatch(summaryStr);

    if (incomeMatch != null) income = double.tryParse(incomeMatch.group(1) ?? '0') ?? 0;
    if (expenseMatch != null) expense = double.tryParse(expenseMatch.group(1) ?? '0') ?? 0;
    if (savingsMatch != null) savings = double.tryParse(savingsMatch.group(1) ?? '0') ?? 0;

    if (json['monthly'] is Map) {
      final m = json['monthly'] as Map;
      income = (m['income'] ?? income).toDouble();
      expense = (m['expense'] ?? expense).toDouble();
      savings = (m['savings'] ?? savings).toDouble();
    }

    if (json['category_breakdown'] is Map) {
      (json['category_breakdown'] as Map).forEach((k, v) {
        breakdown[k.toString()] = (v ?? 0).toDouble();
      });
    }

    return SummaryStats(
      income: income,
      expense: expense,
      savings: savings,
      categoryBreakdown: breakdown,
    );
  }
}