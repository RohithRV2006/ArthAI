import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/dashboard_provider.dart';
import 'package:arth/dashboard_service.dart';
import 'package:arth/ai_chat_screen.dart';
import 'package:arth/financial_health_screen.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/app_localizations.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/transaction_provider.dart';
import 'package:arth/budget_provider.dart';
import 'package:arth/goal_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final user = await LocalStorage.loadUser();

    if (!mounted) return;

    setState(() {
      _userName = user?.name ?? '';
    });

    final dashProvider = context.read<DashboardProvider>();
    final transProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final goalProvider = context.read<GoalProvider>();
    final profProvider = context.read<ProfileProvider>();

    await dashProvider.clearAllCache();
    transProvider.clearTransactions();

    await Future.wait([
      profProvider.load(),
      transProvider.loadTransactions(),
      budgetProvider.load(force: true),
      goalProvider.loadGoals(force: true),
      dashProvider.loadInsights(),
    ]);
  }

  void _showInsightsModal(BuildContext context, dynamic provider, AppLocalizations loc, String currentLanguage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.auto_awesome_outlined,
              title: loc.aiInsights,
              subtitle: provider.isFetchingFresh ? loc.updating : loc.personalizedForYou,
              isUpdating: provider.isFetchingFresh,
            ),
            const SizedBox(height: 20),
            Expanded(
              // 🔥 THE FIX: Stop the infinite loading spinner if the list is actually empty!
              child: provider.isFetchingFresh
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF1D9E75)),
                    const SizedBox(height: 16),
                    Text(loc.updating, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
                  : provider.insights.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        currentLanguage == 'tamil'
                            ? 'தற்போது நுண்ணறிவுகள் இல்லை. உங்கள் வரவு செலவுகளைச் சேர்க்கவும்.'
                            : 'No insights available yet. Add some transactions!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView(
                children: provider.insights.map<Widget>((i) => _InsightCard(
                  title: i.title,
                  description: i.description,
                  category: i.category ?? 'general',
                  loc: loc,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<ProfileProvider>().language;
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF1D9E75)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName.isNotEmpty ? _userName : 'Arth User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Color(0xFF1D9E75)),
                  title: Text(loc.aiInsights, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showInsightsModal(context, provider, loc, currentLanguage);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserAndFetch();
        },
        color: const Color(0xFF1D9E75),
        backgroundColor: Colors.white,
        child: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(provider, loc),
                  const SizedBox(height: 20),

                  if (provider.summaryStats != null) ...[
                    _SectionHeader(
                      icon: Icons.account_balance_wallet,
                      title: currentLanguage == 'tamil' ? 'நிதி சுருக்கம்' : 'Financial Summary',
                      subtitle: currentLanguage == 'tamil' ? 'இந்த மாதம்' : 'This Month',
                    ),
                    const SizedBox(height: 12),
                    _QuickStatsRow(stats: provider.summaryStats!, loc: loc),
                    const SizedBox(height: 20),
                  ],

                  if (provider.alerts.isNotEmpty)
                    _AlertsBanner(alerts: provider.alerts, loc: loc),

                  _AiBanner(loc: loc),
                  const SizedBox(height: 16),

                  _FinancialHealthBanner(language: currentLanguage),
                  const SizedBox(height: 24),

                  Consumer<TransactionProvider>(
                    builder: (context, txProvider, _) {
                      if (txProvider.transactions.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.history_rounded,
                            title: 'Recent Transactions',
                            subtitle: 'Latest Activity',
                          ),
                          const SizedBox(height: 12),
                          ...txProvider.transactions.take(3).map((tx) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      color: Color(0xFF1D9E75),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.category.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (tx.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            tx.description,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${tx.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  if (provider.budgetStatus.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.pie_chart_outline_rounded,
                      title: loc.budgetOverview,
                      subtitle: loc.thisMonth,
                    ),
                    const SizedBox(height: 12),
                    _BudgetOverview(items: provider.budgetStatus),
                    const SizedBox(height: 24),
                  ],

                  if (provider.goals.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.savings_outlined,
                      title: loc.savingsGoals,
                      subtitle: '${provider.goals.where((g) => g.isCompleted).length}/${provider.goals.length} ${loc.completed}',
                    ),
                    const SizedBox(height: 12),
                    _GoalsSnapshot(goals: provider.goals.take(3).toList()),
                    const SizedBox(height: 24),
                  ],

                  if (provider.behavior.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.psychology_outlined,
                      title: loc.spendingPatterns,
                      subtitle: loc.basedOnHabits,
                    ),
                    const SizedBox(height: 12),
                    _BehaviorSection(insights: provider.behavior),
                    const SizedBox(height: 24),
                  ],

                  if (provider.error != null && provider.summaryStats == null)
                    _ErrorCard(message: provider.error!),

                  if (provider.isLoading && provider.summaryStats == null)
                    const _FullSkeletonLoader(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardProvider provider, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.welcomeBack,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName.isNotEmpty ? _userName.split(' ').first : 'Arth User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Builder(
          builder: (ctx) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 26),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── UI COMPONENTS ──────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUpdating;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.grey.shade700, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ),
      if (isUpdating)
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
        ),
    ]);
  }
}

class _AlertsBanner extends StatelessWidget {
  final List<AlertModel> alerts;
  final AppLocalizations loc;

  const _AlertsBanner({required this.alerts, required this.loc});

