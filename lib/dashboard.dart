import 'package:flutter/material.dart';
import 'package:saad_project_2/transaction_notifier.dart';// update path accordingly

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = TransactionNotifier.instance;

    final totalCredit = notifier.transactions
        .where((t) => t.type == TransactionStatus.credited)
        .fold(0, (sum, t) => sum + t.amount);

    final totalDebit = notifier.transactions
        .where((t) => t.type == TransactionStatus.debited)
        .fold(0, (sum, t) => sum + t.amount);

    final balance = totalCredit - totalDebit;

    final categoryData = _getCategoryTotals(notifier);
    final monthlyData = _getMonthlyExpense(notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- BALANCE CARDS ----------------
          Row(
            children: [
              _buildCard("Balance", balance, Colors.blue),
              const SizedBox(width: 10),
              _buildCard("Income", totalCredit, Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          _buildCard("Expense", totalDebit, Colors.red),

          const SizedBox(height: 20),

          // ---------------- CATEGORY SECTION ----------------
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...categoryData.entries.map((e) {
            return ListTile(
              title: Text(e.key),
              trailing: Text("₹${e.value}"),
            );
          }),

          const SizedBox(height: 20),

          // ---------------- MONTHLY SECTION ----------------
          const Text(
            "Monthly Expenses",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...monthlyData.entries.map((e) {
            return ListTile(
              title: Text(e.key),
              trailing: Text("₹${e.value}"),
            );
          }),

          const SizedBox(height: 20),

          // ---------------- RECENT TRANSACTIONS ----------------
          const Text(
            "Recent Transactions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...notifier.transactions.reversed.take(10).map((tx) {
            final isCredit = tx.type == TransactionStatus.credited;

            return Card(
              color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                leading: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
                title: Text(tx.purpose),
                subtitle: Text(
                  "${tx.type == TransactionStatus.credited ? "CREDIT" : "DEBIT"}",
                ),
                trailing: Text(
                  "₹${tx.amount}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------- SMALL WIDGET ----------------
  Widget _buildCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "₹$value",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- CATEGORY LOGIC ----------------
  Map<String, int> _getCategoryTotals(TransactionNotifier notifier) {
    Map<String, int> data = {};

    for (var tx in notifier.transactions) {
      if (tx.type == TransactionStatus.debited) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  // ---------------- MONTHLY LOGIC ----------------
  Map<String, int> _getMonthlyExpense(TransactionNotifier notifier) {
    Map<String, int> data = {};

    for (var tx in notifier.transactions) {
      if (tx.type == TransactionStatus.debited) {
        String month = "${tx.time.month}-${tx.time.year}";
        data[month] = (data[month] ?? 0) + tx.amount;
      }
    }

    return data;
  }
}