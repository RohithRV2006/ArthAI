import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/goal_provider.dart';
import 'package:arth/goal_budget_models.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/app_localizations.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<ProfileProvider>().language;
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(loc.myGoals),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D9E75),
        onPressed: () => _showCreateGoalDialog(context, loc),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(loc.newGoal, style: const TextStyle(color: Colors.white)),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
          }

          if (provider.goals.isEmpty) {
            return Center(
              child: Text(
                loc.noGoalsYet,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.alerts.isNotEmpty) ...[
                  ...provider.alerts.map((alert) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert,
                            style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                ...provider.goals.map((goal) => _GoalCard(goal: goal, loc: loc)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, AppLocalizations loc) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.newGoal),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: loc.goalNameHint),
            ),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.targetAmount),
            ),
            TextField(
              controller: deadlineCtrl,
              decoration: InputDecoration(
                  labelText: loc.deadlineHint, hintText: '2026-12'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty &&
                  targetCtrl.text.isNotEmpty &&
                  deadlineCtrl.text.isNotEmpty) {
                context.read<GoalProvider>().createGoal(
                  goalName: nameCtrl.text,
                  targetAmount: double.parse(targetCtrl.text),
                  deadline: deadlineCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text(loc.create),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final AppLocalizations loc;
  const _GoalCard({required this.goal, required this.loc});

  @override
  Widget build(BuildContext context) {
    final double progress = (goal.progressPercent).clamp(0.0, 100.0) / 100.0;
    final bool isAtRisk = goal.isAtRisk;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.goalName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAtRisk
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isAtRisk
                            ? Colors.red.shade200
                            : Colors.green.shade200),
                  ),
                  child: Text(
                    goal.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAtRisk
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${goal.savedAmount.toStringAsFixed(0)} ${loc.saved}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                Text('${loc.of} ₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAtRisk ? Colors.orange : const Color(0xFF1D9E75),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${loc.deadline}: ${goal.deadline}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                        '${loc.needsMo} ₹${goal.monthlyRequired.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showAddMoneyDialog(context, goal.goalName, loc),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(loc.addMoney),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D9E75),
                    side: const BorderSide(color: Color(0xFF1D9E75)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, String goalName, AppLocalizations loc) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${loc.addMoney} -> $goalName'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.amountHint,
            prefixIcon: const Icon(Icons.currency_rupee),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75)),
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                context.read<GoalProvider>().addMoney(
                  goalName: goalName,
                  amount: double.parse(amountCtrl.text),
                );
                Navigator.pop(context);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }
}