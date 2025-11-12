import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Category data
  List<Map<String, dynamic>> _categories = []; // full list from Firestore
  String? _selectedMain;
  String? _selectedSub;
  List<String> _availableSubs = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Fetch from the new structure
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final docSnap = await _firestore
          .collection('list_of_category')
          .doc('categories_doc')
          .get();

      if (docSnap.exists) {
        final data = docSnap.data();
        final raw = data?['category_data'];
        if (raw is List) {
          _categories = [];
          for (var item in raw) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final isArchived = item['isArchived'] == true;
              if (!isArchived) {
                final subs = <String>[];
                final subRaw = item['subcategories'];
                if (subRaw is List) {
                  for (var s in subRaw) {
                    if (s is Map &&
                        s['name'] != null &&
                        s['isArchived'] != true) {
                      subs.add(s['name'].toString());
                    }
                  }
                }
                _categories.add({'name': name, 'subcategories': subs});
              }
            }
          }
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

  void _onMainChanged(String? newMain) {
    setState(() {
      _selectedMain = newMain;
      _selectedSub = null;
      _availableSubs = _categories
          .firstWhere(
              (m) => m['name'] == newMain,
          orElse: () => {'subcategories': []})
      ['subcategories']
          ?.cast<String>() ??
          [];
    });
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a main category.')),
      );
      return;
    }

    if (_availableSubs.isNotEmpty && _selectedSub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subcategory.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mainCategory': _selectedMain ?? '',
        'subCategory': _selectedSub ?? '',
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': _imageUrlController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isArchived': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully!')),
      );

      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedMain = null;
        _selectedSub = null;
        _availableSubs = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _isLoading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Product',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an image URL';
                  }
                  if (!value.startsWith('http')) {
                    return 'Enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedMain,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Main Category',
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem<String>(
                  value: cat['name'] as String,
                  child: Text(cat['name'] as String),
                ))
                    .toList(),
                onChanged: _onMainChanged,
                validator: (value) =>
                value == null ? 'Please select a main category' : null,
              ),
              const SizedBox(height: 16),

              if (_availableSubs.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSub,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Sub Category',
                  ),
                  items: _availableSubs
                      .map((sub) => DropdownMenuItem<String>(
                    value: sub,
                    child: Text(sub),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSub = val;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select a subcategory' : null,
                ),
              if (_availableSubs.isNotEmpty) const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _uploadProduct,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Upload Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
