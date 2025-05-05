import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './providers/transaction_provider.dart';
import './screens/dashboard_screen.dart';
import './screens/transaction_list_screen.dart'; 
import './screens/add_edit_transaction_screen.dart';
import './screens/category_management_screen.dart';
import './screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TransactionProvider(),
      child: MaterialApp(
        title: 'Finance Tracker',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          // accentColor: Colors.amber, // accentColor is deprecated
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.purple).copyWith(secondary: Colors.amber),
          fontFamily: 'Quicksand', // Example font
          textTheme: ThemeData.light().textTheme.copyWith(
                titleLarge: TextStyle(
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
          appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: DashboardScreen(), // Use DashboardScreen as home
        routes: {
          AddEditTransactionScreen.routeName: (ctx) => AddEditTransactionScreen(),
          CategoryManagementScreen.routeName: (ctx) => CategoryManagementScreen(),
          SettingsScreen.routeName: (ctx) => SettingsScreen(), // Add Settings route
          // Add other routes if needed, e.g., for full transaction history
        },
      ),
    );
  }
}

// Placeholder Home Page - Replace with actual dashboard/transaction list later
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Tracker'),
      ),
      body: Center(
        child: Text('App Home - Implementation Pending'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to add transaction screen later
        },
      ),
    );
  }
}

