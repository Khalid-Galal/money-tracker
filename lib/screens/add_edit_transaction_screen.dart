import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

enum FormMode { add, edit }

class AddEditTransactionScreen extends StatefulWidget {
  static const routeName = '/add-edit-transaction';

  final Transaction? existingTransaction;

  AddEditTransactionScreen({this.existingTransaction});

  @override
  _AddEditTransactionScreenState createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController(); // For income

  FormMode _mode = FormMode.add;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _mode = FormMode.edit;
      _editingId = widget.existingTransaction!.id;
      _selectedType = widget.existingTransaction!.type;
      _amountController.text = widget.existingTransaction!.amount.toStringAsFixed(2);
      _selectedDate = widget.existingTransaction!.date;
      _descriptionController.text = widget.existingTransaction!.description;

      if (widget.existingTransaction is Expense) {
        _selectedCategoryId = (widget.existingTransaction as Expense).categoryId;
      } else if (widget.existingTransaction is Income) {
        _sourceController.text = (widget.existingTransaction as Income).source;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      // Basic validation, more robust needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    if (_selectedType == TransactionType.expense) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a category.')),
        );
        return;
      }
      final newExpense = Expense(
        id: _mode == FormMode.add ? Uuid().v4() : _editingId!,
        amount: enteredAmount,
        date: _selectedDate,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId!,
      );
      if (_mode == FormMode.add) {
        transactionProvider.addTransaction(newExpense);
      } else {
        transactionProvider.updateTransaction(_editingId!, newExpense);
      }
    } else {
      // Income
      if (_sourceController.text.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter an income source.')),
        );
        return;
      }
      final newIncome = Income(
        id: _mode == FormMode.add ? Uuid().v4() : _editingId!,
        amount: enteredAmount,
        date: _selectedDate,
        source: _sourceController.text,
        description: _descriptionController.text, // Optional description
      );
       if (_mode == FormMode.add) {
        transactionProvider.addTransaction(newIncome);
      } else {
        transactionProvider.updateTransaction(_editingId!, newIncome);
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<TransactionProvider>(context).categories;
    // Ensure _selectedCategoryId is valid if editing an expense
    if (_mode == FormMode.edit && _selectedType == TransactionType.expense) {
        if (!categories.any((cat) => cat.id == _selectedCategoryId)) {
            _selectedCategoryId = null; // Reset if category was deleted
        }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == FormMode.add ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitData,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Type Selector (Income/Expense)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Expense'),
                    Radio<TransactionType>(
                      value: TransactionType.expense,
                      groupValue: _selectedType,
                      onChanged: (TransactionType? value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    Text('Income'),
                    Radio<TransactionType>(
                      value: TransactionType.income,
                      groupValue: _selectedType,
                      onChanged: (TransactionType? value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount.';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Please enter an amount greater than zero.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description (Optional)'),
                  // validator: (value) { // Description is optional
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter a description.';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: 10),
                // Category Dropdown (for Expense)
                if (_selectedType == TransactionType.expense)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    hint: Text('Select Category'),
                    items: categories.map((Category category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a category' : null,
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                // Source Input (for Income)
                if (_selectedType == TransactionType.income)
                  TextFormField(
                    controller: _sourceController,
                    decoration: InputDecoration(labelText: 'Source'),
                     validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an income source.';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No Date Chosen!'
                            : 'Picked Date: ${DateFormat.yMd().format(_selectedDate)}',
                      ),
                    ),
                    TextButton(
                      child: Text(
                        'Choose Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _presentDatePicker,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

