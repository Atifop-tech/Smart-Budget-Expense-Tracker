import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saad_project_2/transaction_notifier.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = TransactionNotifier.instance;

    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        final categoryData = notifier.getCategoryTotals();
        final weeklyData = notifier.getWeeklySpending();
        final biggestExpense = notifier.biggestExpenseTransaction;
        final budgetAccent = notifier.budgetStatusColor;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          children: [
            _HeroBalanceCard(notifier: notifier),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    title: 'Top category',
                    value: notifier.topCategory,
                    icon: Icons.local_fire_department_rounded,
                    accent: const Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightTile(
                    title: 'This week',
                    value: _formatSignedCurrency(notifier.weekNetFlow),
                    icon: Icons.show_chart_rounded,
                    accent: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    title: 'Transactions',
                    value: '${notifier.transactionCount}',
                    icon: Icons.layers_rounded,
                    accent: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightTile(
                    title: 'Average spend',
                    value: _formatCurrency(notifier.averageExpense.round()),
                    icon: Icons.analytics_rounded,
                    accent: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Budget pulse',
              subtitle: 'Monthly spending against your current target',
              trailing: TextButton.icon(
                onPressed: () => _showBudgetEditor(context, notifier),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Update'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: budgetAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: budgetAccent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            notifier.isOverBudget
                                ? Icons.warning_amber_rounded
                                : Icons.track_changes_rounded,
                            color: budgetAccent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notifier.budgetStatusLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF172036),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notifier.budgetStatusDescription,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5F6B7A),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPill(
                          label: 'Budget target',
                          value: _formatCurrency(notifier.monthlyBudget),
                          tint: const Color(0xFFE0F2FE),
                          valueColor: const Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPill(
                          label: 'Daily allowance',
                          value: _formatCurrency(notifier.dailyBudgetAllowance),
                          tint: const Color(0xFFF3E8FF),
                          valueColor: const Color(0xFF7E22CE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 14,
                      value: notifier.budgetProgress,
                      backgroundColor: const Color(0xFFE7E5E4),
                      valueColor: AlwaysStoppedAnimation<Color>(budgetAccent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(notifier.rawBudgetProgress * 100).toStringAsFixed(0)}% of monthly target used',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPill(
                          label: 'Spent',
                          value: _formatCurrency(notifier.spentThisMonth),
                          tint: const Color(0xFFFFEDD5),
                          valueColor: const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPill(
                          label: notifier.isOverBudget ? 'Over budget' : 'Remaining',
                          value: _formatCurrency(
                            notifier.isOverBudget
                                ? notifier.overBudgetAmount
                                : notifier.safeBudgetRemaining,
                          ),
                          tint: notifier.isOverBudget
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFCCFBF1),
                          valueColor: notifier.isOverBudget
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF115E59),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Category breakdown',
              subtitle: 'Where your money is going this cycle',
              child: categoryData.isEmpty
                  ? const _EmptyState(message: 'Add expenses to reveal spending categories.')
                  : Column(
                      children: categoryData.entries.map((entry) {
                        final highest = categoryData.values.reduce(math.max).toDouble();
                        final progress = highest == 0 ? 0.0 : entry.value / highest;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(entry.key),
                                  const Spacer(),
                                  Text(
                                    _formatCurrency(entry.value),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  value: progress,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Weekly spending rhythm',
              subtitle: 'Last 7 days of expenses',
              child: weeklyData.values.every((amount) => amount == 0)
                  ? const _EmptyState(message: 'Your last 7 days are clear. New expenses will appear here.')
                  : SizedBox(
                      height: 170,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyData.entries.map((entry) {
                          final maxValue = weeklyData.values.reduce(math.max).toDouble();
                          final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    entry.value == 0 ? '-' : '₹${entry.value}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    height: 22 + (ratio * 90),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFF0F766E),
                                          Color(0xFF5EEAD4),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(entry.key),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Spotlight',
              subtitle: 'A quick look at your biggest outgoing payment',
              child: biggestExpense == null
                  ? const _EmptyState(message: 'No debit transactions yet.')
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                      title: Text(
                        biggestExpense.purpose,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${biggestExpense.category} • ${_formatDate(biggestExpense.time)}',
                      ),
                      trailing: Text(
                        _formatCurrency(biggestExpense.amount),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBE123C),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBudgetEditor(BuildContext context, TransactionNotifier notifier) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: notifier.monthlyBudget.toString());
    String? errorText;
    int previewBudget = notifier.monthlyBudget;
    final presetBudgets = <int>[
      10000,
      15000,
      25000,
      40000,
      math.max(notifier.spentThisMonth, 5000),
    ].toSet().toList()
      ..sort();

    final updatedBudget = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final previewRemaining = previewBudget - notifier.spentThisMonth;
            final previewOverBudget =
                previewRemaining < 0 ? previewRemaining.abs() : 0;
            final previewDailyAllowance = _calculateDailyAllowance(
              previewRemaining < 0 ? 0 : previewRemaining,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adjust monthly budget',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF172036),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set a target that matches your current spending pace.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current month snapshot',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF172036),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _BudgetPreviewTile(
                                  label: 'Spent so far',
                                  value: _formatCurrency(notifier.spentThisMonth),
                                  valueColor: const Color(0xFF9A3412),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _BudgetPreviewTile(
                                  label: 'Current target',
                                  value: _formatCurrency(notifier.monthlyBudget),
                                  valueColor: const Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value.trim());
                        setSheetState(() {
                          if (parsed == null || parsed <= 0) {
                            errorText = 'Enter a valid positive amount.';
                            return;
                          }
                          previewBudget = parsed;
                          errorText = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Monthly budget',
                        prefixText: 'Rs ',
                        hintText: 'Enter target budget',
                        errorText: errorText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Quick presets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetBudgets.map((preset) {
                          final selected = preset == previewBudget;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_formatCurrency(preset)),
                              selected: selected,
                              onSelected: (_) {
                                controller.text = preset.toString();
                                setSheetState(() {
                                  previewBudget = preset;
                                  errorText = null;
                                });
                              },
                              selectedColor: const Color(0xFFCCFBF1),
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: selected
                                    ? const Color(0xFF115E59)
                                    : const Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: previewRemaining < 0
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF172036),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _BudgetPreviewTile(
                                  label: previewRemaining < 0
                                      ? 'You would be over'
                                      : 'You would have left',
                                  value: _formatCurrency(
                                    previewRemaining < 0
                                        ? previewOverBudget
                                        : previewRemaining,
                                  ),
                                  valueColor: previewRemaining < 0
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF047857),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _BudgetPreviewTile(
                                  label: 'Daily allowance',
                                  value: _formatCurrency(previewDailyAllowance),
                                  valueColor: const Color(0xFF6D28D9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => navigator.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final value = int.tryParse(controller.text.trim());
                              if (value == null || value <= 0) {
                                setSheetState(() {
                                  errorText = 'Enter a valid positive amount.';
                                });
                                return;
                              }

                              navigator.pop(value);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save budget'),
                          ),
                        ),
                      ],
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
    controller.dispose();

    if (updatedBudget != null) {
      notifier.setMonthlyBudget(updatedBudget);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Monthly budget updated to ${_formatCurrency(updatedBudget)}.',
          ),
        ),
      );
    }
  }

  int _calculateDailyAllowance(int remainingBudget) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDayOfMonth - now.day) + 1;
    if (remainingDays <= 0) return remainingBudget;
    return (remainingBudget / remainingDays).floor();
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.notifier});

  final TransactionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0F766E),
            Color(0xFF14B8A6),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x300F766E),
            blurRadius: 32,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Available balance',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(Icons.wallet_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatCurrency(notifier.total),
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notifier.total >= 0
                ? 'You are operating in positive cash flow.'
                : 'Outgoing cash is leading this cycle.',
            style: const TextStyle(color: Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Income',
                  value: _formatCurrency(notifier.totalCredit),
                  accent: const Color(0xFFBBF7D0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceStat(
                  label: 'Expenses',
                  value: _formatCurrency(notifier.totalDebit),
                  accent: const Color(0xFFFED7AA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172036),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF172036),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.tint,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color tint;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPreviewTile extends StatelessWidget {
  const _BudgetPreviewTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
      ),
    );
  }
}

String _formatCurrency(int amount) => 'Rs ${amount.toString()}';

String _formatSignedCurrency(int amount) => '${amount >= 0 ? '+' : '-'}${_formatCurrency(amount.abs())}';

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
  return '${date.day} ${months[date.month - 1]}';
}
