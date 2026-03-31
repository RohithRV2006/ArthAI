import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arth/transaction_provider.dart';
import 'package:arth/expense_model.dart';
// 🔥 Import ProfileProvider and AppLocalizations
import 'package:arth/profile_provider.dart';
import 'package:arth/app_localizations.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Watch the global language! Instantly rebuilds.
    final currentLanguage = context.watch<ProfileProvider>().language;
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D9E75),
        onPressed: () => _showAddTransaction(context, loc), // pass loc
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(loc.add, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.transactionHistory, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        _buildTabButton(0, loc.listView, Icons.list_rounded),
                        _buildTabButton(1, loc.calendar, Icons.calendar_month_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _selectedTabIndex == 0 ? _TransactionList(loc: loc) : const _CalendarView()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : []),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF1D9E75) : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF1D9E75) : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
          value: context.read<TransactionProvider>(),
          child: _AddTransactionSheet(loc: loc) // pass loc
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final AppLocalizations loc; // 🔥 Inject loc here
  const _TransactionList({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
        if (provider.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF1D9E75))),
                const SizedBox(height: 16),
                Text(loc.noTransactions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text(loc.noTransactionsSub, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        final grouped = provider.groupedByDate;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final date = grouped.keys.elementAt(index);
            final items = grouped[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4), child: Text(date.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12, letterSpacing: 1.2))),
                ...items.map((tx) => _TransactionTile(expense: tx)),
              ],
            );
          },
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final ExpenseModel expense;
  const _TransactionTile({required this.expense});

  IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_bus_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'health': return Icons.medical_services_rounded;
      case 'education': return Icons.school_rounded;
      case 'income': return Icons.arrow_downward_rounded;
      case 'saving': return Icons.savings_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  String _formatFullDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  void _showDetails(BuildContext context, Color iconColor, Color bgColor, bool isIncome) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(_iconForCategory(expense.category), color: iconColor, size: 32)),
            const SizedBox(height: 16),
            Text(expense.description.isNotEmpty ? expense.description : expense.category.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('${isIncome ? '+' : '-'} ₹${expense.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isIncome ? Colors.green.shade600 : Colors.black87)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Date', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)), Text(_formatFullDate(expense.date), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Category', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)), Text(expense.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Type', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)), Text(isIncome ? 'Income' : 'Expense', style: TextStyle(fontWeight: FontWeight.bold, color: iconColor))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      if (expense.id != null) {
                        context.read<TransactionProvider>().deleteTransaction(expense.id!);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.category.toLowerCase() == 'income';
    final iconColor = isIncome ? Colors.green.shade600 : Colors.red.shade500;
    final bgColor = isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => _showDetails(context, iconColor, bgColor, isIncome),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(_iconForCategory(expense.category), color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.description.isNotEmpty ? expense.description : expense.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(expense.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Text('${isIncome ? '+' : '-'} ₹${expense.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? Colors.green.shade600 : Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final selectedTxns = _selectedDay != null ? provider.transactionsForDay(_selectedDay!) : [];
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
                      Text('${_monthName(_focusedMonth.month)} ${_focusedMonth.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DayGrid(focusedMonth: _focusedMonth, selectedDay: _selectedDay, transactionDays: provider.daysWithTransactions, onDayTap: (day) => setState(() => _selectedDay = day)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: selectedTxns.isEmpty
                  ? Center(child: Text(_selectedDay == null ? 'Tap a day to see transactions' : 'No transactions on this day', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)))
                  : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), children: selectedTxns.map((tx) => _TransactionTile(expense: tx)).toList()),
            ),
          ],
        );
      },
    );
  }
  String _monthName(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _DayGrid extends StatelessWidget {
  final DateTime focusedMonth; final DateTime? selectedDay; final Set<String> transactionDays; final ValueChanged<DateTime> onDayTap;
  const _DayGrid({required this.focusedMonth, required this.selectedDay, required this.transactionDays, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) => SizedBox(width: 36, child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold)))).toList()),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, i) {
            if (i < startWeekday) return const SizedBox();
            final day = i - startWeekday + 1;
            final date = DateTime(focusedMonth.year, focusedMonth.month, day);

            final isFuture = date.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59));
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final hasTx = transactionDays.contains(key);
            final isSelected = selectedDay?.day == day && selectedDay?.month == focusedMonth.month && selectedDay?.year == focusedMonth.year;
            final isToday = date.day == today.day && date.month == today.month && date.year == today.year;

            return GestureDetector(
              onTap: isFuture ? null : () => onDayTap(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF1D9E75) : (isToday ? const Color(0xFF1D9E75).withValues(alpha: 0.1) : Colors.transparent), shape: BoxShape.circle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('$day', style: TextStyle(fontSize: 14, color: isFuture ? Colors.grey.shade300 : (isSelected ? Colors.white : (isToday ? const Color(0xFF1D9E75) : Colors.black87)), fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal)),
                    if (hasTx && !isSelected && !isFuture) Positioned(bottom: 6, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle))),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final AppLocalizations loc; // 🔥 Accept loc here
  const _AddTransactionSheet({required this.loc});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'food';
  String _type = 'expense';
  final List<String> _categories = ['food', 'transport', 'shopping', 'health', 'education', 'entertainment', 'other'];

  @override
  void dispose() { _amountController.dispose(); _descController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          Text(widget.loc.addTransaction, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [_buildToggle('expense', widget.loc.expense), _buildToggle('income', widget.loc.income), _buildToggle('saving', widget.loc.savings)]),
          ),
          const SizedBox(height: 24),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: widget.loc.amount, prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)))),
          const SizedBox(height: 16),
          TextField(controller: _descController, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: widget.loc.description, prefixIcon: const Icon(Icons.notes, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)))),
          const SizedBox(height: 16),
          if (_type == 'expense') DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(labelText: widget.loc.category, prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF1D9E75)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2))),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!)
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _submit, child: Text(widget.loc.saveTransaction, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildToggle(String id, String label) {
    final isSelected = _type == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF1D9E75) : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1D9E75).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : []),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount'))); return; }
    context.read<TransactionProvider>().addTransaction(amount: amount, category: _type == 'income' ? 'income' : (_type == 'saving' ? 'saving' : _selectedCategory), description: _descController.text);
    Navigator.pop(context);
  }
}