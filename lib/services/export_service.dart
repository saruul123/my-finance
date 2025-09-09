import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/settings.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _databaseService = DatabaseService.instance;

  Future<bool> exportData(FileFormat format) async {
    try {
      final settings = _databaseService.getSettings();
      final fileName = settings.getFormattedFileName();

      switch (format) {
        case FileFormat.csv:
          return await _exportToCsv(fileName);
        case FileFormat.json:
          return await _exportToJson(fileName);
        case FileFormat.excel:
          return await _exportToExcel(fileName);
      }
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  Future<bool> _exportToCsv(String baseFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Export transactions
      final transactions = _databaseService.getAllTransactions();
      final transactionsCsvFile = File(
        '${directory.path}/${baseFileName}_transactions.csv',
      );

      final transactionsData = [
        [
          'ID',
          'Type',
          'Category',
          'Amount',
          'Currency',
          'Date',
          'Note',
          'Created At',
          'Updated At',
        ],
        ...transactions.map(
          (t) => [
            t.id,
            t.type.toString().split('.').last,
            t.category,
            t.amount.toString(),
            t.currency,
            t.date.toIso8601String(),
            t.note,
            t.createdAt.toIso8601String(),
            t.updatedAt.toIso8601String(),
          ],
        ),
      ];

      final transactionsCsv = const ListToCsvConverter().convert(
        transactionsData,
      );
      await transactionsCsvFile.writeAsString(transactionsCsv);

      // Export loans
      final loans = _databaseService.getAllLoans();
      final loansCsvFile = File('${directory.path}/${baseFileName}_loans.csv');

      final loansData = [
        [
          'ID',
          'Name',
          'Principal',
          'Monthly Payment',
          'Interest Rate',
          'Start Date',
          'End Date',
          'Remaining Balance',
          'Created At',
          'Updated At',
        ],
        ...loans.map(
          (l) => [
            l.id,
            l.name,
            l.principal.toString(),
            l.monthlyPayment.toString(),
            l.interestRate.toString(),
            l.startDate.toIso8601String(),
            l.endDate?.toIso8601String() ?? '',
            l.remainingBalance.toString(),
            l.createdAt.toIso8601String(),
            l.updatedAt.toIso8601String(),
          ],
        ),
      ];

      final loansCsv = const ListToCsvConverter().convert(loansData);
      await loansCsvFile.writeAsString(loansCsv);

      // Export payments
      final payments = _databaseService.getAllPayments();
      final paymentsCsvFile = File(
        '${directory.path}/${baseFileName}_payments.csv',
      );

      final paymentsData = [
        ['ID', 'Loan ID', 'Date', 'Amount', 'Note', 'Created At'],
        ...payments.map(
          (p) => [
            p.id,
            p.loanId,
            p.date.toIso8601String(),
            p.amount.toString(),
            p.note,
            p.createdAt.toIso8601String(),
          ],
        ),
      ];

      final paymentsCsv = const ListToCsvConverter().convert(paymentsData);
      await paymentsCsvFile.writeAsString(paymentsCsv);

      return true;
    } catch (e) {
      print('CSV export error: $e');
      return false;
    }
  }

  Future<bool> _exportToJson(String baseFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$baseFileName.json');

      final transactions = _databaseService.getAllTransactions();
      final loans = _databaseService.getAllLoans();
      final payments = _databaseService.getAllPayments();
      final settings = _databaseService.getSettings();

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'settings': settings.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'loans': loans.map((l) => l.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);

      return true;
    } catch (e) {
      print('JSON export error: $e');
      return false;
    }
  }

  Future<bool> _exportToExcel(String baseFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$baseFileName.xlsx');

      final excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create transactions sheet
      final transactionsSheet = excel['Transactions'];
      final transactions = _databaseService.getAllTransactions();

      // Add headers
      transactionsSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Type'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Currency'),
        TextCellValue('Date'),
        TextCellValue('Note'),
        TextCellValue('Created At'),
        TextCellValue('Updated At'),
      ]);

      // Add data
      for (final transaction in transactions) {
        transactionsSheet.appendRow([
          TextCellValue(transaction.id),
          TextCellValue(transaction.type.toString().split('.').last),
          TextCellValue(transaction.category),
          DoubleCellValue(transaction.amount),
          TextCellValue(transaction.currency),
          TextCellValue(transaction.date.toIso8601String()),
          TextCellValue(transaction.note),
          TextCellValue(transaction.createdAt.toIso8601String()),
          TextCellValue(transaction.updatedAt.toIso8601String()),
        ]);
      }

      // Create loans sheet
      final loansSheet = excel['Loans'];
      final loans = _databaseService.getAllLoans();

      // Add headers
      loansSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Name'),
        TextCellValue('Principal'),
        TextCellValue('Monthly Payment'),
        TextCellValue('Interest Rate'),
        TextCellValue('Start Date'),
        TextCellValue('End Date'),
        TextCellValue('Remaining Balance'),
        TextCellValue('Created At'),
        TextCellValue('Updated At'),
      ]);

      // Add data
      for (final loan in loans) {
        loansSheet.appendRow([
          TextCellValue(loan.id),
          TextCellValue(loan.name),
          DoubleCellValue(loan.principal),
          DoubleCellValue(loan.monthlyPayment),
          DoubleCellValue(loan.interestRate),
          TextCellValue(loan.startDate.toIso8601String()),
          TextCellValue(loan.endDate?.toIso8601String() ?? ''),
          DoubleCellValue(loan.remainingBalance),
          TextCellValue(loan.createdAt.toIso8601String()),
          TextCellValue(loan.updatedAt.toIso8601String()),
        ]);
      }

      // Create payments sheet
      final paymentsSheet = excel['Payments'];
      final payments = _databaseService.getAllPayments();

      // Add headers
      paymentsSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Loan ID'),
        TextCellValue('Date'),
        TextCellValue('Amount'),
        TextCellValue('Note'),
        TextCellValue('Created At'),
      ]);

      // Add data
      for (final payment in payments) {
        paymentsSheet.appendRow([
          TextCellValue(payment.id),
          TextCellValue(payment.loanId),
          TextCellValue(payment.date.toIso8601String()),
          DoubleCellValue(payment.amount),
          TextCellValue(payment.note),
          TextCellValue(payment.createdAt.toIso8601String()),
        ]);
      }

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return true;
      }

      return false;
    } catch (e) {
      print('Excel export error: $e');
      return false;
    }
  }

  Future<String> getExportsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List<FileSystemEntity>> getExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      return dir
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.csv') ||
                file.path.endsWith('.json') ||
                file.path.endsWith('.xlsx'),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Import functionality
  Future<ImportResult> importData(File file) async {
    try {
      final fileName = file.path.split('/').last.toLowerCase();
      
      if (fileName.endsWith('.json')) {
        return await _importFromJson(file);
      } else if (fileName.endsWith('.csv')) {
        return await _importFromCsv(file);
      } else {
        return ImportResult(
          success: false,
          message: 'Unsupported file format. Only JSON and CSV files are supported.',
        );
      }
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  Future<ImportResult> _importFromJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      int importedCount = 0;
      List<String> errors = [];

      // Import settings if available
      if (data.containsKey('settings')) {
        try {
          final settingsData = data['settings'] as Map<String, dynamic>;
          final settings = Settings.fromJson(settingsData);
          await _databaseService.updateSettings(settings);
        } catch (e) {
          errors.add('Failed to import settings: $e');
        }
      }

      // Import transactions
      if (data.containsKey('transactions')) {
        try {
          final transactionsList = data['transactions'] as List<dynamic>;
          for (final transactionData in transactionsList) {
            final transaction = Transaction.fromJson(transactionData as Map<String, dynamic>);
            await _databaseService.addTransaction(transaction);
            importedCount++;
          }
        } catch (e) {
          errors.add('Failed to import transactions: $e');
        }
      }

      // Import loans
      if (data.containsKey('loans')) {
        try {
          final loansList = data['loans'] as List<dynamic>;
          for (final loanData in loansList) {
            final loan = Loan.fromJson(loanData as Map<String, dynamic>);
            await _databaseService.addLoan(loan);
            importedCount++;
          }
        } catch (e) {
          errors.add('Failed to import loans: $e');
        }
      }

      // Import payments
      if (data.containsKey('payments')) {
        try {
          final paymentsList = data['payments'] as List<dynamic>;
          for (final paymentData in paymentsList) {
            final payment = Payment.fromJson(paymentData as Map<String, dynamic>);
            await _databaseService.addPayment(payment);
            importedCount++;
          }
        } catch (e) {
          errors.add('Failed to import payments: $e');
        }
      }

      return ImportResult(
        success: true,
        message: 'Successfully imported $importedCount items.',
        importedCount: importedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to parse JSON file: ${e.toString()}',
      );
    }
  }

  Future<ImportResult> _importFromCsv(File file) async {
    try {
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        return ImportResult(
          success: false,
          message: 'CSV file is empty',
        );
      }

      final fileName = file.path.split('/').last.toLowerCase();
      int importedCount = 0;
      List<String> errors = [];

      if (fileName.contains('transaction')) {
        importedCount = await _importTransactionsFromCsv(csvData, errors);
      } else if (fileName.contains('loan')) {
        importedCount = await _importLoansFromCsv(csvData, errors);
      } else if (fileName.contains('payment')) {
        importedCount = await _importPaymentsFromCsv(csvData, errors);
      } else {
        return ImportResult(
          success: false,
          message: 'Cannot determine data type from filename. Please ensure filename contains "transaction", "loan", or "payment".',
        );
      }

      return ImportResult(
        success: importedCount > 0,
        message: importedCount > 0 
          ? 'Successfully imported $importedCount items.'
          : 'No items were imported.',
        importedCount: importedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to parse CSV file: ${e.toString()}',
      );
    }
  }

  Future<int> _importTransactionsFromCsv(List<List<dynamic>> csvData, List<String> errors) async {
    int importedCount = 0;
    
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 7) continue; // Skip incomplete rows

        final transaction = Transaction(
          id: row[0].toString(),
          type: row[1].toString().toLowerCase() == 'income' 
            ? TransactionType.income 
            : TransactionType.expense,
          category: row[2].toString(),
          amount: double.parse(row[3].toString()),
          // currency is always MNT, skip row[4]
          date: DateTime.parse(row[5].toString()),
          note: row[6].toString(),
          createdAt: row.length > 7 ? DateTime.parse(row[7].toString()) : DateTime.now(),
          updatedAt: row.length > 8 ? DateTime.parse(row[8].toString()) : DateTime.now(),
        );

        await _databaseService.addTransaction(transaction);
        importedCount++;
      } catch (e) {
        errors.add('Failed to import transaction at row ${i + 1}: $e');
      }
    }
    
    return importedCount;
  }

  Future<int> _importLoansFromCsv(List<List<dynamic>> csvData, List<String> errors) async {
    int importedCount = 0;
    
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 8) continue; // Skip incomplete rows

        final loan = Loan(
          id: row[0].toString(),
          name: row[1].toString(),
          principal: double.parse(row[2].toString()),
          monthlyPayment: double.parse(row[3].toString()),
          interestRate: double.parse(row[4].toString()),
          startDate: DateTime.parse(row[5].toString()),
          endDate: row[6].toString().isEmpty ? null : DateTime.parse(row[6].toString()),
          remainingBalance: double.parse(row[7].toString()),
          createdAt: row.length > 8 ? DateTime.parse(row[8].toString()) : DateTime.now(),
          updatedAt: row.length > 9 ? DateTime.parse(row[9].toString()) : DateTime.now(),
        );

        await _databaseService.addLoan(loan);
        importedCount++;
      } catch (e) {
        errors.add('Failed to import loan at row ${i + 1}: $e');
      }
    }
    
    return importedCount;
  }

  Future<int> _importPaymentsFromCsv(List<List<dynamic>> csvData, List<String> errors) async {
    int importedCount = 0;
    
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 5) continue; // Skip incomplete rows

        final payment = Payment(
          id: row[0].toString(),
          loanId: row[1].toString(),
          date: DateTime.parse(row[2].toString()),
          amount: double.parse(row[3].toString()),
          note: row[4].toString(),
          createdAt: row.length > 5 ? DateTime.parse(row[5].toString()) : DateTime.now(),
        );

        await _databaseService.addPayment(payment);
        importedCount++;
      } catch (e) {
        errors.add('Failed to import payment at row ${i + 1}: $e');
      }
    }
    
    return importedCount;
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.errors = const [],
  });
}
