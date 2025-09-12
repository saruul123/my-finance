import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag.dart';

class TagService {
  static const String tagsBox = 'tags';
  static TagService? _instance;
  static TagService get instance => _instance ??= TagService._();
  TagService._();

  late Box<Tag> _tags;
  Box<Tag> get tags => _tags;

  static Future<void> init() async {
    // Register the adapters if not already registered
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(TagGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(TagAdapter());
    }

    try {
      instance._tags = await Hive.openBox<Tag>(tagsBox);
      await instance._initializeDefaultTags();
    } catch (e) {
      print('Error opening tags box: $e');
      // Try to recover by deleting and recreating
      await Hive.deleteBoxFromDisk(tagsBox);
      instance._tags = await Hive.openBox<Tag>(tagsBox);
      await instance._initializeDefaultTags();
    }
  }

  Future<void> _initializeDefaultTags() async {
    // Only initialize if no tags exist
    if (_tags.isEmpty) {
      final defaultTags = Tag.getDefaultTags();
      for (final tag in defaultTags) {
        await _tags.put(tag.id, tag);
      }
    }
  }

  List<Tag> getAllTags() {
    return _tags.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Tag> getEnabledTags() {
    return _tags.values.where((tag) => tag.isEnabled).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Tag> getTagsByGroup(TagGroup group) {
    return _tags.values
        .where((tag) => tag.group == group && tag.isEnabled)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addTag(Tag tag) async {
    await _tags.put(tag.id, tag);
  }

  Future<void> updateTag(Tag tag) async {
    tag.updatedAt = DateTime.now();
    await _tags.put(tag.id, tag);
  }

  Future<void> deleteTag(String id) async {
    await _tags.delete(id);
  }

  Future<void> toggleTag(String id) async {
    final tag = _tags.get(id);
    if (tag != null) {
      tag.isEnabled = !tag.isEnabled;
      tag.updatedAt = DateTime.now();
      await _tags.put(id, tag);
    }
  }

  /// Extract keywords from transaction text and assign multiple tags
  List<String> extractTagsFromTransaction(String transactionRemarks) {
    final enabledTags = getEnabledTags();
    final matchedTags = <String>{};

    // Try each tag and collect all matches
    for (final tag in enabledTags) {
      if (tag.matches(transactionRemarks)) {
        matchedTags.add(tag.name);
      }
    }

    return matchedTags.toList()..sort();
  }

  /// Enhanced loan-specific tag extraction with intelligent categorization
  List<String> extractLoanTags({
    required String transactionRemarks,
    required double amount,
    String? loanName,
    double? interestRate,
    double? principalAmount,
    double? interestAmount,
  }) {
    final matchedTags = <String>{};
    final lowerRemarks = transactionRemarks.toLowerCase();
    final enabledTags = getEnabledTags();

    // 1. Basic loan keyword matching
    for (final tag in enabledTags.where(
      (t) => t.group == TagGroup.loans || t.group == TagGroup.interest,
    )) {
      if (tag.matches(transactionRemarks)) {
        matchedTags.add(tag.name);
      }
    }

    // 2. Loan name-based tagging
    if (loanName != null && loanName.isNotEmpty) {
      final customLoanTag = _generateLoanNameTag(loanName);
      matchedTags.add(customLoanTag);

      // Auto-create the tag if it doesn't exist
      _ensureLoanTagExists(customLoanTag, loanName);
    }

    // 3. Amount-based categorization
    if (amount > 0) {
      final amountTag = _categorizeByLoanAmount(amount);
      if (amountTag != null) {
        matchedTags.add(amountTag);
      }
    }

    // 4. Interest vs Principal categorization
    if (interestAmount != null && principalAmount != null) {
      if (interestAmount > principalAmount) {
        matchedTags.add('high interest payment');
        _ensureHighInterestTagExists();
      }

      final interestPercentage = (interestAmount / amount) * 100;
      if (interestPercentage > 50) {
        matchedTags.add('interest heavy');
        _ensureInterestHeavyTagExists();
      }
    }

    // 5. Intelligent bank/institution detection
    final institutionTag = _detectLoanInstitution(lowerRemarks);
    if (institutionTag != null) {
      matchedTags.add(institutionTag);
    }

    // 6. Payment frequency detection
    final frequencyTag = _detectPaymentFrequency(lowerRemarks);
    if (frequencyTag != null) {
      matchedTags.add(frequencyTag);
    }

    return matchedTags.toList()..sort();
  }

  String _generateLoanNameTag(String loanName) {
    return 'loan: ${loanName.toLowerCase().trim()}';
  }

  Future<void> _ensureLoanTagExists(String tagName, String loanName) async {
    final existingTag = _tags.values.firstWhere(
      (tag) => tag.name.toLowerCase() == tagName.toLowerCase(),
      orElse: () => Tag(
        id: '',
        name: '',
        group: TagGroup.loans,
        keywords: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingTag.id.isEmpty) {
      final newTag = Tag.create(
        name: tagName,
        group: TagGroup.loans,
        keywords: [loanName.toLowerCase(), tagName.toLowerCase()],
        isEnabled: true,
      );
      await addTag(newTag);
    }
  }

  String? _categorizeByLoanAmount(double amount) {
    if (amount >= 1000000) {
      // 1M MNT or more
      return 'large loan payment';
    } else if (amount >= 500000) {
      // 500K - 1M MNT
      return 'medium loan payment';
    } else if (amount >= 100000) {
      // 100K - 500K MNT
      return 'regular loan payment';
    } else if (amount >= 10000) {
      // 10K - 100K MNT
      return 'small loan payment';
    }
    return null;
  }

  String? _detectLoanInstitution(String lowerRemarks) {
    final institutionKeywords = {
      'khan bank': ['khan', 'хаан банк', 'хаан'],
      'state bank': ['state', 'төрийн банк', 'төрийн'],
      'golomt bank': ['golomt', 'голомт банк', 'голомт'],
      'trade bank': ['trade', 'худалдаа банк', 'худалдаа'],
      'capitron bank': ['capitron', 'капитрон', 'капитрон банк'],
      'xacbank': ['xac', 'хас банк', 'хас'],
      'mbank': ['mbank', 'эм банк', 'эмбанк'],
      'national investment bank': ['nib', 'хөрөнгө оруулалтын банк'],
      'credit mongolia': ['credit mongolia', 'кредит монголиа'],
      'microfinance': ['микрозээл', 'microfinance', 'мфо'],
    };

    for (final entry in institutionKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerRemarks.contains(keyword.toLowerCase())) {
          return '${entry.key} loan';
        }
      }
    }
    return null;
  }

  String? _detectPaymentFrequency(String lowerRemarks) {
    if (lowerRemarks.contains('сарын төлбөр') ||
        lowerRemarks.contains('monthly') ||
        lowerRemarks.contains('сар бүрийн')) {
      return 'monthly payment';
    } else if (lowerRemarks.contains('жилийн төлбөр') ||
        lowerRemarks.contains('annual') ||
        lowerRemarks.contains('жил бүрийн')) {
      return 'annual payment';
    } else if (lowerRemarks.contains('долоо хоногийн') ||
        lowerRemarks.contains('weekly') ||
        lowerRemarks.contains('7 хоног')) {
      return 'weekly payment';
    }
    return null;
  }

  Future<void> _ensureHighInterestTagExists() async {
    const tagName = 'high interest payment';
    final existingTag = _tags.values.firstWhere(
      (tag) => tag.name.toLowerCase() == tagName.toLowerCase(),
      orElse: () => Tag(
        id: '',
        name: '',
        group: TagGroup.interest,
        keywords: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingTag.id.isEmpty) {
      final newTag = Tag.create(
        name: tagName,
        group: TagGroup.interest,
        keywords: ['high interest', 'өндөр хүү', 'их хүү'],
        isEnabled: true,
      );
      await addTag(newTag);
    }
  }

  Future<void> _ensureInterestHeavyTagExists() async {
    const tagName = 'interest heavy';
    final existingTag = _tags.values.firstWhere(
      (tag) => tag.name.toLowerCase() == tagName.toLowerCase(),
      orElse: () => Tag(
        id: '',
        name: '',
        group: TagGroup.interest,
        keywords: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingTag.id.isEmpty) {
      final newTag = Tag.create(
        name: tagName,
        group: TagGroup.interest,
        keywords: ['interest heavy', 'хүү ихтэй', 'хүүгийн хэсэг их'],
        isEnabled: true,
      );
      await addTag(newTag);
    }
  }

  /// Get tag groups for a list of tag names
  Map<TagGroup, List<String>> groupTagsByCategory(List<String> tagNames) {
    final result = <TagGroup, List<String>>{};

    for (final group in TagGroup.values) {
      result[group] = [];
    }

    for (final tagName in tagNames) {
      final tag = _tags.values.firstWhere(
        (t) => t.name == tagName && t.isEnabled,
        orElse: () => Tag(
          id: '',
          name: '',
          group: TagGroup.needs,
          keywords: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (tag.id.isNotEmpty) {
        result[tag.group]!.add(tagName);
      }
    }

    return result;
  }

  /// Get all unique tags from transactions grouped by their categories
  Map<TagGroup, int> getTagGroupSummary(List<List<String>> allTransactionTags) {
    final result = <TagGroup, int>{};

    for (final group in TagGroup.values) {
      result[group] = 0;
    }

    final allTags = <String>{};
    for (final transactionTags in allTransactionTags) {
      allTags.addAll(transactionTags);
    }

    for (final tagName in allTags) {
      final tag = _tags.values.firstWhere(
        (t) => t.name == tagName && t.isEnabled,
        orElse: () => Tag(
          id: '',
          name: '',
          group: TagGroup.needs,
          keywords: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (tag.id.isNotEmpty) {
        result[tag.group] = (result[tag.group] ?? 0) + 1;
      }
    }

    return result;
  }

  Future<void> resetToDefaults() async {
    await _tags.clear();
    await _initializeDefaultTags();
  }

  Future<List<String>> getUniqueTagNames() async {
    final tags = getAllTags();
    final tagNames = tags.map((tag) => tag.name).toSet().toList();
    tagNames.sort();
    return tagNames;
  }

  Future<void> exportTags() async {
    // TODO: Implement export functionality
  }

  Future<void> importTags(List<Tag> importedTags) async {
    for (final tag in importedTags) {
      await _tags.put(tag.id, tag);
    }
  }
}
