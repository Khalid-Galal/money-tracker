import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatelessWidget {
  static const routeName = '/manage-categories';

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<TransactionProvider>(context);
    final categories = categoryProvider.categories;

    void _showAddEditCategoryDialog({Category? existingCategory}) {
      final _nameController = TextEditingController(
        text: existingCategory?.name,
      );
      final _formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(existingCategory == null ? 'Add Category' : 'Edit Category'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name.';
                }
                // Optional: Check for duplicate names
                if (existingCategory == null && categoryProvider.categories.any((cat) => cat.name.toLowerCase() == value.toLowerCase())) {
                   return 'Category name already exists.';
                }
                 if (existingCategory != null && existingCategory.name.toLowerCase() != value.toLowerCase() && categoryProvider.categories.any((cat) => cat.name.toLowerCase() == value.toLowerCase())) {
                   return 'Category name already exists.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text;
                  if (existingCategory == null) {
                    categoryProvider.addCategory(name);
                  } else {
                    categoryProvider.updateCategory(existingCategory.id, name);
                  }
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      );
    }

    void _confirmDeleteCategory(String id, String name) {
       showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete Category?'),
          content: Text('Are you sure you want to delete the category "$name"? Expenses in this category might need reassignment (feature not yet implemented).'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                categoryProvider.deleteCategory(id);
                Navigator.of(ctx).pop();
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$name" deleted.'))
                 );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Categories'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddEditCategoryDialog(),
          ),
        ],
      ),
      body: categories.isEmpty
          ? Center(child: Text('No categories defined yet.'))
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (ctx, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () => _showAddEditCategoryDialog(existingCategory: category),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _confirmDeleteCategory(category.id, category.name),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

