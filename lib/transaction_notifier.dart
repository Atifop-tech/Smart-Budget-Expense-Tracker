import 'package:flutter/material.dart';

enum TransactionStatus { credited, debited }

const List<String> categories = [
  "Food",
  "Travel",
  "Bills",
  "Shopping",
  "Entertainment",
  "Others"
];  

class Transaction {
  String purpose;
  int amount;
  TransactionStatus type;
  DateTime time;
  String category;

  Transaction({
    required this.purpose,
    required this.amount,
    required this.type,
    required this.time,
    required this.category,
  });
}

class TransactionNotifier extends ChangeNotifier {
  static final TransactionNotifier instance = TransactionNotifier._internal();

  TransactionNotifier._internal();

  final List<Transaction> transactions = [];
  final List<TextEditingController> controllers = [];

  void addTransaction(int amount, TransactionStatus type, String category, {required String purpose}) {
    transactions.add(Transaction(purpose: purpose, amount: amount, type: type, time: DateTime.now(), category: category ));
    controllers.add(TextEditingController(text: purpose));
    notifyListeners();
  }

  void updatePurpose(int index, String value) {
    if (index < transactions.length) {
      transactions[index].purpose = value;
      notifyListeners();
    }
  }

  void deleteTransaction(int index) {
    if (index < transactions.length) {
      controllers[index].dispose();
      controllers.removeAt(index);
      transactions.removeAt(index);
      notifyListeners();
    }
  }

  int get total => transactions.fold(0, (sum, item) {
  if (item.type == TransactionStatus.credited) {
    return sum + item.amount;
  } else {
    return sum - item.amount;
  }
});

Map<String, int> getCategoryTotals() {
  Map<String, int> data = {};

  for (var tx in transactions) {
    if (tx.type == TransactionStatus.debited) {
      data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
    }
  }

  return data;
}

int get totalCredit =>
    transactions.where((t) => t.type == TransactionStatus.credited)
        .fold(0, (sum, t) => sum + t.amount);

int get totalDebit =>
    transactions.where((t) => t.type == TransactionStatus.debited)
        .fold(0, (sum, t) => sum + t.amount);

Map<String, int> getMonthlyExpense() {
  Map<String, int> data = {};

  for (var tx in transactions) {
    if (tx.type == TransactionStatus.debited) {
      String month = "${tx.time.month}-${tx.time.year}";
      data[month] = (data[month] ?? 0) + tx.amount;
    }
  }

  return data;
}
}
