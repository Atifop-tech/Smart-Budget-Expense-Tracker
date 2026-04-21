import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saad_project_2/transaction_notifier.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final notifier = TransactionNotifier.instance;
  final TextEditingController _searchController = TextEditingController();

  TransactionStatus? _selectedType;
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        final filteredTransactions = notifier.searchTransactions(
          query: _searchController.text,
          type: _selectedType,
          category: _selectedCategory,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.76),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search purpose, category, source...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TypeFilterChip(
                              label: 'All',
                              selected: _selectedType == null,
                              onTap: () {
                                setState(() {
                                  _selectedType = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _TypeFilterChip(
                              label: 'Expense',
                              selected: _selectedType == TransactionStatus.debited,
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionStatus.debited;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _TypeFilterChip(
                              label: 'Income',
                              selected: _selectedType == TransactionStatus.credited,
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionStatus.credited;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ...categories].map((category) {
                            final selected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Text(
                    '${filteredTransactions.length} result${filteredTransactions.length == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF172036),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Net ${_formatCurrency(notifier.total)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5F6B7A),
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          'No transactions match the current filters.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(tx.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => notifier.deleteTransaction(tx.id),
                            child: _TransactionCard(
                              transaction: tx,
                              onEdit: () => _showEditDialog(context, tx),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, Transaction tx) async {
    final navigator = Navigator.of(context);
    final purposeController = TextEditingController(text: tx.purpose);
    final amountController = TextEditingController(text: tx.amount.toString());
    String selectedCategory = tx.category;
    TransactionStatus selectedType = tx.type;

    final updatedTransaction = await showDialog<_PendingTransactionUpdate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<TransactionStatus>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionStatus.debited,
                          label: Text('Expense'),
                        ),
                        ButtonSegment(
                          value: TransactionStatus.credited,
                          label: Text('Income'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          selectedType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'Rs ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = int.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) return;

                    navigator.pop(
                      _PendingTransactionUpdate(
                        purpose: purposeController.text,
                        amount: amount,
                        type: selectedType,
                        category: selectedCategory,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    purposeController.dispose();
    amountController.dispose();

    if (updatedTransaction != null) {
      notifier.updateTransaction(
        id: tx.id,
        purpose: updatedTransaction.purpose,
        amount: updatedTransaction.amount,
        type: updatedTransaction.type,
        category: updatedTransaction.category,
      );
    }
  }
}

class _PendingTransactionUpdate {
  const _PendingTransactionUpdate({
    required this.purpose,
    required this.amount,
    required this.type,
    required this.category,
  });

  final String purpose;
  final int amount;
  final TransactionStatus type;
  final String category;
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
  });

  final Transaction transaction;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final accent = isCredit ? const Color(0xFF15803D) : const Color(0xFFB45309);
    final soft = isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.58)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.purpose,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172036),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${transaction.category} • ${transaction.source} • ${_formatDate(transaction.time)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFCCFBF1),
      backgroundColor: Colors.white.withOpacity(0.8),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF115E59) : const Color(0xFF475569),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

String _formatCurrency(int amount) => 'Rs ${amount.toString()}';

String _formatDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
