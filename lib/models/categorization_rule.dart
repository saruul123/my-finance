import 'package:hive/hive.dart';

part 'categorization_rule.g.dart';

@HiveType(typeId: 10)
class CategorizationRule extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late List<String> keywords;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late bool isEnabled;

  @HiveField(5)
  late bool caseSensitive;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt;

  CategorizationRule({
    required this.id,
    required this.name,
    required this.keywords,
    required this.category,
    this.isEnabled = true,
    this.caseSensitive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategorizationRule.create({
    required String name,
    required List<String> keywords,
    required String category,
    bool isEnabled = true,
    bool caseSensitive = false,
  }) {
    final now = DateTime.now();
    return CategorizationRule(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      keywords: keywords,
      category: category,
      isEnabled: isEnabled,
      caseSensitive: caseSensitive,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<CategorizationRule> getDefaultRules() {
    final now = DateTime.now();
    return [
      // Transport
      CategorizationRule(
        id: 'transport_1',
        name: 'Transport - Bus & Taxi',
        keywords: ['автобус', 'bus', 'такси', 'taxi', 'зорчсон төлбөр'],
        category: 'Тээвэр',
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      // Food
      CategorizationRule(
        id: 'food_1',
        name: 'Food - Restaurants',
        keywords: ['kfc', 'мс', 'burger', 'хоол', 'food', 'pizza', 'coffee'],
        category: 'Хоол хүнс',
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      // Shopping
      CategorizationRule(
        id: 'shopping_1',
        name: 'Shopping',
        keywords: ['дэлгүүр', 'shop', 'store', 'худалдаа', 'market'],
        category: 'Дэлгүүр худалдаа',
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      // Transfers
      CategorizationRule(
        id: 'transfer_1',
        name: 'Personal Transfers',
        keywords: ['саруул-эрдэм', '-с', 'transfer', 'шилжүүлэг'],
        category: 'Шилжүүлэг',
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      // Fuel
      CategorizationRule(
        id: 'fuel_1',
        name: 'Fuel & Gas',
        keywords: ['шатахуун', 'fuel', 'gas', 'petrol', 'бензин'],
        category: 'Шатахуун',
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  bool matches(String transactionRemarks) {
    final text = caseSensitive ? transactionRemarks : transactionRemarks.toLowerCase();
    
    for (final keyword in keywords) {
      final searchKeyword = caseSensitive ? keyword : keyword.toLowerCase();
      if (text.contains(searchKeyword)) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keywords': keywords,
      'category': category,
      'isEnabled': isEnabled,
      'caseSensitive': caseSensitive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static CategorizationRule fromJson(Map<String, dynamic> json) {
    return CategorizationRule(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      category: json['category'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      caseSensitive: json['caseSensitive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}