import 'package:flutter/material.dart';
import '../models/categorization_rule.dart';
import '../services/categorization_service.dart';
import '../l10n/app_localizations.dart';

class CategorizationSettingsScreen extends StatefulWidget {
  const CategorizationSettingsScreen({super.key});

  @override
  State<CategorizationSettingsScreen> createState() =>
      _CategorizationSettingsScreenState();
}

class _CategorizationSettingsScreenState
    extends State<CategorizationSettingsScreen> {
  List<CategorizationRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    setState(() {
      _isLoading = true;
    });

    _rules = CategorizationService.instance.getAllRules();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гүйлгээний ангилал'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog();
                  break;
                case 'test':
                  _showTestDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.science),
                    SizedBox(width: 8),
                    Text('Ангилал турших'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Анхдагш байдалд шинэчлэх'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.withOpacity(0.1), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildRulesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRulesList() {
    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.category, size: 64, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ангиллын дүрэм олдсонгүй',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Эхний дүрмээ нэмэхийн тулд + товчийг дарна уу',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildRuleCard(CategorizationRule rule) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            rule.isEnabled
                ? Colors.indigo.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: rule.isEnabled
                ? Colors.indigo.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: rule.isEnabled
                  ? [Colors.green, Colors.green.shade400]
                  : [Colors.grey, Colors.grey.shade400],
            ),
            boxShadow: [
              BoxShadow(
                color: rule.isEnabled
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            rule.isEnabled ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          rule.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rule.isEnabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: Text(
                'Ангилал: ${rule.category}',
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children:
                  rule.keywords.take(3).map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList()..addAll(
                    rule.keywords.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '+${rule.keywords.length - 3} илүү',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(rule.isEnabled ? Icons.toggle_on : Icons.toggle_off),
              color: rule.isEnabled ? Colors.green : Colors.grey,
              onPressed: () => _toggleRule(rule),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditRuleDialog(rule);
                    break;
                  case 'delete':
                    _deleteRule(rule);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Засах'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Устгах'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _toggleRule(CategorizationRule rule) async {
    await CategorizationService.instance.toggleRule(rule.id);
    _loadRules();
  }

  void _deleteRule(CategorizationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дүрэм устгах'),
        content: Text('Та "${rule.name}" дүрмийг устгахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Цуцлах'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CategorizationService.instance.deleteRule(rule.id);
      _loadRules();
    }
  }

  void _showAddRuleDialog() {
    _showRuleDialog(null);
  }

  void _showEditRuleDialog(CategorizationRule rule) {
    _showRuleDialog(rule);
  }

  void _showRuleDialog(CategorizationRule? existingRule) {
    final nameController = TextEditingController(
      text: existingRule?.name ?? '',
    );
    final categoryController = TextEditingController(
      text: existingRule?.category ?? '',
    );
    final keywordsController = TextEditingController(
      text: existingRule?.keywords.join(', ') ?? '',
    );
    bool caseSensitive = existingRule?.caseSensitive ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingRule == null ? 'Дүрэм нэмэх' : 'Дүрэм засах'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Дүрмийн нэр',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                    helperText: 'Тохирох гүйлгээнд оноох ангилал',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Түлхүүр үгс',
                    border: OutlineInputBorder(),
                    helperText: 'Таслалаар тусгаарлагдсан түлхүүр үгс',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Том жижиг үсэг ялгах'),
                  subtitle: const Text('Түлхүүр үгсийг яг тохирох ёсоор хайх'),
                  value: caseSensitive,
                  onChanged: (value) {
                    setState(() {
                      caseSensitive = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Цуцлах'),
            ),
            ElevatedButton(
              onPressed: () => _saveRule(
                existingRule,
                nameController.text,
                categoryController.text,
                keywordsController.text,
                caseSensitive,
              ),
              child: Text(existingRule == null ? 'Нэмэх' : 'Засах'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRule(
    CategorizationRule? existingRule,
    String name,
    String category,
    String keywordsText,
    bool caseSensitive,
  ) async {
    if (name.isEmpty || category.isEmpty || keywordsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүх талбарыг бөглөнө үү'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final keywords = keywordsText
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    if (keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хамгийн багадаа нэг түлхүүр үг нэмнэ үү'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    CategorizationRule rule;
    if (existingRule != null) {
      rule = existingRule;
      rule.name = name;
      rule.category = category;
      rule.keywords = keywords;
      rule.caseSensitive = caseSensitive;
      await CategorizationService.instance.updateRule(rule);
    } else {
      rule = CategorizationRule.create(
        name: name,
        keywords: keywords,
        category: category,
        caseSensitive: caseSensitive,
      );
      await CategorizationService.instance.addRule(rule);
    }

    Navigator.of(context).pop();
    if (mounted) {
      _loadRules();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingRule == null
                ? 'Дүрэм амжилттай нэмэгдлээ'
                : 'Дүрэм амжилттай засагдлаа',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Анхны төлөвт буцаах'),
        content: const Text(
          'Энэ нь таны бүх дүрмүүдийг устгаж анхны ангиллын дүрмүүдийг сэргээнэ. Энэ үйлдлийг буцаах боломжгүй.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Цуцлах'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await CategorizationService.instance.resetToDefaults();
              if (mounted) {
                _loadRules();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Дүрмүүд анхны төлөвт буцлаа'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Буцаах'),
          ),
        ],
      ),
    );
  }

  void _showTestDialog() {
    final testController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ангилал турших'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: testController,
              decoration: const InputDecoration(
                labelText: 'Гүйлгээний тайлбар',
                border: OutlineInputBorder(),
                helperText: 'Турших гүйлгээний тайлбар оруулна уу',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Хаах'),
          ),
          ElevatedButton(
            onPressed: () {
              if (testController.text.isNotEmpty) {
                final category = CategorizationService.instance
                    .categorizeTransaction(testController.text);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ангилал: $category'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Турших'),
          ),
        ],
      ),
    );
  }
}
