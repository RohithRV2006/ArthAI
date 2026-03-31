import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/dashboard_service.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/ai_models.dart';
import 'package:arth/ai_service.dart';
import 'package:arth/translation_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  final AiService _aiService = AiService();

  List<AlertModel> _alerts = [];
  List<BudgetStatusItem> _budgetStatus = [];
  List<GoalSnapshot> _goals = [];
  List<BehaviorInsight> _behavior = [];
  SummaryStats? _summaryStats;
  List<InsightModel> _insights = [];

  bool _isLoading = false;
  bool _isFetchingFresh = false;
  String? _error;

  List<AlertModel> get alerts => _alerts;
  List<BudgetStatusItem> get budgetStatus => _budgetStatus;
  List<GoalSnapshot> get goals => _goals;
  List<BehaviorInsight> get behavior => _behavior;
  SummaryStats? get summaryStats => _summaryStats;
  List<InsightModel> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isFetchingFresh => _isFetchingFresh;
  String? get error => _error;

  Future<String> _getCacheKey() async {
    final userId = await LocalStorage.getUserId() ?? 'guest';
    return 'arth_dashboard_cache_$userId';
  }

  Future<String> _getCacheTimeKey() async {
    final userId = await LocalStorage.getUserId() ?? 'guest';
    return 'arth_dashboard_cache_time_$userId';
  }

  Future<void> init() async {
    await _loadFromCache();
    await _fetchAll();
  }

  Future<void> loadInsights() async {
    await _loadFromCache();
    if (_summaryStats == null) {
      _isLoading = true;
      notifyListeners();
    }
    await _invalidateCache();
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    final userId = await LocalStorage.getUserId();
    final language = await LocalStorage.getLanguage();

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_summaryStats != null) _isFetchingFresh = true;
    _error = null;
    notifyListeners();

    double baseIncome = 0.0;
    try {
      final user = await LocalStorage.loadUser();
      baseIncome = user?.totalMonthlyIncome ?? 0.0;
    } catch (_) {}

    try {
      final results = await Future.wait([
        _service.getAlerts(userId),
        _service.getBudgetStatus(userId),
        _service.getGoals(userId),
        _service.getBehavior(userId),
        _service.getSummaryStats(userId),
        _aiService.getInsights(userId, language: language),
      ]).timeout(const Duration(seconds: 60));

      _alerts = results[0] as List<AlertModel>;
      _budgetStatus = results[1] as List<BudgetStatusItem>;
      _goals = results[2] as List<GoalSnapshot>;
      _behavior = results[3] as List<BehaviorInsight>;

      if (language == 'tamil') {
        await Future.wait([
          ..._alerts.asMap().entries.map((e) async {
            final translated = await TranslationService.translate(e.value.message, 'ta');
            _alerts[e.key] = AlertModel(message: translated, severity: e.value.severity, category: e.value.category);
          }),
          ..._behavior.asMap().entries.map((e) async {
            final translated = await TranslationService.translate(e.value.insight, 'ta');
            _behavior[e.key] = BehaviorInsight(insight: translated, severity: e.value.severity, category: e.value.category);
          }),
          ..._goals.asMap().entries.map((e) async {
            final translatedName = await TranslationService.translate(e.value.goalName, 'ta');
            final translatedStatus = await TranslationService.translate(e.value.status, 'ta');
            _goals[e.key] = GoalSnapshot(goalName: translatedName, targetAmount: e.value.targetAmount, savedAmount: e.value.savedAmount, progressPercent: e.value.progressPercent, status: translatedStatus, deadline: e.value.deadline);
          }),
          ..._budgetStatus.asMap().entries.map((e) async {
            final translatedCategory = await TranslationService.translate(e.value.category, 'ta');
            _budgetStatus[e.key] = BudgetStatusItem(category: translatedCategory, limit: e.value.limit, spent: e.value.spent, remaining: e.value.remaining, usagePercent: e.value.usagePercent, dailyAvgSpend: e.value.dailyAvgSpend, predictedMonthEnd: e.value.predictedMonthEnd, willExceed: e.value.willExceed);
          }),
        ]);
      }

      final fetchedStats = results[4] as SummaryStats?;

      // 🔥 THE FIX: Stop double counting! Use the backend summary income.
      // If the backend is empty (0), fallback to the profile baseIncome.
      final backendIncome = fetchedStats?.income ?? 0.0;
      final actualIncome = backendIncome > 0 ? backendIncome : baseIncome;

      final loggedExpense = fetchedStats?.expense ?? 0.0;
      final actualSavings = actualIncome - loggedExpense;

      _summaryStats = SummaryStats(
        income: actualIncome,
        expense: loggedExpense,
        savings: actualSavings,
        categoryBreakdown: fetchedStats?.categoryBreakdown ?? {},
      );

      _insights = results[5] as List<InsightModel>;

      await _saveToCache();
    } on TimeoutException {
      if (_summaryStats == null) _error = 'Server is slow. Pull down to retry.';
    } catch (e) {
      if (_summaryStats == null) _error = 'Could not load dashboard. Pull down to retry.';
    } finally {
      _isLoading = false;
      _isFetchingFresh = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _getCacheKey();
      final raw = prefs.getString(cacheKey);

      if (raw == null) {
        _clearState();
        return;
      }

      final map = jsonDecode(raw) as Map<String, dynamic>;

      if (map['summary'] != null) {
        _summaryStats = SummaryStats.fromJson(Map<String, dynamic>.from(map['summary']));
      }
      if (map['insights'] is List) {
        _insights = (map['insights'] as List)
            .map((e) => InsightModel(title: e['title'] ?? '', description: e['description'] ?? '', category: e['category'])).toList();
      }
      if (map['alerts'] is List) {
        _alerts = (map['alerts'] as List)
            .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (map['goals'] is List) {
        _goals = (map['goals'] as List)
            .map((e) => GoalSnapshot.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (map['budgets'] is List) {
        _budgetStatus = (map['budgets'] as List)
            .map((e) => BudgetStatusItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      if (_summaryStats != null) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (_) {
      _clearState();
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _getCacheKey();
      final cacheTimeKey = await _getCacheTimeKey();

      final map = {
        'summary': _summaryStats != null
            ? {'income': _summaryStats!.income, 'expense': _summaryStats!.expense, 'savings': _summaryStats!.savings} : null,
        'insights': _insights.map((i) => {'title': i.title, 'description': i.description, 'category': i.category}).toList(),
        'alerts': _alerts.map((a) => {'message': a.message, 'severity': a.severity, 'category': a.category}).toList(),
        'goals': _goals.map((g) => {'goal_name': g.goalName, 'target_amount': g.targetAmount, 'saved_amount': g.savedAmount, 'progress_percent': g.progressPercent, 'status': g.status, 'deadline': g.deadline}).toList(),
        'budgets': _budgetStatus.map((b) => {'category': b.category, 'limit': b.limit, 'spent': b.spent, 'remaining': b.remaining, 'usage_percent': b.usagePercent, 'daily_avg_spend': b.predictedMonthEnd, 'predicted_month_end': b.predictedMonthEnd, 'will_exceed': b.willExceed}).toList(),
      };
      await prefs.setString(cacheKey, jsonEncode(map));
      await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = await _getCacheKey();
    final cacheTimeKey = await _getCacheTimeKey();

    await prefs.remove(cacheKey);
    await prefs.remove(cacheTimeKey);
  }

  void _clearState() {
    _summaryStats = null; _insights = []; _alerts = []; _goals = []; _budgetStatus = []; _behavior = [];
    notifyListeners();
  }

  Future<void> clearAllCache() async {
    _clearState();
    await _invalidateCache();
  }
}