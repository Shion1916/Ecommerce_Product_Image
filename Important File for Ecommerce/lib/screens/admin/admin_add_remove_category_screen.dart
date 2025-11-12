import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddRemoveCategory extends StatefulWidget {
  const AdminAddRemoveCategory({super.key});

  @override
  State<AdminAddRemoveCategory> createState() => _AdminAddRemoveCategoryState();
}

class _AdminAddRemoveCategoryState extends State<AdminAddRemoveCategory> {
  static const String _collection = 'list_of_category';
  static const String _docId = 'categories_doc';
  static const String _field = 'category_data';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mainAddController = TextEditingController();
  final TextEditingController _subAddController = TextEditingController();

  String? _selectedMain;
  static const String addMainSentinel = '__ADD_MAIN__';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _mainAddController.dispose();
    _subAddController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final docSnap = await _firestore.collection(_collection).doc(_docId).get();
      if (!docSnap.exists) {
        setState(() {
          _categories = [];
          _selectedMain = null;
        });
      } else {
        final data = docSnap.data();
        final raw = data?[_field];
        if (raw is List) {
          List<Map<String, dynamic>> parsed = [];
          for (var item in raw) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final isArchived = item['isArchived'] == true;
              final subsRaw = item['subcategories'];
              List<Map<String, dynamic>> subs = [];
              if (subsRaw is List) {
                for (var s in subsRaw) {
                  if (s is Map) {
                    subs.add({
                      'name': s['name']?.toString() ?? '',
                      'isArchived': s['isArchived'] == true,
                    });
                  }
                }
              }
              parsed.add({
                'name': name,
                'isArchived': isArchived,
                'subcategories': subs,
              });
            }
          }
          setState(() {
            _categories = parsed;
            _selectedMain = null;
          });
        } else {
          setState(() {
            _categories = [];
            _selectedMain = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCategoriesToFirestore() async {
    final payload = _categories.map((main) {
      return {
        'name': main['name'],
        'isArchived': main['isArchived'],
        'subcategories': (main['subcategories'] as List)
            .map((s) => {'name': s['name'], 'isArchived': s['isArchived']})
            .toList(),
      };
    }).toList();

    await _firestore.collection(_collection).doc(_docId).set({
      _field: payload,
    }, SetOptions(merge: true));
  }

  // Add a new main category
  Future<void> _addMainCategory() async {
    if (_mainAddController.text.trim().isEmpty) return;
    final newName = _mainAddController.text.trim();

    // Check duplicates
    final exists = _categories.any((m) => (m['name'] as String).toLowerCase() == newName.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Main category already exists.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      _categories.add({
        'name': newName,
        'isArchived': false,
        'subcategories': <Map<String, dynamic>>[],
      });
      await _saveCategoriesToFirestore();
      _mainAddController.clear();
      // refresh local state
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Main category added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add main category: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add a subcategory under selected main
  Future<void> _addSubCategory() async {
    if (_selectedMain == null) return;
    if (_subAddController.text.trim().isEmpty) return;

    final subName = _subAddController.text.trim();
    final mainIndex = _categories.indexWhere((m) => m['name'] == _selectedMain);
    if (mainIndex == -1) return;

    final subs = _categories[mainIndex]['subcategories'] as List;
    final exists = subs.any((s) => (s['name'] as String).toLowerCase() == subName.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory already exists under this main category.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      subs.add({
        'name': subName,
        'isArchived': false,
      });
      await _saveCategoriesToFirestore();
      _subAddController.clear();
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add subcategory: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle main archived state. If archiving (false -> true) then mark all subs archived too.
  Future<void> _toggleMainArchive(int mainIndex, bool newArchived) async {
    setState(() => _isLoading = true);
    try {
      _categories[mainIndex]['isArchived'] = newArchived;
      if (newArchived) {
        // when main turned off/archived, set all subs archived
        final subs = _categories[mainIndex]['subcategories'] as List;
        for (var s in subs) {
          s['isArchived'] = true;
        }
      }
      // if unarchiving main, keep sub states as-is (they can be individually toggled)
      await _saveCategoriesToFirestore();
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newArchived ? 'Category archived' : 'Category restored')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update main category: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle subcategory archived state; only allowed when main is not archived
  Future<void> _toggleSubArchive(int mainIndex, int subIndex, bool newArchived) async {
    setState(() => _isLoading = true);
    try {
      final main = _categories[mainIndex];
      if (main['isArchived'] == true) {
        // shouldn't happen because UI disables switch, but guard anyway
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot toggle subcategory while main is archived.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final subs = main['subcategories'] as List;
      subs[subIndex]['isArchived'] = newArchived;
      await _saveCategoriesToFirestore();
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newArchived ? 'Subcategory archived' : 'Subcategory restored')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update subcategory: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Build dropdown options: existing main names + 'Add Main Category' sentinel
  List<DropdownMenuItem<String>> _buildMainDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    items.add(
      const DropdownMenuItem(
        value: null,
        child: Text('Select Main Category'),
      ),
    );
    for (var main in _categories) {
      items.add(DropdownMenuItem(
        value: main['name'] as String,
        child: Text(main['name'] as String),
      ));
    }
    items.add(const DropdownMenuItem(
      value: addMainSentinel,
      child: Text('Add Main Category'),
    ));
    return items;
  }

  Widget _buildAddSection() {
    final isAddMain = _selectedMain == addMainSentinel;
    final isExistingMain = _selectedMain != null && _selectedMain != addMainSentinel;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Dropdown
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select or Add Main Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedMain,
                items: _buildMainDropdownItems(),
                onChanged: _isLoading
                    ? null
                    : (val) {
                  setState(() {
                    _selectedMain = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (isAddMain) ...[
            TextFormField(
              controller: _mainAddController,
              decoration: const InputDecoration(
                labelText: 'Add Main Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _addMainCategory,
              child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload Main Category'),
            ),
          ],
          if (isExistingMain) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _subAddController,
              decoration: const InputDecoration(
                labelText: 'Add Sub Category for selected main',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _addSubCategory,
              child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload Sub Category'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }

    return Column(
      children: _categories.asMap().entries.map((entry) {
        final mainIndex = entry.key;
        final main = entry.value;
        final mainName = main['name'] as String;
        final mainArchived = main['isArchived'] == true;
        final subs = main['subcategories'] as List;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            initiallyExpanded: false,
            title: Row(
              children: [
                Expanded(child: Text(mainName, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Hide Category', style: TextStyle(fontSize: 12)),
                    Switch.adaptive(
                      value: mainArchived,
                      onChanged: _isLoading ? null : (val) => _toggleMainArchive(mainIndex, val),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              if (subs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('No subcategories'),
                ),
              ...subs.asMap().entries.map((sEntry) {
                final subIndex = sEntry.key;
                final sub = sEntry.value;
                final subName = sub['name'] as String;
                final subArchived = sub['isArchived'] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(subName)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Hide', style: TextStyle(fontSize: 12)),
                          Switch.adaptive(
                            value: subArchived,
                            onChanged: (_isLoading || mainArchived)
                                ? null
                                : (val) => _toggleSubArchive(mainIndex, subIndex, val),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('Add New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildAddSection(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('All Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCategoriesList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
