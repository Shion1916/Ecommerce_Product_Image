import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditProductScreen extends StatefulWidget {
  final String productUid;
  const AdminEditProductScreen({required this.productUid, super.key});

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedMainCategory;
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load categories
      DocumentSnapshot catDoc =
      await _firestore.collection('list_of_category').doc('categories_doc').get();

      final categoryDataRaw = catDoc.get('category_data') as List<dynamic>;
      _categories = categoryDataRaw
          .map((cat) => {
        'name': cat['name'],
        'isArchived': cat['isArchived'],
        'subcategories': (cat['subcategories'] as List<dynamic>)
            .map((subcat) => {
          'name': subcat['name'],
          'isArchived': subcat['isArchived']
        })
            .toList()
      })
          .where((cat) => cat['isArchived'] == false)
          .toList();

      // Load product
      DocumentSnapshot productDoc =
      await _firestore.collection('products').doc(widget.productUid).get();
      final productData = productDoc.data() as Map<String, dynamic>?;

      if (productData != null) {
        _nameController.text = productData['name'] ?? '';
        _priceController.text = productData['price']?.toString() ?? '';
        _descriptionController.text = productData['description'] ?? '';
        _imageUrlController.text = productData['imageUrl'] ?? '';
        _selectedMainCategory = productData['mainCategory'];
        _selectedSubCategory = productData['subCategory'];

        // Ensure main category exists
        if (!_categories.any((cat) => cat['name'] == _selectedMainCategory)) {
          _selectedMainCategory = null;
          _selectedSubCategory = null;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product/category data: $e')));
    }
  }

  List<String> getSubCategories() {
    if (_selectedMainCategory == null) return [];
    final selectedCategory = _categories.firstWhere(
            (cat) => cat['name'] == _selectedMainCategory,
        orElse: () => {});
    if (selectedCategory.isEmpty) return [];
    return (selectedCategory['subcategories'] as List<dynamic>)
        .where((subcat) => subcat['isArchived'] == false)
        .map<String>((subcat) => subcat['name'] as String)
        .toList();
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType inputType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'Product Price') {
              if (double.tryParse(value) == null) return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMainCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both main and sub category')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    try {
      await _firestore.collection('products').doc(widget.productUid).update({
        'name': _nameController.text.trim(),
        'price': price,
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'mainCategory': _selectedMainCategory,
        'subCategory': _selectedSubCategory,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );

      // Wait a brief moment so the snackbar shows, then go back
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = getSubCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Product Name', _nameController, TextInputType.text),
              const SizedBox(height: 10),
              _buildTextField('Product Price', _priceController, TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField('Product Description', _descriptionController, TextInputType.text),
              const SizedBox(height: 10),
              _buildTextField('Product Image URL', _imageUrlController, TextInputType.url),
              const SizedBox(height: 20),
              const Text('Product Main Category'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _categories.any((cat) => cat['name'] == _selectedMainCategory)
                    ? _selectedMainCategory
                    : null,
                items: _categories
                    .map((cat) => DropdownMenuItem<String>(
                  value: cat['name'],
                  child: Text(cat['name']),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMainCategory = value;
                    _selectedSubCategory = null;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Product Sub Category'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: subCategories.contains(_selectedSubCategory)
                    ? _selectedSubCategory
                    : null,
                items: subCategories
                    .map((subcat) => DropdownMenuItem(
                  value: subcat,
                  child: Text(subcat),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    child: Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
