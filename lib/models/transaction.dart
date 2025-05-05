import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
  });
}

class Expense extends Transaction {
  final String categoryId;

  Expense({
    required String id,
    required double amount,
    required DateTime date,
    required String description,
    required this.categoryId,
  }) : super(
          id: id,
          amount: amount,
          date: date,
          description: description,
          type: TransactionType.expense,
        );
}

class Income extends Transaction {
  final String source;

  Income({
    required String id,
    required double amount,
    required DateTime date,
    required this.source,
    String description = '', // Description might be optional for income
  }) : super(
          id: id,
          amount: amount,
          date: date,
          description: description,
          type: TransactionType.income,
        );
}

