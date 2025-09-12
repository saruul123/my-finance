import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import 'categorization_service.dart';

class KhanBankService {
  String username = "";
  String account = "";
  String deviceId = "";
  String accessToken = "";
  String startTime = "";
  String nowTime = "";

  KhanBankService({
    required this.username,
    required this.account,
    required this.deviceId,
    required this.startTime,
    required this.nowTime,
  });

  /// Login to Khan Bank API and get access token
  Future<bool> login(String password) async {
    try {
      print(
        "Khan Bank login initiated for user: $username",
      ); // --- IGNORE ---
      final encodedPassword = base64Encode(utf8.encode(password));

      // Simplified headers for Android compatibility
      final headers = {
        "Host": "e.khanbank.com",
        "Accept": "application/json, text/plain, */*",
        "Authorization": "",
        "Device-Id": deviceId,
        "User-Agent":
            "Mozilla/5.0 (Linux; Android 9; SM-N950N Build/PPR1.180610.011; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/93.0.4577.82 Mobile Safari/537.36",
        "Accept-Language": "mn-MN",
        "Secure": "yes",
        "Content-Type": "application/json",
        "Content-Length": "116",
        "Accept-Encoding": "gzip, deflate, br, zstd",
        "Connection": "keep-alive",
      };

      final data = json.encode({
        "grant_type": "password",
        "username": username,
        "password": encodedPassword,
        "channelId": "I",
        "languageId": "003",
      });

      print("Attempting Khan Bank login for user: $username");
      print("Device ID: $deviceId");

      final response = await http
          .post(
            Uri.parse(
              "https://e.khanbank.com/v3/cfrm/auth/token?grant_type=password",
            ),
            headers: headers,
            body: data,
          )
          .timeout(const Duration(seconds: 30));

      print("Khan Bank login response status: ${response.statusCode}");
      print("Khan Bank login response headers: ${response.headers}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Khan Bank login response body: ${response.body}");

        if (responseData["access_token"] != null) {
          accessToken = responseData["access_token"];
          print("Successfully obtained access token");
          return true;
        } else {
          print("No access token in response: $responseData");
          return false;
        }
      } else {
        print("Khan Bank login error - Status: ${response.statusCode}");
        print("Khan Bank login error - Body: ${response.body}");
        return false;
      }
    } catch (e, stackTrace) {
      print("Khan Bank login exception: $e");
      print("Stack trace: $stackTrace");
      return false;
    }
  }

  /// Build transaction URL with date range and filters
  String _buildTransactionUrl(
    String account,
    String startTime,
    String nowTime, [
    String remarks = "",
  ]) {
    final baseUrl = "https://e.khanbank.com/v3/omni/accounts/receipt/$account";

    // Try different date formats based on Khan Bank API requirements
    Map<String, String> transactionDate;

    // Check if the time format is milliseconds or ISO string
    if (startTime.contains('-')) {
      // ISO format - use as is
      transactionDate = {"lt": nowTime, "gt": startTime};
    } else {
      // Milliseconds format - convert to proper format for Khan Bank
      final startMs = int.tryParse(startTime) ?? 0;
      final endMs = int.tryParse(nowTime) ?? 0;

      // Convert milliseconds to ISO date strings for API
      final startDate = DateTime.fromMillisecondsSinceEpoch(
        startMs,
      ).toIso8601String();
      final endDate = DateTime.fromMillisecondsSinceEpoch(
        endMs,
      ).toIso8601String();

      transactionDate = {"lt": endDate, "gt": startDate};
      print(
        "Converted timestamps: $startMs -> $startDate, $endMs -> $endDate",
      );
    }

    final transactionAmount = {"lt": "0", "gt": "0"};

    final params = {
      "transactionDate": Uri.encodeComponent(json.encode(transactionDate)),
      "transactionAmount": Uri.encodeComponent(json.encode(transactionAmount)),
      "beneficiaryAccountId": "",
      "transactionRemarks": remarks,
    };

    // Filter out empty parameters and build clean query string
    final filteredParams = <String, String>{};
    for (final entry in params.entries) {
      if (entry.value.isNotEmpty &&
          entry.key != "beneficiaryAccountId" &&
          entry.key != "transactionRemarks") {
        filteredParams[entry.key] = entry.value;
      }
    }

    final queryString = filteredParams.entries
        .map((e) => "${e.key}=${e.value}")
        .join("&");

    final fullUrl = "$baseUrl?$queryString";
    print("Built transaction URL: $fullUrl");
    print("Transaction date parameter: ${json.encode(transactionDate)}");
    return fullUrl;
  }

  /// Download transactions from Khan Bank API
  Future<KhanBankTransactionResult?> downloadTransactions() async {
    if (accessToken.isEmpty) {
      print("Access token is empty. Please login first.");
      return null;
    }

    try {
      // Clean headers for GET request (no Content-Length or Content-Type for GET)
      final headers = {
        "Accept": "application/json, text/plain, */*",
        "Authorization": "Bearer $accessToken",
        "Device-Id": deviceId,
        "User-Agent":
            "Mozilla/5.0 (Linux; Android 9; SM-N950N Build/PPR1.180610.011; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/93.0.4577.82 Mobile Safari/537.36",
        "Accept-Language": "mn-MN",
      };

      final url = _buildTransactionUrl(account, startTime, nowTime);
      print("Downloading transactions from: $url");
      print(
        "Date range parameters: startTime=$startTime, nowTime=$nowTime",
      );

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      print(
        "Transaction download response status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(
          "Successfully downloaded transactions: ${responseData['transactions']?.length ?? 0} transactions",
        );
        return KhanBankTransactionResult.fromJson(responseData);
      } else {
        print(
          "Khan Bank transaction download error - Status: ${response.statusCode}",
        );
        print(
          "Khan Bank transaction download error - Body: ${response.body}",
        );
        return null;
      }
    } catch (e, stackTrace) {
      print("Khan Bank transaction download exception: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  /// Convert Khan Bank transactions to app Transaction objects
  List<Transaction> convertToAppTransactions(KhanBankTransactionResult result) {
    final transactions = <Transaction>[];

    for (final kbTransaction in result.transactions) {
      try {
        final amount = double.parse(
          kbTransaction.amount.amount.replaceAll(',', ''),
        );
        final isIncome = amount > 0;

        // Create a unique ID based on transaction details to detect duplicates
        final uniqueId = _createUniqueTransactionId(kbTransaction, amount);

        // Use automatic categorization service
        final category = CategorizationService.instance.categorizeTransaction(
          kbTransaction.transactionRemarks,
        );

        final transaction = Transaction(
          id: uniqueId,
          amount: amount.abs(),
          category: category,
          note: kbTransaction.transactionRemarks,
          date: DateTime.parse(
            "${kbTransaction.transactionDate}T${kbTransaction.txnTime}",
          ),
          type: isIncome ? TransactionType.income : TransactionType.expense,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        transactions.add(transaction);
      } catch (e) {
        print("Error converting transaction: $e");
        continue;
      }
    }

    return transactions;
  }

  /// Create a unique transaction ID based on Khan Bank transaction details
  String _createUniqueTransactionId(
    KhanBankTransaction kbTransaction,
    double amount,
  ) {
    // Use transaction date, time, amount, and remarks to create a unique identifier
    final uniqueString =
        'kb_${kbTransaction.transactionDate}_${kbTransaction.txnTime}_${amount.abs()}_${kbTransaction.transactionRemarks.hashCode}';
    return uniqueString;
  }
}

/// Khan Bank transaction result model
class KhanBankTransactionResult {
  final String account;
  final String currency;
  final String customerName;
  final double beginBalance;
  final double endBalance;
  final String productName;
  final KhanBankTotal total;
  final List<KhanBankTransaction> transactions;

  KhanBankTransactionResult({
    required this.account,
    required this.currency,
    required this.customerName,
    required this.beginBalance,
    required this.endBalance,
    required this.productName,
    required this.total,
    required this.transactions,
  });

  factory KhanBankTransactionResult.fromJson(Map<String, dynamic> json) {
    return KhanBankTransactionResult(
      account: json['account'] ?? '',
      currency: json['currency'] ?? 'MNT',
      customerName: json['customerName'] ?? '',
      beginBalance: (json['beginBalance'] ?? 0.0).toDouble(),
      endBalance: (json['endBalance'] ?? 0.0).toDouble(),
      productName: json['productName'] ?? '',
      total: KhanBankTotal.fromJson(json['total'] ?? {}),
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((t) => KhanBankTransaction.fromJson(t))
              .toList() ??
          [],
    );
  }
}

/// Khan Bank total model
class KhanBankTotal {
  final int count;
  final double credit;
  final double debit;

  KhanBankTotal({
    required this.count,
    required this.credit,
    required this.debit,
  });

  factory KhanBankTotal.fromJson(Map<String, dynamic> json) {
    return KhanBankTotal(
      count: json['count'] ?? 0,
      credit: (json['credit'] ?? 0.0).toDouble(),
      debit: (json['debit'] ?? 0.0).toDouble(),
    );
  }
}

/// Khan Bank transaction model
class KhanBankTransaction {
  final String? accountId;
  final KhanBankAmount amount;
  final String transactionDate;
  final String transactionRemarks;
  final String txnTime;
  final String benefBankName;

  KhanBankTransaction({
    this.accountId,
    required this.amount,
    required this.transactionDate,
    required this.transactionRemarks,
    required this.txnTime,
    required this.benefBankName,
  });

  factory KhanBankTransaction.fromJson(Map<String, dynamic> json) {
    return KhanBankTransaction(
      accountId: json['accountId'],
      amount: KhanBankAmount.fromJson(json['amount'] ?? {}),
      transactionDate: json['transactionDate'] ?? '',
      transactionRemarks: json['transactionRemarks'] ?? '',
      txnTime: json['txnTime'] ?? '',
      benefBankName: json['benefBankName'] ?? '',
    );
  }
}

/// Khan Bank amount model
class KhanBankAmount {
  final String amount;
  final String currency;

  KhanBankAmount({required this.amount, required this.currency});

  factory KhanBankAmount.fromJson(Map<String, dynamic> json) {
    return KhanBankAmount(
      amount: json['amount'] ?? '0.00',
      currency: json['currency'] ?? 'MNT',
    );
  }
}
