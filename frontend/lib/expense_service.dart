import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/expense_model.dart';

class ExpenseService {
  static const String _expensesKey = 'arth_local_expenses';

  /// Adds a new expense to local storage
  Future<void> addExpense(ExpenseModel expense) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load existing expenses
    final String? existingData = prefs.getString(_expensesKey);
    List<dynamic> expenseList = [];

    if (existingData != null) {
      expenseList = jsonDecode(existingData);
    }

    // 2. Convert the new expense using your model's toJson() method
    expenseList.add(expense.toJson());

    // 3. Save back to SharedPreferences
    await prefs.setString(_expensesKey, jsonEncode(expenseList));
  }

  /// Loads all expenses for a specific user from local storage
  Future<List<ExpenseModel>> getExpenses(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_expensesKey);

    if (existingData == null) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(existingData);

      // Parse the JSON list back into objects using your fromJson() method
      List<ExpenseModel> allExpenses = decodedList
          .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Filter to only return expenses for the logged-in user
      return allExpenses.where((exp) => exp.userId == userId).toList();

    } catch (e) {
      // If there's an error parsing old data, return an empty list
      return [];
    }
  }

  /// Clears all saved expenses (useful for testing or logging out)
  Future<void> clearAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expensesKey);
  }
}