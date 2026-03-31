class ApiConstants {
  // ── Base URL ─────────────────────────────────────────────────────────────
  // Replace with your actual backend URL before running
  static const String baseUrl = 'http://10.132.185.222:8000';

  // ── AI endpoints ─────────────────────────────────────────────────────────
  static const String aiProcess = '/ai/process';
  static String aiInsights(String userId) => '/ai/insights/$userId';

  // ── Expense endpoints ─────────────────────────────────────────────────────
  static const String expenseAdd = '/expenses/add';
  static const String expenseList = '/expenses/list';
  static String expenseDelete(String id) => '/expenses/$id';

  // ── Income endpoints ──────────────────────────────────────────────────────
  static const String incomeAdd = '/income/add';
  static const String incomeList = '/income/list';

  // ── Budget endpoints ──────────────────────────────────────────────────────
  static const String budgetList = '/budgets/list';
  static const String budgetSave = '/budgets/save';

  // ── User endpoints ────────────────────────────────────────────────────────
  static const String userProfile = '/user/profile';
  static const String userUpdate = '/user/update';
}