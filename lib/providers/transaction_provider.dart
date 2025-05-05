import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // For jsonEncode/Decode

import '../models/transaction.dart';
import '../models/category.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Category> _categories = [
    // Default categories
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
    Category(id: 'bills', name: 'Bills'),
    Category(id: 'entertainment', name: 'Entertainment'),
  ];

  List<Transaction> get transactions => [..._transactions];
  List<Category> get categories => [..._categories];

  List<Expense> get expenses => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .map((tx) => tx as Expense)
      .toList();

  List<Income> get income => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .map((tx) => tx as Income)
      .toList();

  var _uuid = Uuid();

  // --- Transaction Methods ---

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
    notifyListeners();
    // TODO: Persist data
  }

  void addExpense({
    required double amount,
    required DateTime date,
    required String description,
    required String categoryId,
  }) {
    final newExpense = Expense(
      id: _uuid.v4(),
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
    );
    addTransaction(newExpense);
  }

  void addIncome({
    required double amount,
    required DateTime date,
    required String source,
    String description = '',
  }) {
    final newIncome = Income(
      id: _uuid.v4(),
      amount: amount,
      date: date,
      source: source,
      description: description,
    );
    addTransaction(newIncome);
  }

  void updateTransaction(String id, Transaction updatedTransaction) {
    final txIndex = _transactions.indexWhere((tx) => tx.id == id);
    if (txIndex >= 0) {
      _transactions[txIndex] = updatedTransaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      // TODO: Persist data
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
    // TODO: Persist data
  }

  // --- Category Methods ---

  void addCategory(String name) {
    final newCategory = Category(id: _uuid.v4(), name: name);
    _categories.add(newCategory);
    notifyListeners();
     // TODO: Persist data
  }

  void updateCategory(String id, String newName) {
    final catIndex = _categories.indexWhere((cat) => cat.id == id);
    if (catIndex >= 0) {
      _categories[catIndex] = Category(id: id, name: newName);
      notifyListeners();
       // TODO: Persist data
    }
  }

  void deleteCategory(String id) {
    // Optional: Handle expenses associated with the deleted category
    // For simplicity now, we just delete the category.
    // A better approach might reassign expenses or prevent deletion if used.
    _categories.removeWhere((cat) => cat.id == id);
    // Update expenses that used this category to a default/uncategorized state if needed
    // _transactions = _transactions.map((tx) {
    //   if (tx is Expense && tx.categoryId == id) {
    //     // Example: Reassign to an 'uncategorized' category ID
    //     // return Expense(... tx properties ..., categoryId: 'uncategorized');
    //   }
    //   return tx;
    // }).toList();
    notifyListeners();
     // TODO: Persist data
  }

  Category? getCategoryById(String id) {
     try {
       return _categories.firstWhere((cat) => cat.id == id);
     } catch (e) {
       return null; // Return null if not found
     }
  }

  // --- Backup/Restore --- 

  Map<String, dynamic> toJson() {
    return {
      'transactions': _transactions.map((tx) {
        if (tx is Expense) {
          return {
            'id': tx.id,
            'amount': tx.amount,
            'date': tx.date.toIso8601String(),
            'description': tx.description,
            'type': 'expense',
            'categoryId': tx.categoryId,
          };
        } else if (tx is Income) {
          return {
            'id': tx.id,
            'amount': tx.amount,
            'date': tx.date.toIso8601String(),
            'description': tx.description,
            'type': 'income',
            'source': tx.source,
          };
        }
        return {}; // Should not happen
      }).toList(),
      'categories': _categories.map((cat) => {
        'id': cat.id,
        'name': cat.name,
      }).toList(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    try {
      final List<dynamic> loadedTransactions = json['transactions'] ?? [];
      final List<dynamic> loadedCategories = json['categories'] ?? [];

      _categories = loadedCategories.map((catData) {
        return Category(
          id: catData['id'] ?? _uuid.v4(), 
          name: catData['name'] ?? 'Unnamed Category',
        );
      }).toList();

      // Ensure default categories exist if missing in backup (optional, depends on desired behavior)
      // AddDefaultCategoriesIfNeeded(); 

      _transactions = loadedTransactions.map((txData) {
        final type = txData['type'];
        final id = txData['id'] ?? _uuid.v4();
        final amount = (txData['amount'] as num?)?.toDouble() ?? 0.0;
        final date = DateTime.tryParse(txData['date'] ?? '') ?? DateTime.now();
        final description = txData['description'] ?? '';

        if (type == 'expense') {
          final categoryId = txData['categoryId'] ?? '';
          // Ensure category exists, otherwise assign to a default/unknown
          final finalCategoryId = _categories.any((cat) => cat.id == categoryId) ? categoryId : (_categories.isNotEmpty ? _categories.first.id : 'unknown');
          return Expense(
            id: id,
            amount: amount,
            date: date,
            description: description,
            categoryId: finalCategoryId,
          );
        } else if (type == 'income') {
          final source = txData['source'] ?? '';
          return Income(
            id: id,
            amount: amount,
            date: date,
            description: description,
            source: source,
          );
        } else {
          // Handle unknown type or skip
          return null;
        }
      }).whereType<Transaction>().toList(); // Filter out nulls

      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
       // TODO: Persist data after restore
    } catch (error) {
      print("Error loading data from JSON: $error");
      // Optionally show an error message to the user
    }
  }

  // Helper to ensure default categories exist (call in fromJson if needed)
  void AddDefaultCategoriesIfNeeded() {
     final defaultIds = ['food', 'transport', 'bills', 'entertainment'];
     final defaultNames = ['Food', 'Transport', 'Bills', 'Entertainment'];
     for (int i = 0; i < defaultIds.length; i++) {
        if (!_categories.any((cat) => cat.id == defaultIds[i])) {
           _categories.add(Category(id: defaultIds[i], name: defaultNames[i]));
        }
     }
  }

}

