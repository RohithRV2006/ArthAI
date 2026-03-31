import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:arth/budget_provider.dart';
import 'package:arth/goal_budget_models.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/app_localizations.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<ProfileProvider>().language;
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.budget),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSetBudgetSheet(context, loc),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: loc.overview),
            Tab(text: loc.status),
            Tab(text: loc.suggestions),
          ],
        ),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.reload(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(provider: provider, loc: loc),
                _StatusTab(provider: provider, loc: loc),
                _SuggestionsTab(provider: provider, loc: loc),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSetBudgetSheet(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(),
        child: _SetBudgetSheet(loc: loc),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final BudgetProvider provider;
  final AppLocalizations loc;
  const _OverviewTab({required this.provider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final health = provider.health;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (health != null) _HealthScoreCard(health: health, loc: loc),
          const SizedBox(height: 20),

          if (health != null && health.warnings.isNotEmpty) ...[
            Text(loc.warnings,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...health.warnings.map(
                  (w) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(w,
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (provider.budgetStatus.isNotEmpty) ...[
            Text(loc.thisMonth,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _QuickStatsRow(status: provider.budgetStatus, loc: loc),
          ],

          if (provider.error != null) _ErrorCard(message: provider.error!),

          if (provider.budgetStatus.isEmpty && provider.error == null)
            _EmptyBudget(
              loc: loc,
              onSet: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: _SetBudgetSheet(loc: loc),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final BudgetHealthModel health;
  final AppLocalizations loc;
  const _HealthScoreCard({required this.health, required this.loc});

  Color get _scoreColor {
    if (health.score >= 80) return const Color(0xFF1D9E75);
    if (health.score >= 60) return Colors.blue;
    if (health.score >= 40) return Colors.orange;
    return Colors.red;
  }

  String get _emoji {
    if (health.score >= 80) return '🌟';
    if (health.score >= 60) return '👍';
    if (health.score >= 40) return '⚠️';
    return '🚨';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _scoreColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${health.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '/100',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_emoji Budget Health',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  health.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: health.score / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final List<BudgetStatusModel> status;
  final AppLocalizations loc;
  const _QuickStatsRow({required this.status, required this.loc});

  @override
  Widget build(BuildContext context) {
    final totalLimit = status.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = status.fold<double>(0, (s, b) => s + b.spent);
    final atRisk = status.where((b) => b.willExceed).length;

    return Row(
      children: [
        _MiniStat(
          label: loc.totalLimit,
          value: '₹${totalLimit.toStringAsFixed(0)}',
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          label: loc.totalSpent,
          value: '₹${totalSpent.toStringAsFixed(0)}',
          color: const Color(0xFF1D9E75),
        ),
        const SizedBox(width: 8),
        _MiniStat(
          label: loc.atRisk,
          value: '$atRisk ${loc.categories}',
          color: atRisk > 0 ? Colors.red : const Color(0xFF1D9E75),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final BudgetProvider provider;
  final AppLocalizations loc;
  const _StatusTab({required this.provider, required this.loc});

  @override
  Widget build(BuildContext context) {
    if (provider.budgetStatus.isEmpty) {
      return Center(
        child: Text(loc.noBudgetData,
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: provider.budgetStatus
          .map((b) => _BudgetStatusCard(budget: b, loc: loc))
          .toList(),
    );
  }
}

class _BudgetStatusCard extends StatelessWidget {
  final BudgetStatusModel budget;
  final AppLocalizations loc;
  const _BudgetStatusCard({required this.budget, required this.loc});

  Color get _barColor {
    if (budget.usagePercent >= 100) return Colors.red;
    if (budget.usagePercent >= 80) return Colors.orange;
    return const Color(0xFF1D9E75);
  }

  IconData _iconFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':        return Icons.restaurant;
      case 'transport':   return Icons.directions_bus;
      case 'shopping':    return Icons.shopping_bag;
      case 'health':      return Icons.medical_services;
      case 'entertainment': return Icons.movie;
      case 'education':   return Icons.school;
      default:            return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (budget.usagePercent / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: budget.willExceed
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _barColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(budget.category),
                      color: _barColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    budget.category[0].toUpperCase() +
                        budget.category.substring(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (budget.willExceed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(loc.willExceed,
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${budget.spent.toStringAsFixed(0)} ${loc.spent}',
                    style:
                    const TextStyle(fontWeight: FontWeight.w600)),
                Text('₹${budget.limit.toStringAsFixed(0)} ${loc.limit}',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                valueColor:
                AlwaysStoppedAnimation<Color>(_barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.usagePercent.toStringAsFixed(1)}% ${loc.used}',
                  style: TextStyle(
                      color: _barColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
                Text(
                  '₹${budget.remaining.toStringAsFixed(0)} ${loc.left}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BurnStat(
                    label: loc.dailyAvg,
                    value:
                    '₹${budget.dailyAvgSpend.toStringAsFixed(0)}',
                  ),
                  Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200),
                  _BurnStat(
                    label: loc.monthEndPrediction,
                    value:
                    '₹${budget.predictedMonthEnd.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurnStat extends StatelessWidget {
  final String label;
  final String value;
  const _BurnStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _SuggestionsTab extends StatelessWidget {
  final BudgetProvider provider;
  final AppLocalizations loc;
  const _SuggestionsTab({required this.provider, required this.loc});

  @override
  Widget build(BuildContext context) {
    if (provider.suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💡', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(loc.noSuggestionsYet,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                loc.addMoreExpenses,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF1D9E75), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.aiSuggestedBudgets,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...provider.suggestions.map((s) => _SuggestionCard(
          suggestion: s,
          loc: loc,
          onApply: () async {
            final success =
            await context.read<BudgetProvider>().setBudget(
              category: s.category,
              limit: s.suggestedBudget,
            );
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.budget} set for ${s.category}: ₹${s.suggestedBudget}'),
                  backgroundColor: const Color(0xFF1D9E75),
                ),
              );
            }
          },
        )),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final BudgetSuggestionModel suggestion;
  final AppLocalizations loc;
  final VoidCallback onApply;
  const _SuggestionCard(
      {required this.suggestion, required this.loc, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.category[0].toUpperCase() +
                        suggestion.category.substring(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.avgSpend}: ₹${suggestion.avgSpend.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Text(
                    '${loc.suggested}: ₹${suggestion.suggestedBudget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onApply,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D9E75),
                side: const BorderSide(color: Color(0xFF1D9E75)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(loc.apply),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetBudgetSheet extends StatefulWidget {
  final AppLocalizations loc;
  const _SetBudgetSheet({required this.loc});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  final _limitCtrl = TextEditingController();
  String _category = 'food';
  bool _isLoading = false;

  final List<String> _categories = [
    'food', 'transport', 'shopping', 'health',
    'entertainment', 'education', 'other',
  ];

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final limit = double.tryParse(_limitCtrl.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await context.read<BudgetProvider>().setBudget(
      category: _category,
      limit: limit,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.loc.setBudgetLimit,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: widget.loc.category,
              prefixIcon: const Icon(Icons.category_outlined,
                  color: Color(0xFF1D9E75)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1D9E75), width: 2),
              ),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(
              value: c,
              child: Text(
                  c[0].toUpperCase() + c.substring(1)),
            ))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _limitCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.loc.monthlyLimit,
              prefixIcon: const Icon(Icons.currency_rupee,
                  color: Color(0xFF1D9E75)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1D9E75), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(widget.loc.setBudget,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  final VoidCallback onSet;
  final AppLocalizations loc;
  const _EmptyBudget({required this.onSet, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('💰', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(loc.noBudgetsSet,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              loc.setMonthlyLimits,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onSet,
              icon: const Icon(Icons.add),
              label: Text(loc.setFirstBudget),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer)),
      ),
    );
  }
}