import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  // --- CSV Export ---
  Future<void> _exportDataToCsv(BuildContext context) async {
    // ... (CSV export code remains the same)
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    final categories = transactionProvider.categories;

    if (transactions.isEmpty && categories.length <= 4) { // Check if only default categories exist
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add([
      'ID', 'Type', 'Date', 'Amount', 'Description', 'Category/Source', 'CategoryID_if_Expense'
    ]);

    for (var tx in transactions) {
      String categoryOrSource = '';
      String categoryId = '';
      if (tx is Expense) {
        final category = categories.firstWhere((cat) => cat.id == tx.categoryId, orElse: () => Category(id: 'unknown', name: 'Unknown'));
        categoryOrSource = category.name;
        categoryId = tx.categoryId;
      } else if (tx is Income) {
        categoryOrSource = tx.source;
      }

      rows.add([
        tx.id,
        tx.type.toString().split('.').last,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.date),
        tx.amount,
        tx.description,
        categoryOrSource,
        categoryId,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      try {
        Directory? directory;
        if (Platform.isAndroid) {
           directory = await getExternalStoragePublicDirectory(ExternalStoragePublicDirectory.Downloads);
           if (directory == null) { 
              directory = await getExternalStorageDirectory();
           }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
           throw Exception("Could not access storage directory.");
        }

        final String filePath = '${directory.path}/finance_tracker_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final File file = File(filePath);
        await file.writeAsString(csvData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported successfully to ${filePath}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied. Cannot export data.')),
      );
    }
  }

  // --- JSON Backup ---
  Future<void> _backupData(BuildContext context) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final backupData = transactionProvider.toJson(); // Assuming toJson exists in provider
    final jsonString = jsonEncode(backupData);

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

     if (status.isGranted) {
      try {
        Directory? directory;
        // Save to Documents directory for backups
        directory = await getApplicationDocumentsDirectory(); 

        if (directory == null) {
           throw Exception("Could not access storage directory.");
        }

        final String filePath = '${directory.path}/finance_tracker_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
        final File file = File(filePath);
        await file.writeAsString(jsonString);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data backed up successfully to ${filePath}')),
        );
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error backing up data: ${e.toString()}')),
        );
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied. Cannot backup data.')),
      );
    }
  }

  // --- JSON Restore ---
  Future<void> _restoreData(BuildContext context) async {
     // TODO: Implement file picker to select backup file
     // For now, assume a fixed file path for simplicity (replace later)
     var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
       try {
          Directory? directory = await getApplicationDocumentsDirectory();
          if (directory == null) throw Exception("Could not access storage directory.");
          
          // --- This needs a file picker --- 
          // Hardcoding filename for now - VERY BAD PRACTICE
          final String filePath = '${directory.path}/finance_tracker_backup.json'; // Needs to be selectable
          final File file = File(filePath);

          if (!await file.exists()) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Backup file not found at ${filePath}. Please select a file.')),
             );
             return;
          }

          final jsonString = await file.readAsString();
          final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

          // Show confirmation dialog
          bool confirmed = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Confirm Restore'),
              content: Text('Restoring data will overwrite current data. Are you sure?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Restore')),
              ],
            ),
          ) ?? false;

          if (confirmed) {
            final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
            transactionProvider.fromJson(backupData); // Assuming fromJson exists
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data restored successfully.')),
            );
          }

       } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error restoring data: ${e.toString()}')),
          );
       }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied. Cannot restore data.')),
      );
    }
  }

   // Placeholder for Security Settings Navigation
  void _navigateToSecuritySettings(BuildContext context) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Security settings not yet implemented.')),
      );
    // TODO: Navigate to a new screen for PIN/Biometric setup
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings & Utilities'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.import_export),
            title: Text('Export Data to CSV'),
            subtitle: Text('Save all transactions to a CSV file in Downloads.'),
            onTap: () => _exportDataToCsv(context),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup Data'),
            subtitle: Text('Create a local backup file (JSON).'),
            onTap: () => _backupData(context),
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Restore Data'),
            subtitle: Text('Restore data from a local backup file (JSON).'),
            onTap: () => _restoreData(context),
          ),
          Divider(),
           ListTile(
            leading: Icon(Icons.security),
            title: Text('App Security'),
            subtitle: Text('Set up PIN or Biometric lock (Not Implemented).'),
            onTap: () => _navigateToSecuritySettings(context),
          ),
        ],
      ),
    );
  }
}

// Helper function for Android external storage public directory
Future<Directory?> getExternalStoragePublicDirectory(String type) async {
  if (!Platform.isAndroid) {
    return null;
  }
  // Use getExternalStorageDirectories which is more reliable
  List<Directory>? directories = await getExternalStorageDirectories(type: StorageDirectory.downloads);
  if (directories != null && directories.isNotEmpty) {
      // Usually the first path is the primary external storage
      final publicDir = Directory(directories[0].path.split('/Android/')[0] + '/$type');
       try {
         if (!await publicDir.exists()) {
           await publicDir.create(recursive: true);
         }
         return publicDir;
      } catch (e) {
         print("Error accessing public directory: $e");
         return directories[0]; // Fallback to app-specific external dir
      }
  }
  // Fallback if specific type not found or error occurs
  return await getExternalStorageDirectory(); 
}

