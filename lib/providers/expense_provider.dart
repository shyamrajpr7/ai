import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class ExpenseProvider extends ChangeNotifier {
  final HiveService _hiveService;

  List<Expense> _expenses = [];
  bool _initialized = false;
  String _selectedMonth = 'all';

  List<Expense> get expenses => _expenses;
  bool get initialized => _initialized;
  String get selectedMonth => _selectedMonth;

  static const _categories = [
    'food', 'transport', 'housing', 'entertainment',
    'health', 'education', 'shopping', 'utilities', 'other'
  ];

  static const _categoryIcons = {
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'housing': Icons.home,
    'entertainment': Icons.sports_esports,
    'health': Icons.local_hospital,
    'education': Icons.school,
    'shopping': Icons.shopping_bag,
    'utilities': Icons.bolt,
    'other': Icons.more_horiz,
  };

  static const _categoryColors = {
    'food': Color(0xFFFF6D00),
    'transport': Color(0xFF448AFF),
    'housing': Color(0xFF00BCD4),
    'entertainment': Color(0xFFE040FB),
    'health': Color(0xFF00E676),
    'education': Color(0xFFFFD740),
    'shopping': Color(0xFFFF4081),
    'utilities': Color(0xFF536DFE),
    'other': Color(0xFF78909C),
  };

  List<String> get categories => _categories;
  Map<String, IconData> get categoryIcons => _categoryIcons;
  Map<String, Color> get categoryColors => _categoryColors;

  List<Expense> get filteredExpenses {
    if (_selectedMonth == 'all') return _expenses;
    return _expenses.where((e) {
      final monthKey = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      return monthKey == _selectedMonth;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalExpenses => filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final e in filteredExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<String> get availableMonths {
    final months = <String>{};
    for (final e in _expenses) {
      months.add('${e.date.year}-${e.date.month.toString().padLeft(2, '0')}');
    }
    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  double get monthlyAverage {
    if (_expenses.isEmpty) return 0;
    final months = availableMonths.length;
    return totalExpenses / (months > 0 ? months : 1);
  }

  ExpenseProvider(this._hiveService);

  Future<void> load() async {
    _expenses = _hiveService.loadExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    _initialized = true;
    notifyListeners();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    String category = 'other',
    String? note,
    DateTime? date,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
    );
    _expenses.add(expense);
    await _save();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  void setMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveExpenses(_expenses);
  }
}
