import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 11)
enum TagGroup {
  @HiveField(0)
  needs, // food, rent, utilities
  
  @HiveField(1)
  wants, // shopping, entertainment, travel
  
  @HiveField(2)
  loans, // loan repayments, installments
  
  @HiveField(3)
  interest, // loan interest, bank fees
}

@HiveType(typeId: 12)
class Tag extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late TagGroup group;

  @HiveField(3)
  late List<String> keywords;

  @HiveField(4)
  late bool isEnabled;

  @HiveField(5)
  late bool caseSensitive;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt;

  Tag({
    required this.id,
    required this.name,
    required this.group,
    required this.keywords,
    this.isEnabled = true,
    this.caseSensitive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tag.create({
    required String name,
    required TagGroup group,
    required List<String> keywords,
    bool isEnabled = true,
    bool caseSensitive = false,
  }) {
    final now = DateTime.now();
    return Tag(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      group: group,
      keywords: keywords,
      isEnabled: isEnabled,
      caseSensitive: caseSensitive,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<Tag> getDefaultTags() {
    final now = DateTime.now();
    return [
      // NEEDS
      Tag(
        id: 'food_tag',
        name: 'food',
        group: TagGroup.needs,
        keywords: ['kfc', 'мс', 'burger', 'хоол', 'food', 'pizza', 'coffee', 'мак доналдс', 'макдоналдс', 'ресторан', 'кафе'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'rent_tag',
        name: 'rent',
        group: TagGroup.needs,
        keywords: ['түрээс', 'rent', 'орон сууц', 'гэрийн түрээс', 'байрны төлбөр'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'utilities_tag',
        name: 'utilities',
        group: TagGroup.needs,
        keywords: ['цахилгаан', 'ус', 'дулаан', 'газар', 'интернет', 'утас', 'электрик', 'халаалт'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'transport_tag',
        name: 'transport',
        group: TagGroup.needs,
        keywords: ['автобус', 'bus', 'такси', 'taxi', 'зорчсон төлбөр', 'шатахуун', 'fuel', 'бензин', 'метро'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      
      // WANTS
      Tag(
        id: 'shopping_tag',
        name: 'shopping',
        group: TagGroup.wants,
        keywords: ['дэлгүүр', 'shop', 'store', 'худалдаа', 'market', 'супермаркет', 'худалдан авалт'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'entertainment_tag',
        name: 'entertainment',
        group: TagGroup.wants,
        keywords: ['кино', 'movie', 'театр', 'концерт', 'клуб', 'бар', 'зугаацай', 'спорт', 'тоглоом'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'travel_tag',
        name: 'travel',
        group: TagGroup.wants,
        keywords: ['аялал', 'travel', 'зочид буудал', 'hotel', 'нисэх', 'flight', 'тэвэр', 'жуулчлал'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      
      // LOANS
      Tag(
        id: 'loan_repayment_tag',
        name: 'loan repayment',
        group: TagGroup.loans,
        keywords: ['зээлийн төлбөр', 'loan payment', 'зээл', 'төлбөр', 'mortgage', 'гэрийн зээл', 'автозээл'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'installment_tag',
        name: 'installment',
        group: TagGroup.loans,
        keywords: ['хэсэгчилсэн төлбөр', 'installment', 'monthly payment', 'сарын төлбөр', 'хуваан төлөх'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      
      // INTEREST
      Tag(
        id: 'loan_interest_tag',
        name: 'loan interest',
        group: TagGroup.interest,
        keywords: ['зээлийн хүү', 'loan interest', 'хүү', 'interest', 'шимтгэл'],
        isEnabled: true,
        caseSensitive: false,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'bank_fees_tag',
        name: 'bank fees',
        group: TagGroup.interest,
        keywords: ['банкны шимтгэл', 'bank fee', 'service fee', 'үйлчилгээний төлбөр', 'хураамж', 'комисс'],
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
      'group': group.toString(),
      'keywords': keywords,
      'isEnabled': isEnabled,
      'caseSensitive': caseSensitive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Tag fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      group: TagGroup.values.firstWhere(
        (e) => e.toString() == json['group'],
        orElse: () => TagGroup.needs,
      ),
      keywords: List<String>.from(json['keywords'] ?? []),
      isEnabled: json['isEnabled'] ?? true,
      caseSensitive: json['caseSensitive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

extension TagGroupExtension on TagGroup {
  String get displayName {
    switch (this) {
      case TagGroup.needs:
        return 'Needs';
      case TagGroup.wants:
        return 'Wants';
      case TagGroup.loans:
        return 'Loans';
      case TagGroup.interest:
        return 'Interest';
    }
  }

  String get mongolianName {
    switch (this) {
      case TagGroup.needs:
        return 'Хэрэгцээ';
      case TagGroup.wants:
        return 'Хүсэл';
      case TagGroup.loans:
        return 'Зээл';
      case TagGroup.interest:
        return 'Хүү';
    }
  }
}