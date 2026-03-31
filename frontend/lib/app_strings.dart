/// All UI strings used across the app.
/// Keys are used with TranslationProvider.t(key).
/// Add new strings here and they'll be auto-translated on next language switch.
class AppStrings {
  AppStrings._();

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const home = 'Home';
  static const arthAi = 'Arth AI';
  static const history = 'History';
  static const budget = 'Budget';
  static const goals = 'Goals';
  static const profile = 'Profile';

  // ── Profile Screen ─────────────────────────────────────────────────────────
  static const personalInfo = 'Personal Info';
  static const preferences = 'Preferences';
  static const incomeSources = 'Income Sources';
  static const name = 'Name';
  static const familyType = 'Family Type';
  static const monthlyIncome = 'Monthly Income';
  static const language = 'Language';
  static const currency = 'Currency';
  static const family = 'Family';
  static const individual = 'Individual';
  static const addIncomeSource = 'Add Income Source';
  static const signOut = 'Sign out';
  static const signOutTitle = 'Sign out';
  static const signOutBody = 'Are you sure you want to log out of Arth?';
  static const arthUser = 'Arth User';

  // ── Edit Dialogs ───────────────────────────────────────────────────────────
  static const editMonthlyIncome = 'Edit Monthly Income';
  static const editName = 'Edit Name';
  static const amountHint = 'Amount (₹)';
  static const nameHint = 'Name';
  static const sourceHint = 'Source (e.g. Freelance)';
  static const monthlyAmountHint = 'Monthly Amount (₹)';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const add = 'Add';

  // ── Home / Dashboard ───────────────────────────────────────────────────────
  static const goodMorning = 'Good Morning';
  static const goodAfternoon = 'Good Afternoon';
  static const goodEvening = 'Good Evening';
  static const totalBalance = 'Total Balance';
  static const income = 'Income';
  static const expenses = 'Expenses';
  static const savings = 'Savings';
  static const recentTransactions = 'Recent Transactions';
  static const viewAll = 'View All';
  static const noTransactions = 'No transactions yet';
  static const thisMonth = 'This Month';
  static const today = 'Today';

  // ── Transactions ───────────────────────────────────────────────────────────
  static const addTransaction = 'Add Transaction';
  static const amount = 'Amount';
  static const category = 'Category';
  static const note = 'Note';
  static const date = 'Date';
  static const type = 'Type';
  static const expense = 'Expense';
  static const food = 'Food';
  static const transport = 'Transport';
  static const shopping = 'Shopping';
  static const health = 'Health';
  static const entertainment = 'Entertainment';
  static const education = 'Education';
  static const other = 'Other';
  static const allTransactions = 'All Transactions';
  static const noTransactionsFound = 'No transactions found';

  // ── Budget ─────────────────────────────────────────────────────────────────
  static const monthlyBudget = 'Monthly Budget';
  static const setBudget = 'Set Budget';
  static const remaining = 'Remaining';
  static const spent = 'Spent';
  static const budgetExceeded = 'Budget exceeded!';
  static const noBudgetSet = 'No budget set';
  static const addBudget = 'Add Budget';
  static const totalBudget = 'Total Budget';
  static const totalSpent = 'Total Spent';

  // ── Goals ──────────────────────────────────────────────────────────────────
  static const myGoals = 'My Goals';
  static const addGoal = 'Add Goal';
  static const goalName = 'Goal Name';
  static const targetAmount = 'Target Amount';
  static const savedAmount = 'Saved Amount';
  static const deadline = 'Deadline';
  static const noGoalsYet = 'No goals yet';
  static const completed = 'Completed';
  static const inProgress = 'In Progress';

  // ── AI Chat ────────────────────────────────────────────────────────────────
  static const askAnything = 'Ask me anything about your finances...';
  static const thinking = 'Thinking...';
  static const typeMessage = 'Type a message...';

  // ── General ───────────────────────────────────────────────────────────────
  static const loading = 'Loading...';
  static const error = 'Something went wrong';
  static const retry = 'Retry';
  static const done = 'Done';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const confirm = 'Confirm';
  static const translating = 'Translating app...';
  static const success = 'Success';
  static const failed = 'Failed';

  /// Returns a flat map of all strings for bulk translation.
  /// key → English string
  static Map<String, String> get all => {
    'home': home,
    'arthAi': arthAi,
    'history': history,
    'budget': budget,
    'goals': goals,
    'profile': profile,
    'personalInfo': personalInfo,
    'preferences': preferences,
    'incomeSources': incomeSources,
    'name': name,
    'familyType': familyType,
    'monthlyIncome': monthlyIncome,
    'language': language,
    'currency': currency,
    'family': family,
    'individual': individual,
    'addIncomeSource': addIncomeSource,
    'signOut': signOut,
    'signOutTitle': signOutTitle,
    'signOutBody': signOutBody,
    'arthUser': arthUser,
    'editMonthlyIncome': editMonthlyIncome,
    'editName': editName,
    'amountHint': amountHint,
    'nameHint': nameHint,
    'sourceHint': sourceHint,
    'monthlyAmountHint': monthlyAmountHint,
    'cancel': cancel,
    'save': save,
    'add': add,
    'goodMorning': goodMorning,
    'goodAfternoon': goodAfternoon,
    'goodEvening': goodEvening,
    'totalBalance': totalBalance,
    'income': income,
    'expenses': expenses,
    'savings': savings,
    'recentTransactions': recentTransactions,
    'viewAll': viewAll,
    'noTransactions': noTransactions,
    'thisMonth': thisMonth,
    'today': today,
    'addTransaction': addTransaction,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date,
    'type': type,
    'expense': expense,
    'food': food,
    'transport': transport,
    'shopping': shopping,
    'health': health,
    'entertainment': entertainment,
    'education': education,
    'other': other,
    'allTransactions': allTransactions,
    'noTransactionsFound': noTransactionsFound,
    'monthlyBudget': monthlyBudget,
    'setBudget': setBudget,
    'remaining': remaining,
    'spent': spent,
    'budgetExceeded': budgetExceeded,
    'noBudgetSet': noBudgetSet,
    'addBudget': addBudget,
    'totalBudget': totalBudget,
    'totalSpent': totalSpent,
    'myGoals': myGoals,
    'addGoal': addGoal,
    'goalName': goalName,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline,
    'noGoalsYet': noGoalsYet,
    'completed': completed,
    'inProgress': inProgress,
    'askAnything': askAnything,
    'thinking': thinking,
    'typeMessage': typeMessage,
    'loading': loading,
    'error': error,
    'retry': retry,
    'done': done,
    'delete': delete,
    'edit': edit,
    'confirm': confirm,
    'translating': translating,
    'success': success,
    'failed': failed,
  };
}