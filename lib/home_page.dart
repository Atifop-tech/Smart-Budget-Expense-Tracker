import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saad_project_2/dashboard.dart';
import 'package:saad_project_2/history.dart';
import 'package:saad_project_2/transaction_notifier.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardPage(), const History()];

    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            indicatorColor: const Color(0xFFCCFBF1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
            ],
            onDestinationSelected: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4EDE1), Color(0xFFF7F4EE), Color(0xFFE6F7F2)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -30,
              child: _BlurOrb(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                size: 210,
              ),
            ),
            Positioned(
              top: 120,
              right: -60,
              child: _BlurOrb(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.18),
                size: 230,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Budget',
                                style: GoogleFonts.outfit(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF172036),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currentIndex == 0
                                    ? 'Elegant money tracking with live insights'
                                    : 'Search, filter, and manage every transaction',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF5F6B7A)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: pages[_currentIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTransactionSheet(BuildContext context) async {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    String selectedCategory = categories.first;
    TransactionStatus selectedType = TransactionStatus.debited;

    final pendingTransaction =
        await showModalBottomSheet<_PendingTransactionCreate>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.88,
                    ),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF5),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a transaction',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF172036),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Capture cash flow manually in a few seconds.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF627082)),
                            ),
                            const SizedBox(height: 18),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<TransactionStatus>(
                                segments: const [
                                  ButtonSegment(
                                    value: TransactionStatus.debited,
                                    icon: Icon(Icons.arrow_upward_rounded),
                                    label: Text('Expense'),
                                  ),
                                  ButtonSegment(
                                    value: TransactionStatus.credited,
                                    icon: Icon(Icons.arrow_downward_rounded),
                                    label: Text('Income'),
                                  ),
                                ],
                                selected: {selectedType},
                                onSelectionChanged: (selection) {
                                  setModalState(() {
                                    selectedType = selection.first;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: purposeController,
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                hintText: 'Groceries, salary, rent, coffee...',
                              ),
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
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
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
                                setModalState(() {
                                  selectedCategory = value;
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  final amount = int.tryParse(
                                    amountController.text.trim(),
                                  );
                                  if (amount == null || amount <= 0) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Enter a valid amount.'),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(sheetContext).pop(
                                    _PendingTransactionCreate(
                                      purpose: purposeController.text,
                                      amount: amount,
                                      type: selectedType,
                                      category: selectedCategory,
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                ),
                                child: const Text('Save transaction'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

    amountController.dispose();
    purposeController.dispose();

    if (!context.mounted || pendingTransaction == null) return;

    TransactionNotifier.instance.addTransaction(
      pendingTransaction.amount,
      pendingTransaction.type,
      pendingTransaction.category,
      purpose: pendingTransaction.purpose,
    );
  }
}

class _PendingTransactionCreate {
  const _PendingTransactionCreate({
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

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.02)],
        ),
      ),
    );
  }
}
