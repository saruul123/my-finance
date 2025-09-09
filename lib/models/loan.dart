import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 2)
class Payment extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String loanId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String note;

  @HiveField(5)
  late DateTime createdAt;

  Payment({
    required this.id,
    required this.loanId,
    required this.date,
    required this.amount,
    this.note = '',
    required this.createdAt,
  });

  Payment.create({
    required this.loanId,
    required this.date,
    required this.amount,
    this.note = '',
  }) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    createdAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'date': date.toIso8601String(),
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      loanId: json['loanId'],
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

@HiveType(typeId: 3)
class Loan extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double principal;

  @HiveField(3)
  late double monthlyPayment;

  @HiveField(4)
  late double interestRate;

  @HiveField(5)
  late DateTime startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  late double remainingBalance;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  Loan({
    required this.id,
    required this.name,
    required this.principal,
    required this.monthlyPayment,
    required this.interestRate,
    required this.startDate,
    this.endDate,
    required this.remainingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  Loan.create({
    required this.name,
    required this.principal,
    required this.monthlyPayment,
    required this.interestRate,
    required this.startDate,
    this.endDate,
  }) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    remainingBalance = principal;
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'principal': principal,
      'monthlyPayment': monthlyPayment,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'remainingBalance': remainingBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      principal: json['principal'].toDouble(),
      monthlyPayment: json['monthlyPayment'].toDouble(),
      interestRate: json['interestRate'].toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      remainingBalance: json['remainingBalance'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  void makePayment(double amount) {
    remainingBalance -= amount;
    if (remainingBalance < 0) remainingBalance = 0;
    updatedAt = DateTime.now();
  }

  void updateLoan({
    String? name,
    double? principal,
    double? monthlyPayment,
    double? interestRate,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (name != null) this.name = name;
    if (principal != null) {
      this.principal = principal;
      remainingBalance = principal;
    }
    if (monthlyPayment != null) this.monthlyPayment = monthlyPayment;
    if (interestRate != null) this.interestRate = interestRate;
    if (startDate != null) this.startDate = startDate;
    if (endDate != null) this.endDate = endDate;
    updatedAt = DateTime.now();
  }

  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!) && remainingBalance > 0;
  }

  bool get isDueSoon {
    if (endDate == null) return false;
    final daysUntilDue = endDate!.difference(DateTime.now()).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0 && remainingBalance > 0;
  }

  double get progressPercentage {
    if (principal == 0) return 0;
    return ((principal - remainingBalance) / principal) * 100;
  }
}