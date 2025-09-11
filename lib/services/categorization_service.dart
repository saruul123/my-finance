import 'package:hive_flutter/hive_flutter.dart';
import '../models/categorization_rule.dart';

class CategorizationService {
  static const String rulesBox = 'categorization_rules';
  static CategorizationService? _instance;
  static CategorizationService get instance =>
      _instance ??= CategorizationService._();
  CategorizationService._();

  late Box<CategorizationRule> _rules;
  Box<CategorizationRule> get rules => _rules;

  static Future<void> init() async {
    // Register the adapter if not already registered
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CategorizationRuleAdapter());
    }

    try {
      instance._rules = await Hive.openBox<CategorizationRule>(rulesBox);
      await instance._initializeDefaultRules();
    } catch (e) {
      print('Error opening categorization rules box: $e');
      // Try to recover by deleting and recreating
      await Hive.deleteBoxFromDisk(rulesBox);
      instance._rules = await Hive.openBox<CategorizationRule>(rulesBox);
      await instance._initializeDefaultRules();
    }
  }

  Future<void> _initializeDefaultRules() async {
    // Only initialize if no rules exist
    if (_rules.isEmpty) {
      final defaultRules = CategorizationRule.getDefaultRules();
      for (final rule in defaultRules) {
        await _rules.put(rule.id, rule);
      }
    }
  }

  List<CategorizationRule> getAllRules() {
    return _rules.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<CategorizationRule> getEnabledRules() {
    return _rules.values.where((rule) => rule.isEnabled).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addRule(CategorizationRule rule) async {
    await _rules.put(rule.id, rule);
  }

  Future<void> updateRule(CategorizationRule rule) async {
    rule.updatedAt = DateTime.now();
    await _rules.put(rule.id, rule);
  }

  Future<void> deleteRule(String id) async {
    await _rules.delete(id);
  }

  Future<void> toggleRule(String id) async {
    final rule = _rules.get(id);
    if (rule != null) {
      rule.isEnabled = !rule.isEnabled;
      rule.updatedAt = DateTime.now();
      await _rules.put(id, rule);
    }
  }

  String categorizeTransaction(String transactionRemarks) {
    final enabledRules = getEnabledRules();

    // Try each rule in order
    for (final rule in enabledRules) {
      if (rule.matches(transactionRemarks)) {
        return rule.category;
      }
    }

    // Default category if no matches
    return 'Бусад';
  }

  Future<void> resetToDefaults() async {
    await _rules.clear();
    await _initializeDefaultRules();
  }

  Future<List<String>> getUniqueCategories() async {
    final rules = getAllRules();
    final categories = rules.map((rule) => rule.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<void> exportRules() async {
    // TODO: Implement export functionality
  }

  Future<void> importRules(List<CategorizationRule> importedRules) async {
    for (final rule in importedRules) {
      await _rules.put(rule.id, rule);
    }
  }
}
