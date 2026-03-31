import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:arth/expense_model.dart';

class ApiService {
  // Your live Render backend URL
  static const String baseUrl = 'http://10.132.185.222:8000';

  // ── 1. Save User Profile ──
  static Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // 🔥 THE FIX: If Python rejects it, print the EXACT reason and stop the app!
        debugPrint('🛑 PYTHON REJECTED PAYLOAD: ${response.body}');
        throw Exception('Server rejected data: ${response.body}');
      }
    } catch (e) {
      debugPrint('🛑 CRITICAL ERROR saving profile: $e');
      rethrow; // 🔥 Force the error back to the UI so it doesn't navigate to the Home screen!
    }
  }

  // ── 2. Create Goal ──
  static Future<bool> createGoal({required String userId, required String name, required double targetAmount, required String deadline}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/goal/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'goal_name': name, 'target_amount': targetAmount, 'deadline': deadline}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating goal: $e');
      return false;
    }
  }

  // ── 3. Add Money to Goal ──
  static Future<bool> addMoney({required String userId, required String name, required double amount}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/goal/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'goal_name': name, 'amount': amount}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding money: $e');
      return false;
    }
  }

  // ── 4. Get All Goals ──
  static Future<List<dynamic>> getGoals(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/goal/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error fetching goals: $e');
    }
    return [];
  }

  // ── 5. Get Goal Alerts ──
  static Future<List<dynamic>> getAlerts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/alerts/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
    }
    return [];
  }

  // ── 6. Get Budget Status ──
  static Future<Map<String, dynamic>> getBudgetStatus(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/budget/status/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error fetching budget status: $e');
    }
    return {};
  }

  // ── 7. Get Financial Behavior ──
  static Future<Map<String, dynamic>> getBehavior(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/behavior/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error fetching behavior: $e');
    }
    return {};
  }

  // ── 8. Get Transaction History ──
  static Future<List<dynamic>> getTransactions(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expense/history/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
    return [];
  }

  // ── 9. Delete Transaction ──
  static Future<bool> deleteTransaction(String txId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/expense/delete/$txId'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  // ── 10. Add Manual Transaction ──
  static Future<bool> addTransaction(ExpenseModel expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expense/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(expense.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding manual transaction: $e');
      return false;
    }
  }
}