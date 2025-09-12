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
