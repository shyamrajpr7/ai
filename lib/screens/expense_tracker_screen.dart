import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Expense Tracker',
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, accent),
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                const SizedBox(height: 100),
                _buildTotalCard(provider, accent),
                const SizedBox(height: 12),
                _buildMonthSelector(provider, accent),
                const SizedBox(height: 12),
                _buildCategoryBreakdown(provider, accent),
                const SizedBox(height: 8),
                Expanded(
                  child: provider.filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: accent.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses recorded',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: provider.filteredExpenses.length,
                          itemBuilder: (context, index) {
                            return _buildExpenseCard(provider.filteredExpenses[index], provider, accent);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalCard(ExpenseProvider provider, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              'Total',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${provider.totalExpenses.toStringAsFixed(2)}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.filteredExpenses.length} transactions',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ExpenseProvider provider, Color accent) {
    final months = ['all', ...provider.availableMonths];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: months.map((m) {
          final selected = provider.selectedMonth == m;
          final label = m == 'all' ? 'All Time' : _formatMonth(m);
          return GestureDetector(
            onTap: () => provider.setMonth(m),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
              ),
              child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: selected ? accent : Colors.white60, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider, Color accent) {
    final breakdown = provider.categoryBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = provider.totalExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...sorted.take(5).map((e) {
              final color = provider.categoryColors[e.key] ?? Colors.white;
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(provider.categoryIcons[e.key] ?? Icons.circle, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(e.key[0].toUpperCase() + e.key.substring(1), style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                    const Spacer(),
                    Text('\$${e.value.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(dynamic expense, ExpenseProvider provider, Color accent) {
    final color = provider.categoryColors[expense.category] ?? Colors.white;
    final icon = provider.categoryIcons[expense.category] ?? Icons.circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                Text(
                  '${expense.category[0].toUpperCase()}${expense.category.substring(1)} \u2022 ${_formatDate(expense.date)}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _confirmDelete(context, expense),
            child: Icon(Icons.close, size: 16, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, Color accent) {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    _selectedCategory = 'food';
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Add Expense', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _saveExpense(context);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(hintText: 'What did you spend on?', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none),
                    ),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(color: accent, fontSize: 32, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '\$0.00',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
                        border: InputBorder.none,
                        prefixText: '\$ ',
                        prefixStyle: GoogleFonts.spaceGrotesk(color: accent, fontSize: 32, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextField(
                      controller: _noteController,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                      decoration: InputDecoration(hintText: 'Note (optional)', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none),
                    ),
                    const SizedBox(height: 12),
                    Text('Category', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: context.read<ExpenseProvider>().categories.map((c) {
                        final selected = _selectedCategory == c;
                        final color = context.read<ExpenseProvider>().categoryColors[c] ?? Colors.white;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedCategory = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                            ),
                            child: Text(c[0].toUpperCase() + c.substring(1), style: GoogleFonts.inter(fontSize: 12, color: selected ? color : Colors.white60)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExpense(BuildContext context) {
    final amount = double.tryParse(_amountController.text);
    if (_titleController.text.trim().isEmpty || amount == null || amount <= 0) return;
    context.read<ExpenseProvider>().addExpense(
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      date: _selectedDate,
    );
  }

  void _confirmDelete(BuildContext context, dynamic expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense?'),
        content: Text('Remove "${expense.title}"?', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          TextButton(
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(expense.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String key) {
    final parts = key.split('-');
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
