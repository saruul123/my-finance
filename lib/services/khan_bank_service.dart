import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

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
      final encodedPassword = base64Encode(utf8.encode(password));
      
      final headers = {
        "Host": "e.khanbank.com",
        "Accept": "application/json, text/plain, */*",
        "Authorization": "", // Keep empty as per original code
        "Device-Id": deviceId,
        "User-Agent": "Mozilla/5.0 (Linux; Android 9; SM-N950N Build/PPR1.180610.011; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/93.0.4577.82 Mobile Safari/537.36",
        "Accept-Language": "mn-MN",
        "Secure": "yes",
        "Content-Type": "application/json",
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

      final response = await http.post(
        Uri.parse("https://e.khanbank.com/v3/cfrm/auth/token?grant_type=password"),
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        accessToken = responseData["access_token"];
        return true;
      } else {
        log("Khan Bank login error: ${response.body}");
        return false;
      }
    } catch (e) {
      log("Khan Bank login exception: $e");
      return false;
    }
  }

  /// Build transaction URL with date range and filters
  String _buildTransactionUrl(String account, String startTime, String nowTime, [String remarks = ""]) {
    final baseUrl = "https://e.khanbank.com/v3/omni/accounts/receipt/$account";
    
    final transactionDate = {"lt": startTime, "gt": nowTime};
    final transactionAmount = {"lt": "0", "gt": "0"};
    
    final params = {
      "transactionDate": Uri.encodeComponent(json.encode(transactionDate)),
      "transactionAmount": Uri.encodeComponent(json.encode(transactionAmount)),
      "beneficiaryAccountId": "",
      "transactionRemarks": remarks,
    };
    
    final queryString = params.entries.map((e) => "${e.key}=${e.value}").join("&");
    return "$baseUrl?$queryString";
  }

  /// Download transactions from Khan Bank API
  Future<KhanBankTransactionResult?> downloadTransactions() async {
    if (accessToken.isEmpty) {
      log("Access token is empty. Please login first.");
      return null;
    }

    try {
      final headers = {
        "Host": "e.khanbank.com",
        "Accept": "application/json, text/plain, */*",
        "Authorization": "Bearer $accessToken",
        "Device-Id": deviceId,
        "Accept-Language": "mn-MN",
        "User-Agent": "Mozilla/5.0 (Linux; Android 9; SM-N950N Build/PPR1.180610.011; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/93.0.4577.82 Mobile Safari/537.36",
        "Secure": "yes",
        "Accept-Encoding": "gzip, deflate, br, zstd",
        "Connection": "keep-alive",
      };

      final url = _buildTransactionUrl(account, startTime, nowTime);
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return KhanBankTransactionResult.fromJson(responseData);
      } else {
        log("Khan Bank transaction download error: ${response.body}");
        return null;
      }
    } catch (e) {
      log("Khan Bank transaction download exception: $e");
      return null;
    }
  }

  /// Convert Khan Bank transactions to app Transaction objects
  List<Transaction> convertToAppTransactions(KhanBankTransactionResult result) {
    final transactions = <Transaction>[];
    
    for (final kbTransaction in result.transactions) {
      try {
        final amount = double.parse(kbTransaction.amount.amount.replaceAll(',', ''));
        final isIncome = amount > 0;
        
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString() + transactions.length.toString(),
          amount: amount.abs(),
          category: _categorizeTransaction(kbTransaction.transactionRemarks),
          note: kbTransaction.transactionRemarks,
          date: DateTime.parse("${kbTransaction.transactionDate}T${kbTransaction.txnTime}"),
          type: isIncome ? TransactionType.income : TransactionType.expense,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        transactions.add(transaction);
      } catch (e) {
        log("Error converting transaction: $e");
        continue;
      }
    }
    
    return transactions;
  }

  /// Categorize transaction based on remarks
  String _categorizeTransaction(String remarks) {
    final remarksLower = remarks.toLowerCase();
    
    // Transport
    if (remarksLower.contains('автобус') || remarksLower.contains('bus') || 
        remarksLower.contains('такси') || remarksLower.contains('taxi')) {
      return 'Тээвэр';
    }
    
    // Food
    if (remarksLower.contains('kfc') || remarksLower.contains('мс') || remarksLower.contains('burger') ||
        remarksLower.contains('хоол') || remarksLower.contains('food')) {
      return 'Хоол хүнс';
    }
    
    // Shopping
    if (remarksLower.contains('дэлгүүр') || remarksLower.contains('shop') || remarksLower.contains('store')) {
      return 'Дэлгүүр худалдаа';
    }
    
    // Transfer/Personal
    if (remarksLower.contains('саруул-эрдэм') || remarksLower.contains('-с') || remarksLower.contains('transfer')) {
      return 'Шилжүүлэг';
    }
    
    // Default category
    return 'Бусад';
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
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((t) => KhanBankTransaction.fromJson(t))
          .toList() ?? [],
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

  KhanBankAmount({
    required this.amount,
    required this.currency,
  });

  factory KhanBankAmount.fromJson(Map<String, dynamic> json) {
    return KhanBankAmount(
      amount: json['amount'] ?? '0.00',
      currency: json['currency'] ?? 'MNT',
    );
  }
}