import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class MonthlyComparisonChart extends StatelessWidget {
  final int numberOfMonthsToShow;

  const MonthlyComparisonChart({this.numberOfMonthsToShow = 6});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final allTransactions = transactionProvider.transactions;

    // Calculate monthly totals for the last N months
    Map<String, Map<String, double>> monthlyTotals = {};
    DateTime now = DateTime.now();

    for (int i = 0; i < numberOfMonthsToShow; i++) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      String monthKey = DateFormat('yyyy-MM').format(monthDate);
      monthlyTotals[monthKey] = {'income': 0.0, 'expense': 0.0};
    }

    for (var tx in allTransactions) {
      String monthKey = DateFormat('yyyy-MM').format(tx.date);
      if (monthlyTotals.containsKey(monthKey)) {
        if (tx.type == TransactionType.income) {
          monthlyTotals[monthKey]!['income'] = (monthlyTotals[monthKey]!['income'] ?? 0.0) + tx.amount;
        } else {
          monthlyTotals[monthKey]!['expense'] = (monthlyTotals[monthKey]!['expense'] ?? 0.0) + tx.amount;
        }
      }
    }

    // Prepare data for the bar chart
    List<BarChartGroupData> barGroups = [];
    List<String> sortedMonths = monthlyTotals.keys.toList()..sort(); // Sort chronologically
    double maxY = 0; // To determine the max Y value for the chart

    for (int i = 0; i < sortedMonths.length; i++) {
      String monthKey = sortedMonths[i];
      double income = monthlyTotals[monthKey]!['income'] ?? 0.0;
      double expense = monthlyTotals[monthKey]!['expense'] ?? 0.0;

      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 16,
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.red,
              width: 16,
            ),
          ],
        ),
      );
    }

    // Adjust maxY for better visualization
    maxY = (maxY * 1.2).ceilToDouble(); // Add 20% padding
    if (maxY == 0) maxY = 100; // Avoid zero max Y

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Monthly Income vs Expenses (Last $numberOfMonthsToShow Months)',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 38),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String month = DateFormat('MMM').format(DateFormat('yyyy-MM').parse(sortedMonths[group.x]));
                          String type = rodIndex == 0 ? 'Income' : 'Expense';
                          return BarTooltipItem(
                            '$month\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            children: <TextSpan>[
                              TextSpan(
                                text: '$type: \$${rod.toY.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: rod.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedMonths.length) {
                              String month = DateFormat('MMM').format(DateFormat('yyyy-MM').parse(sortedMonths[index]));
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4,
                                child: Text(month, style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return Container();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                           getTitlesWidget: (double value, TitleMeta meta) {
                              // Show labels only at reasonable intervals
                              if (value == 0 || value == maxY || value == maxY / 2) {
                                return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                              }
                              return Container();
                           },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

