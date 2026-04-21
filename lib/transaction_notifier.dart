import 'package:flutter/material.dart';

enum TransactionStatus { credited, debited }

const List<String> categories = [
  'Food',
  'Travel',
  'Bills',
  'Shopping',
  'Entertainment',
  'Health',
  'Education',
  'Others',
];

class Transaction {
  Transaction({
    required this.id,
    required this.purpose,
    required this.amount,
    required this.type,
    required this.time,
    required this.category,
    this.source = 'Manual',
  });

  final String id;
  String purpose;
  int amount;
  TransactionStatus type;
  DateTime time;
  String category;
  String source;

  bool get isCredit => type == TransactionStatus.credited;
}

class TransactionNotifier extends ChangeNotifier {
  TransactionNotifier._internal();

  static final TransactionNotifier instance = TransactionNotifier._internal();

  final List<Transaction> _transactions = [];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  int _monthlyBudget = 25000;

  int get monthlyBudget => _monthlyBudget;

  void setMonthlyBudget(int value) {
    if (value <= 0) return;
    _monthlyBudget = value;
    notifyListeners();
  }

  void addTransaction(
    int amount,
    TransactionStatus type,
    String category, {
    required String purpose,
    DateTime? time,
    String source = 'Manual',
  }) {
    _transactions.add(
      Transaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        purpose: purpose.trim().isEmpty ? 'Untitled transaction' : purpose.trim(),
        amount: amount,
        type: type,
        time: time ?? DateTime.now(),
        category: categories.contains(category) ? category : 'Others',
        source: source,
      ),
    );
    _transactions.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }

  void updateTransaction({
    required String id,
    required String purpose,
    required int amount,
    required TransactionStatus type,
    required String category,
  }) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;

    _transactions[index]
      ..purpose = purpose.trim().isEmpty ? 'Untitled transaction' : purpose.trim()
      ..amount = amount
      ..type = type
      ..category = categories.contains(category) ? category : 'Others';
    notifyListeners();
  }

  void updatePurpose(String id, String value) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    _transactions[index].purpose = value;
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  int get total => totalCredit - totalDebit;

  int get totalCredit => _transactions
      .where((t) => t.type == TransactionStatus.credited)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalDebit => _transactions
      .where((t) => t.type == TransactionStatus.debited)
      .fold(0, (sum, t) => sum + t.amount);

  int get transactionCount => _transactions.length;

  double get averageExpense {
    final debits = _transactions.where((t) => t.type == TransactionStatus.debited).toList();
    if (debits.isEmpty) return 0;
    return totalDebit / debits.length;
  }

  int get highestExpense {
    final debits = _transactions.where((t) => t.type == TransactionStatus.debited);
    if (debits.isEmpty) return 0;
    return debits.fold(0, (highest, item) => item.amount > highest ? item.amount : highest);
  }

  Transaction? get latestTransaction => _transactions.isEmpty ? null : _transactions.first;

  Transaction? get biggestExpenseTransaction {
    final debits = _transactions.where((t) => t.type == TransactionStatus.debited).toList();
    if (debits.isEmpty) return null;
    debits.sort((a, b) => b.amount.compareTo(a.amount));
    return debits.first;
  }

  String get topCategory {
    final totals = getCategoryTotals();
    if (totals.isEmpty) return 'No spending yet';
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  int get spentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.type == TransactionStatus.debited &&
              tx.time.month == now.month &&
              tx.time.year == now.year,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get earnedThisMonth {
    final now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.type == TransactionStatus.credited &&
              tx.time.month == now.month &&
              tx.time.year == now.year,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get weekNetFlow {
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    return _transactions
        .where((tx) => tx.time.isAfter(threshold))
        .fold(0, (sum, tx) => tx.isCredit ? sum + tx.amount : sum - tx.amount);
  }

  double get budgetProgress {
    if (_monthlyBudget <= 0) return 0;
    return (spentThisMonth / _monthlyBudget).clamp(0, 1);
  }

  int get budgetRemaining => _monthlyBudget - spentThisMonth;

  int get safeBudgetRemaining => budgetRemaining < 0 ? 0 : budgetRemaining;

  int get overBudgetAmount => budgetRemaining < 0 ? budgetRemaining.abs() : 0;

  bool get isOverBudget => spentThisMonth > _monthlyBudget;

  double get rawBudgetProgress {
    if (_monthlyBudget <= 0) return 0;
    return spentThisMonth / _monthlyBudget;
  }

  String get budgetStatusLabel {
    if (spentThisMonth == 0) return 'Budget untouched';
    if (isOverBudget) return 'Budget exceeded';
    if (budgetProgress >= 0.85) return 'Close to limit';
    if (budgetProgress >= 0.6) return 'On watch';
    return 'Healthy';
  }

  String get budgetStatusDescription {
    if (spentThisMonth == 0) {
      return 'No expenses recorded this month yet.';
    }
    if (isOverBudget) {
      return 'You have crossed the target by Rs $overBudgetAmount.';
    }
    if (budgetProgress >= 0.85) {
      return 'Only Rs $safeBudgetRemaining left in this month\'s budget.';
    }
    return 'You still have Rs $safeBudgetRemaining available this month.';
  }

  Color get budgetStatusColor {
    if (isOverBudget) return const Color(0xFFDC2626);
    if (budgetProgress >= 0.85) return const Color(0xFFEA580C);
    return const Color(0xFF0F766E);
  }

  int get dailyBudgetAllowance {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDayOfMonth - now.day) + 1;
    if (remainingDays <= 0) return safeBudgetRemaining;
    return (safeBudgetRemaining / remainingDays).floor();
  }

  Map<String, int> getCategoryTotals() {
    final Map<String, int> data = {};

    for (final tx in _transactions) {
      if (tx.type == TransactionStatus.debited) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  Map<String, int> getMonthlyExpense() {
    final Map<String, int> data = {};

    for (final tx in _transactions) {
      if (tx.type == TransactionStatus.debited) {
        final month = _monthKey(tx.time);
        data[month] = (data[month] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  Map<String, int> getWeeklySpending() {
    final now = DateTime.now();
    final Map<String, int> data = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    for (final tx in _transactions) {
      if (tx.type != TransactionStatus.debited) continue;
      final difference = now.difference(tx.time).inDays;
      if (difference < 0 || difference > 6) continue;
      final label = _weekdayLabel(tx.time.weekday);
      data[label] = (data[label] ?? 0) + tx.amount;
    }

    return data;
  }

  List<Transaction> searchTransactions({
    String query = '',
    TransactionStatus? type,
    String? category,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return _transactions.where((tx) {
      final matchesQuery = normalizedQuery.isEmpty ||
          tx.purpose.toLowerCase().contains(normalizedQuery) ||
          tx.category.toLowerCase().contains(normalizedQuery) ||
          tx.source.toLowerCase().contains(normalizedQuery);
      final matchesType = type == null || tx.type == type;
      final matchesCategory = category == null || category == 'All' || tx.category == category;
      return matchesQuery && matchesType && matchesCategory;
    }).toList();
  }

  String _monthKey(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}
