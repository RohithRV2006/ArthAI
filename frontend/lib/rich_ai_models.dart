// ── Models for the rich /ai/process response ─────────────────────────────────
// FIX: moved import to top — Dart requires all directives before declarations
import 'package:flutter/material.dart';

class FinancialHealthModel {
  final int score;
  final String status;
  final double savingsRate;
  final double debtRatio;
  final double netWorth;

  FinancialHealthModel({
    required this.score,
    required this.status,
    required this.savingsRate,
    required this.debtRatio,
    required this.netWorth,
  });

  factory FinancialHealthModel.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    return FinancialHealthModel(
      score: (json['score'] ?? 0) is int
          ? json['score']
          : (json['score'] as num).toInt(),
      status: json['status']?.toString() ?? 'Unknown',
      savingsRate: (breakdown['savings_rate'] ?? 0).toDouble(),
      debtRatio: (breakdown['debt_ratio'] ?? 0).toDouble(),
      netWorth: (breakdown['net_worth'] ?? 0).toDouble(),
    );
  }

  bool get isAvailable => score > 0 || status != 'Unknown';

  Color get statusColor {
    switch (status) {
      case 'Excellent': return const Color(0xFF1D9E75);
      case 'Good': return Colors.blue;
      case 'Average': return Colors.orange;
      case 'Poor': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get emoji {
    switch (status) {
      case 'Excellent': return '🌟';
      case 'Good': return '👍';
      case 'Average': return '⚠️';
      case 'Poor': return '🚨';
      default: return '📊';
    }
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
      score: (json['score'] ?? 0) is int
          ? json['score']
          : (json['score'] as num).toInt(),
      status: json['status']?.toString() ?? '',
      warnings: (json['warnings'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}

class UserProfileSummary {
  final double income;
  final double savings;
  final double emi;
  final double netWorth;

  UserProfileSummary({
    required this.income,
    required this.savings,
    required this.emi,
    required this.netWorth,
  });

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      income: (json['income'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
      emi: (json['emi'] ?? 0).toDouble(),
      netWorth: (json['net_worth'] ?? 0).toDouble(),
    );
  }
}

class RichAiResponse {
  final String type;
  final String displayText;
  final bool isDataSaved;
  final FinancialHealthModel? financialHealth;
  final BudgetHealthModel? budgetHealth;
  final List<Map<String, dynamic>> goals;
  final List<String> recommendations;
  final String aiRecommendation;
  final UserProfileSummary? userProfile;
  final Map<String, dynamic>? metadata;

  RichAiResponse({
    required this.type,
    required this.displayText,
    this.isDataSaved = false,
    this.financialHealth,
    this.budgetHealth,
    this.goals = const [],
    this.recommendations = const [],
    this.aiRecommendation = '',
    this.userProfile,
    this.metadata,
  });

  factory RichAiResponse.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    String text = '';
    bool saved = false;

    // ── multi_data_saved ────────────────────────────────────────────────────
    if (type == 'multi_data_saved') {
      saved = true;
      final txns = json['transactions'];
      if (txns is List && txns.isNotEmpty) {
        text = txns.map((t) {
          final intent = t['intent']?.toString() ?? 'transaction';
          final amount = t['amount']?.toString() ?? '';
          final category = t['category']?.toString() ?? '';
          final alert = t['alert']?.toString() ?? '';
          String line = 'Recorded $intent of ₹$amount in $category.';
          if (alert.isNotEmpty) line += ' ⚠️ $alert';
          return line;
        }).join('\n');
      } else {
        text = 'Your data has been saved!';
      }
    }

    // ── insight ─────────────────────────────────────────────────────────────
    else if (type == 'insight') {
      final raw = json['response'];
      if (raw is Map) {
        text = raw['insight']?.toString() ??
            raw['message']?.toString() ??
            raw.values.whereType<String>().firstOrNull ??
            '';
      } else if (raw is String) {
        text = raw;
      }
      if (text.isEmpty) {
        text = json['ai_recommendation']?.toString() ??
            json['message']?.toString() ??
            'Here is your financial overview.';
      }
    }

    // ── error / fallback ────────────────────────────────────────────────────
    else {
      text = json['message']?.toString() ??
          json['response']?.toString() ??
          'Done!';
    }

    // ── Parse financial health ───────────────────────────────────────────────
    FinancialHealthModel? financialHealth;
    final fhRaw = json['financial_health'];
    if (fhRaw is Map && !fhRaw.containsKey('message')) {
      try {
        financialHealth = FinancialHealthModel.fromJson(
            Map<String, dynamic>.from(fhRaw));
      } catch (_) {}
    }

    // ── Parse budget health ──────────────────────────────────────────────────
    BudgetHealthModel? budgetHealth;
    final bhRaw = json['budget_health'];
    if (bhRaw is Map) {
      try {
        budgetHealth =
            BudgetHealthModel.fromJson(Map<String, dynamic>.from(bhRaw));
      } catch (_) {}
    }

    // ── Parse goals ──────────────────────────────────────────────────────────
    final goalsList = <Map<String, dynamic>>[];
    final goalsRaw = json['goals'];
    if (goalsRaw is List) {
      for (final g in goalsRaw) {
        if (g is Map) goalsList.add(Map<String, dynamic>.from(g));
      }
    }

    // ── Parse recommendations ────────────────────────────────────────────────
    final recsList = <String>[];
    final recsRaw = json['recommendations'];
    if (recsRaw is List) {
      recsList.addAll(recsRaw.map((e) => e.toString()));
    }

    // ── Parse user profile ───────────────────────────────────────────────────
    UserProfileSummary? userProfile;
    final upRaw = json['user_profile'];
    if (upRaw is Map) {
      try {
        userProfile =
            UserProfileSummary.fromJson(Map<String, dynamic>.from(upRaw));
      } catch (_) {}
    }

    return RichAiResponse(
      type: type,
      displayText: text.trim(),
      isDataSaved: saved,
      financialHealth: financialHealth,
      budgetHealth: budgetHealth,
      goals: goalsList,
      recommendations: recsList,
      aiRecommendation: json['ai_recommendation']?.toString() ?? '',
      userProfile: userProfile,
      metadata: json,
    );
  }

  bool get hasFinancialHealth =>
      financialHealth != null && financialHealth!.isAvailable;
  bool get hasBudgetHealth =>
      budgetHealth != null && budgetHealth!.score > 0;
  bool get hasGoals => goals.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;
  bool get hasProfile =>
      userProfile != null && userProfile!.income > 0;
  bool get hasRichData =>
      hasFinancialHealth || hasBudgetHealth || hasGoals || hasRecommendations;
}