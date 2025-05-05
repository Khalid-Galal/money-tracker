import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class TransactionListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(AddEditTransactionScreen.routeName);
            },
          ),
        ],
      ),
      body: transactions.isEmpty
          ? Center(
              child: Text('No transactions added yet!'),
            )
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (ctx, index) {
                final tx = transactions[index];
                return TransactionItem(transaction: tx);
              },
            ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<TransactionProvider>(context, listen: false);
    String categoryName = 'N/A';
    String titlePrefix = '';
    Color amountColor = Colors.black;

    if (transaction is Expense) {
      final expense = transaction as Expense;
      final category = categoryProvider.getCategoryById(expense.categoryId);
      categoryName = category?.name ?? 'Unknown Category';
      titlePrefix = 'Expense: ';
      amountColor = Colors.red;
    } else if (transaction is Income) {
      final income = transaction as Income;
      categoryName = 'Source: ${income.source}';
      titlePrefix = 'Income: ';
      amountColor = Colors.green;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: FittedBox(
              child: Text('\$${transaction.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)),
            ),
          ),
          backgroundColor: transaction.type == TransactionType.expense ? Colors.red[300] : Colors.green[300],
        ),
        title: Text(
          '$titlePrefix${transaction.description.isNotEmpty ? transaction.description : categoryName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          '${DateFormat.yMMMd().format(transaction.date)} ${transaction.type == TransactionType.expense ? "($categoryName)" : ""}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AddEditTransactionScreen.routeName,
                  arguments: transaction, // Pass the transaction to edit
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("Are you sure?"),
                    content: Text("Do you want to remove this transaction?"),
                    actions: <Widget>[
                      TextButton(
                        child: Text("No"),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        child: Text("Yes"),
                        onPressed: () {
                          Provider.of<TransactionProvider>(context, listen: false)
                              .deleteTransaction(transaction.id);
                          Navigator.of(ctx).pop(); // Close the dialog
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Transaction deleted."))
                           );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        // onTap: () { // Can use onTap or edit button
        //   Navigator.of(context).pushNamed(
        //     AddEditTransactionScreen.routeName,
        //     arguments: transaction,
        //   );
        // },
      ),
    );
  }
}

