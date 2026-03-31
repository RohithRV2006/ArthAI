import 'package:flutter/material.dart';
import 'package:arth/api_service.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/expense_model.dart';
// 🔥 Notice the old dead service is completely gone from the imports!

class TransactionProvider extends ChangeNotifier {
  List<ExpenseModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, List<ExpenseModel>> get groupedByDate {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final tx in _transactions) {
      final key = _formatDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  Set<String> get daysWithTransactions {
    return _transactions.map((tx) {
      return '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
    }).toSet();
  }

  List<ExpenseModel> transactionsForDay(DateTime day) {
    return _transactions.where((tx) {
      return tx.date.year == day.year && tx.date.month == day.month && tx.date.day == day.day;
    }).toList();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await LocalStorage.getUserId();
      if (userId != null) {
        final dbTransactions = await ApiService.getTransactions(userId);
        if (dbTransactions.isNotEmpty) {
          _transactions = dbTransactions.map((item) {
            DateTime parsedDate = DateTime.now();
            if (item['date'] != null) {
              parsedDate = DateTime.tryParse(item['date'].toString()) ?? DateTime.now();
            }
            return ExpenseModel(
              id: item['id']?.toString() ?? item['_id']?.toString(),
              userId: userId,
              amount: (item['amount'] ?? 0).toDouble(),
              category: item['category']?.toString() ?? 'other',
              description: item['description']?.toString() ?? '',
              date: parsedDate,
            );
          }).toList();
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load history: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔥 THE NEW BULLETPROOF ADD ROUTE
  Future<void> addTransaction({required double amount, required String category, required String description}) async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return;

    final expense = ExpenseModel(
      userId: userId,
      amount: amount,
      category: category,
      description: description,
      date: DateTime.now(),
    );

    // 1. Optimistic Update: Instantly show it on the screen!
    _transactions.insert(0, expense);
    notifyListeners();

    try {
      // 2. Send it to the Python backend via ApiService
      final success = await ApiService.addTransaction(expense);

      if (success) {
        // 3. If successful, reload to grab the real MongoDB ID so we can delete it later
        loadTransactions();
      } else {
        throw Exception("Server rejected the transaction");
      }
    } catch (e) {
      debugPrint("Backend save failed: $e");
      // Rollback: If the server fails, remove it from the screen
      _transactions.remove(expense);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;

    final removedTx = _transactions.removeAt(index);
    notifyListeners();

    try {
      final success = await ApiService.deleteTransaction(id);
      if (!success) throw Exception("Server returned false");
    } catch (e) {
      _transactions.insert(index, removedTx);
      notifyListeners();
      debugPrint("Delete failed: $e");
    }
  }

  void onAiTransactionSaved(Map<String, dynamic> details) {
    loadTransactions();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) return 'Yesterday';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  // 🔥 THE FIX: Added the missing clear function!
  void clearTransactions() {
    _transactions.clear();
    notifyListeners();
  }
}