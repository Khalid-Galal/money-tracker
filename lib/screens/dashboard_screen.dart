import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import './category_management_screen.dart'; // Import category managementimport ".//add_edit_transaction_screen.dart";
import "../widgets/expense_pie_chart.dart";
import "../widgets/monthly_comparison_chart.dart";

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _changeMonth(int monthDelta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthDelta,
        1, // Go to the first day of the month
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactionsForMonth = transactionProvider.transactions.where((tx) {
      return tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month;
    }).toList();

    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (var tx in transactionsForMonth) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpenses += tx.amount;
      }
    }

    double netBalance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          // Add navigation to category management
          IconButton(
            icon: Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.of(context).pushNamed(CategoryManagementScreen.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat.yMMM().format(_selectedMonth),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Divider(),
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SummaryCard(
                  title: 'Total Income',
                  amount: totalIncome,
                  color: Colors.green,
                ),
                SizedBox(height: 10),
                SummaryCard(
                  title: 'Total Expenses',
                  amount: totalExpenses,
                  color: Colors.red,
                ),
                SizedBox(height: 10),
                SummaryCard(
                  title: 'Net Balance',
                  amount: netBalance,
                  color: netBalance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),
          Divider(),
          // Add Charts here
          Expanded(
            child: ListView( // Use ListView to allow scrolling if charts take space
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                ExpensePieChart(selectedMonth: _selectedMonth),
                SizedBox(height: 20),
                MonthlyComparisonChart(), // Add the monthly comparison chart
                SizedBox(height: 20), // Add some spacing
              ],
            ),
          ),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
        onPressed: () {
          Navigator.of(context).pushNamed(AddEditTransactionScreen.routeName);
        },
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