  @override
  Widget build(BuildContext context) {
    final highAlerts = alerts.where((a) => a.isHigh).toList();
    final displayAlerts = highAlerts.isNotEmpty ? highAlerts : alerts;
    final isHigh = highAlerts.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHigh ? Colors.red.shade200 : Colors.orange.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            isHigh ? Icons.warning_rounded : Icons.info_outline,
            color: isHigh ? Colors.red : Colors.orange.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isHigh ? loc.urgentAlerts : loc.notifications,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHigh ? Colors.red.shade800 : Colors.orange.shade800,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ...displayAlerts.take(3).map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '• ',
              style: TextStyle(
                color: isHigh ? Colors.red.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                a.message,
                style: TextStyle(
                  fontSize: 13,
                  color: isHigh ? Colors.red.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
          ]),
        )),
      ]),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final SummaryStats stats;
  final AppLocalizations loc;

  const _QuickStatsRow({required this.stats, required this.loc});

  @override
  Widget build(BuildContext context) {
    final savingsColor = stats.savings >= 0 ? const Color(0xFF1D9E75) : Colors.red;
    return Row(children: [
      _StatCard(
        label: loc.income,
        value: '₹${_compact(stats.income)}',
        icon: Icons.arrow_downward_rounded,
        color: const Color(0xFF1D9E75),
      ),
      const SizedBox(width: 10),
      _StatCard(
        label: loc.expense,
        value: '₹${_compact(stats.expense)}',
        icon: Icons.arrow_upward_rounded,
        color: Colors.red.shade400,
      ),
      const SizedBox(width: 10),
      _StatCard(
        label: loc.savings,
        value: '₹${_compact(stats.savings)}',
        icon: Icons.savings_outlined,
        color: savingsColor,
      ),
    ]);
  }

  String _compact(double v) {
    if (v.abs() >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  final List<BudgetStatusItem> items;

  const _BudgetOverview({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: items.take(4).map((item) {
          final pct = (item.usagePercent / 100).clamp(0.0, 1.0);
          Color barColor = item.usagePercent >= 100
              ? Colors.red
              : (item.usagePercent >= 80 ? Colors.orange : const Color(0xFF1D9E75));

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  _capitalize(item.category),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
                ),
                Row(children: [
                  Text(
                    '₹${item.spent.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: barColor),
                  ),
                  Text(
                    ' / ₹${item.limit.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ]),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  '${item.usagePercent.toStringAsFixed(0)}% used',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (item.willExceed)
                  Text(
                    'Will exceed!',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.w600),
                  ),
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _GoalsSnapshot extends StatelessWidget {
  final List<GoalSnapshot> goals;

  const _GoalsSnapshot({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: goals.map((goal) {
        final pct = (goal.progressPercent / 100).clamp(0.0, 1.0);
        final color = goal.isCompleted
            ? const Color(0xFF1D9E75)
            : (goal.isAtRisk ? Colors.red : Colors.blue);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                goal.isCompleted ? '🎉' : (goal.isAtRisk ? '⚠️' : '🎯'),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.goalName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.status,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                '₹${goal.savedAmount.toStringAsFixed(0)} saved',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
              Text(
                '${goal.progressPercent.toStringAsFixed(0)}% of ₹${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}

class _BehaviorSection extends StatelessWidget {
  final List<BehaviorInsight> insights;

  const _BehaviorSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: insights.take(3).map((b) {
          final isHigh = b.severity == 'high';
          final color = isHigh ? Colors.red : Colors.orange;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHigh ? Icons.trending_up_rounded : Icons.info_outline,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  b.insight,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  final AppLocalizations loc;

  const _AiBanner({required this.loc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1D9E75),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                loc.talkToArth,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                loc.talkToArthSub,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
          ),
        ]),
      ),
    );
  }
}

class _FinancialHealthBanner extends StatelessWidget {
  final String language;

  const _FinancialHealthBanner({required this.language});

  @override
  Widget build(BuildContext context) {
    final isTamil = language == 'tamil';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialHealthScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF1D9E75), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isTamil ? 'நிதி சுகாதார மதிப்பெண்' : 'Financial Health Score',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                isTamil ? 'உங்கள் முழு விவரத்தைக் காண தட்டவும்' : 'Tap to see your full breakdown',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

class _InsightCard extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final AppLocalizations loc;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.category,
    required this.loc,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  IconData get _icon =>
      widget.category == 'summary' ? Icons.bar_chart_rounded : Icons.lightbulb_outline_rounded;
  Color get _baseColor =>
      widget.category == 'summary' ? Colors.blue : const Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanText(widget.description);
    final lines = cleaned.split('\n');
    final isLong = lines.length > 4;
    final displayText = _expanded || !isLong ? cleaned : '${lines.take(4).join('\n')}...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _baseColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _baseColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Text(displayText, style: TextStyle(height: 1.6, color: Colors.grey.shade700, fontSize: 14)),
        if (isLong) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                _expanded ? widget.loc.showLess : widget.loc.showMore,
                style: TextStyle(color: _baseColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _baseColor,
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _FullSkeletonLoader extends StatelessWidget {
  const _FullSkeletonLoader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.red.shade100),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500),
        ),
      ),
    ]),
  );
}

String _cleanText(String text) => text
    .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '')
    .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1) ?? '')
    .replaceAll("{'", '')
    .replaceAll("':", ':')
    .replaceAll("', '", ', ')
    .replaceAll("'}", '')
    .replaceAll('{', '')
    .replaceAll('}', '')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();