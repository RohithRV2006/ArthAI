import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arth/goal_budget_service.dart';
import 'package:arth/goal_budget_models.dart';
import 'package:arth/local_storage.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _service = GoalService();

  List<GoalModel> _goals = [];
  List<String> _alerts = [];
  bool _isLoading = false;
  bool _loaded = false; // ← guard: don't re-fetch if already loaded
  String? _error;

  List<GoalModel> get goals => _goals;
  List<String> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Call this from initState. Skips fetch if data is already loaded.
  /// Pass [force] = true to always re-fetch (e.g. pull-to-refresh).
  Future<void> loadGoals({bool force = false}) async {
    if (_isLoading) return; // already in flight
    if (_loaded && !force) return; // already have data, skip

    final userId = await LocalStorage.getUserId();
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getGoals(userId),
        _service.getAlerts(userId),
      ]).timeout(
        const Duration(seconds: 30), // generous timeout for cold backends
        onTimeout: () => throw TimeoutException('timeout'),
      );
      _goals = results[0] as List<GoalModel>;
      _alerts = results[1] as List<String>;
      _loaded = true;
      _error = null;
    } on TimeoutException {
      _error = 'Server took too long. Pull down to retry.';
    } catch (e) {
      _error = 'Could not load goals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force a fresh fetch — used by pull-to-refresh.
  Future<void> reload() => loadGoals(force: true);

  Future<bool> createGoal({
    required String goalName,
    required double targetAmount,
    required String deadline,
  }) async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return false;

    try {
      await _service.createGoal(
        userId: userId,
        goalName: goalName,
        targetAmount: targetAmount,
        deadline: deadline,
      );
      await loadGoals(force: true); // force refresh after mutation
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMoney({
    required String goalName,
    required double amount,
  }) async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return false;

    try {
      await _service.addMoney(
        userId: userId,
        goalName: goalName,
        amount: amount,
      );
      await loadGoals(force: true); // force refresh after mutation
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
