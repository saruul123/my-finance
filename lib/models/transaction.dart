import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late TransactionType type;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late double amount;

  // Currency is always MNT
  String get currency => 'MNT';

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late String note;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    // currency is always MNT, no parameter needed
    required this.date,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction.create({
    required this.type,
    required this.category,
    required this.amount,
    // currency is always MNT, no parameter needed
    required this.date,
    this.note = '',
  }) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'category': category,
      'amount': amount,
      'currency': 'MNT', // Always MNT
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      category: json['category'],
      amount: json['amount'].toDouble(),
      // currency is always MNT, ignore json value
      date: DateTime.parse(json['date']),
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  void updateTransaction({
    TransactionType? type,
    String? category,
    double? amount,
    // currency removed - always MNT
    DateTime? date,
    String? note,
  }) {
    if (type != null) this.type = type;
    if (category != null) this.category = category;
    if (amount != null) this.amount = amount;
    // currency is always MNT, no update needed
    if (date != null) this.date = date;
    if (note != null) this.note = note;
    updatedAt = DateTime.now();
  }
}