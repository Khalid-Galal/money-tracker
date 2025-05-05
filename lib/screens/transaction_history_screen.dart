import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../screens/transaction_list_screen.dart'; // Re-use TransactionItem

enum FilterType { all, income, expense }

class TransactionHistoryScreen extends StatefulWidget {
  static const routeName = '/transaction-history';

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  FilterType _selectedFilterType = FilterType.all;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categories = transactionProvider.categories;

    List<Transaction> filteredTransactions = transactionProvider.transactions;

    // Apply type filter
    if (_selectedFilterType == FilterType.income) {
      filteredTransactions = transactionProvider.income;
    } else if (_selectedFilterType == FilterType.expense) {
      filteredTransactions = transactionProvider.expenses;
    }

    // Apply category filter (only if filtering for expenses)
    if (_selectedFilterType == FilterType.expense && _selectedCategoryId != null) {
      filteredTransactions = (filteredTransactions as List<Expense>)
          .where((exp) => exp.categoryId == _selectedCategoryId)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
        // TODO: Add more advanced filtering options (date range, search) later
      ),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Type Filter Dropdown
                DropdownButton<FilterType>(
                  value: _selectedFilterType,
                  items: FilterType.values.map((FilterType type) {
                    return DropdownMenuItem<FilterType>(
                      value: type,
                      child: Text(type.toString().split('.').last.capitalize()),
                    );
                  }).toList(),
                  onChanged: (FilterType? newValue) {
                    setState(() {
                      _selectedFilterType = newValue!;
                      // Reset category filter if not filtering expenses
                      if (_selectedFilterType != FilterType.expense) {
                        _selectedCategoryId = null;
                      }
                    });
                  },
                ),
                // Category Filter Dropdown (visible only for expenses)
                if (_selectedFilterType == FilterType.expense)
                  DropdownButton<String?>(
                    value: _selectedCategoryId,
                    hint: Text('All Categories'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map((Category category) {
                        return DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                  ),
              ],
            ),
          ),
          Divider(),
          // Transaction List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Text('No transactions match the filter.'),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = filteredTransactions[index];
                      // Reuse the TransactionItem widget from TransactionListScreen
                      return TransactionItem(transaction: tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
}

