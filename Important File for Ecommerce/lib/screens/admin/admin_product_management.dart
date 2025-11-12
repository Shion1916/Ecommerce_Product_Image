import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin/admin_edit_product_screen.dart';

class AdminProductPanelScreen extends StatefulWidget {
  const AdminProductPanelScreen({super.key});

  @override
  State<AdminProductPanelScreen> createState() => _AdminProductPanelScreenState();
}

class _AdminProductPanelScreenState extends State<AdminProductPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('products').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$name" successfully')),
        );
      }
    }
  }

  Color OffWhite = Color(0xFFF8F4F0);
  Color Taupe = Color(0xFF554940);
  Color SoftGreen = Color(0xFF879A77);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Product',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('isArchived', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                final filtered = docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in filtered) {
                  final category = doc['mainCategory'] ?? 'Uncategorized';
                  grouped.putIfAbsent(category, () => []).add(doc);
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    final categoryName = entry.key;
                    final products = entry.value;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        collapsedBackgroundColor: Colors.grey.shade300, // when closed
                        backgroundColor: Colors.grey.shade100,          // when expanded
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          categoryName,
                          style: TextStyle(
                            color: Taupe,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: products.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final productName = data['name'] ?? 'Unknown Product';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SoftGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(productName,
                                style: TextStyle(
                                    color: OffWhite
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: OffWhite),
                                    onPressed: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminEditProductScreen(productUid: doc.id),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('"$productName" updated successfully!')),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: OffWhite),
                                    onPressed: () => _confirmDelete(context, doc.id, productName),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
