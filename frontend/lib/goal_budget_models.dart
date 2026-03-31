class GoalModel {
  final String goalName;
  final double targetAmount;
  final double savedAmount;
  final double remainingAmount;
  final double progressPercent;
  final String deadline;
  final double monthlyRequired;
  final int? predictedMonths;
  final String status;

  GoalModel({
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.deadline,
    required this.monthlyRequired,
    this.predictedMonths,
    required this.status,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      goalName: json['goal_name']?.toString() ?? '',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      savedAmount: (json['saved_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      progressPercent: (json['progress_percent'] ?? 0).toDouble(),
      deadline: json['deadline']?.toString() ?? '',
      monthlyRequired: (json['monthly_required'] ?? 0).toDouble(),
      predictedMonths: json['predicted_months'] as int?,
      status: json['status']?.toString() ?? 'On Track',
    );
  }

  bool get isCompleted => status == 'Completed';
  bool get isAtRisk => status == 'At Risk';
  bool get isOnTrack => status == 'On Track';
}

class BudgetStatusModel {
  final String category;
  final String month;
  final double limit;
  final double spent;
  final double remaining;
  final double usagePercent;
  final double dailyAvgSpend;
  final double predictedMonthEnd;
  final bool willExceed;

  BudgetStatusModel({
    required this.category,
    required this.month,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.usagePercent,
    required this.dailyAvgSpend,
    required this.predictedMonthEnd,
    required this.willExceed,
  });

  factory BudgetStatusModel.fromJson(Map<String, dynamic> json) {
    return BudgetStatusModel(
      category: json['category']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
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

class BudgetHealthModel {
  final int score;
  final String status;
  final List<String> warnings;

  BudgetHealthModel({
    required this.score,
    required this.status,
    required this.warnings,
  });

  factory BudgetHealthModel.fromJson(Map<String, dynamic> json) {
    return BudgetHealthModel(
      score: (json['score'] ?? 0) as int,
      status: json['status']?.toString() ?? '',
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class BudgetSuggestionModel {
  final String category;
  final double avgSpend;
  final double suggestedBudget;

  BudgetSuggestionModel({
    required this.category,
    required this.avgSpend,
    required this.suggestedBudget,
  });

  factory BudgetSuggestionModel.fromJson(Map<String, dynamic> json) {
    return BudgetSuggestionModel(
      category: json['category']?.toString() ?? '',
      avgSpend: (json['avg_spend'] ?? 0).toDouble(),
      suggestedBudget: (json['suggested_budget'] ?? 0).toDouble(),
    );
  }
}
