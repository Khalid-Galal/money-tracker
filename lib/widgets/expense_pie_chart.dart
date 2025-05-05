import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class ExpensePieChart extends StatefulWidget {
  final DateTime selectedMonth;

  const ExpensePieChart({required this.selectedMonth});

  @override
  State<StatefulWidget> createState() => ExpensePieChartState();
}

class ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final expensesForMonth = transactionProvider.expenses.where((exp) {
      return exp.date.year == widget.selectedMonth.year &&
             exp.date.month == widget.selectedMonth.month;
    }).toList();

    if (expensesForMonth.isEmpty) {
      return Center(
        child: Text(
          'No expense data for ${widget.selectedMonth.year}-${widget.selectedMonth.month}',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Aggregate expenses by category
    Map<String, double> categoryTotals = {};
    double totalMonthlyExpense = 0;
    for (var exp in expensesForMonth) {
      categoryTotals.update(exp.categoryId, (value) => value + exp.amount, ifAbsent: () => exp.amount);
      totalMonthlyExpense += exp.amount;
    }

    List<PieChartSectionData> showingSections() {
      int index = -1;
      return categoryTotals.entries.map((entry) {
        index++;
        final isTouched = index == touchedIndex;
        final fontSize = isTouched ? 20.0 : 14.0;
        final radius = isTouched ? 110.0 : 100.0;
        final category = transactionProvider.getCategoryById(entry.key);
        final categoryName = category?.name ?? 'Unknown';
        final percentage = totalMonthlyExpense > 0 ? (entry.value / totalMonthlyExpense * 100) : 0;

        // Assign colors based on index or category ID hash for variety
        final colorValue = category?.id.hashCode ?? index;
        final color = Colors.primaries[colorValue % Colors.primaries.length].shade300;

        return PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%', // Show percentage
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text on colored background
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
          // Optional: Add badge for category name on touch
          // badgeWidget: isTouched ? _Badge(categoryName, color: color) : null,
          // badgePositionPercentageOffset: .98,
        );
      }).toList();
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text(
                 'Expense Breakdown by Category',
                 style: Theme.of(context).textTheme.titleMedium,
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 18),
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40, // Make it a donut chart
                    sections: showingSections(),
                  ),
                ),
              ),
              // TODO: Add Legend here
               const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// Optional Badge Widget (Example)
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

