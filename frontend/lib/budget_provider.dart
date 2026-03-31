import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arth/goal_budget_service.dart';
import 'package:arth/goal_budget_models.dart';
import 'package:arth/local_storage.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service = BudgetService();

  List<BudgetStatusModel> _budgetStatus = [];
  BudgetHealthModel? _health;
  List<BudgetSuggestionModel> _suggestions = [];
  bool _isLoading = false;
  bool _loaded = false; // ← guard: don't re-fetch if already loaded
  String? _error;

  List<BudgetStatusModel> get budgetStatus => _budgetStatus;
  BudgetHealthModel? get health => _health;
  List<BudgetSuggestionModel> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Call this from initState. Skips fetch if data is already loaded.
  /// Pass [force] = true to always re-fetch (e.g. pull-to-refresh).
  Future<void> load({bool force = false}) async {
    if (_isLoading) return; // already in flight
    if (_loaded && !force) return; // already have data, skip

    final userId = await LocalStorage.getUserId();
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getBudgetStatus(userId),
        _service.getBudgetHealth(userId),
        _service.getSuggestions(userId),
      ]).timeout(
        const Duration(seconds: 30), // generous timeout for cold backends
        onTimeout: () => throw TimeoutException('timeout'),
      );
      _budgetStatus = results[0] as List<BudgetStatusModel>;
      _health = results[1] as BudgetHealthModel;
      _suggestions = results[2] as List<BudgetSuggestionModel>;
      _loaded = true;
      _error = null;
    } on TimeoutException {
      _error = 'Server took too long. Pull down to retry.';
    } catch (e) {
      _error = 'Could not load budget: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force a fresh fetch — used by pull-to-refresh.
  Future<void> reload() => load(force: true);

  Future<bool> setBudget({
    required String category,
    required double limit,
  }) async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return false;

    try {
      await _service.setBudget(
        userId: userId,
        category: category,
        limit: limit,
      );
      await load(force: true); // force refresh after mutation
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
