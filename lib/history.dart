import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transaction_notifier.dart';

class History extends StatefulWidget {
  final int? curr;
  const History({super.key, this.curr});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final notifier = TransactionNotifier.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Total: Rs ${notifier.total}",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: notifier.transactions.isEmpty
                    ? const Center(child: Text("No transactions"))
                    : ListView.builder(
                        itemCount: notifier.transactions.length,
                        itemBuilder: (context, index) {
                          final tx = notifier.transactions[index];

                          return Card(
                            color: tx.type == TransactionStatus.credited ? Colors.green : Colors.red,
                            child: ListTile(
                              title: TextField(
                                controller:
                                    notifier.controllers[index],
                                onChanged: (value) =>
                                    notifier.updatePurpose(index, value),
                              ),
                              subtitle: Text("Rs ${tx.amount}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    notifier.deleteTransaction(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}