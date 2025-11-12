import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/widgets/notification_icon.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _categories = ['All'];
  List<String> _mainCategories = [];
  List<String> _archiveCategories = [];

  TabController? _tabController;
  TabController? _subTabController;

  String _selectedCategory = 'All';
  bool _isLoadingCategories = true;
  bool _showSubcategories = true;

  Map<String, List<String>> _subcategories = {};
  String? _selectedSubcategory;
  String? _lastTappedCategory;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _subTabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc =
      await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('list_of_category')
          .doc('categories_doc')
          .get();
      final data = doc.data();

      if (data != null && data['category_data'] != null) {
        final List categories = data['category_data'];

        _categories = ['All'];
        _subcategories = {};

        for (var cat in categories) {
          if (cat['isArchived'] == false) {
            final mainName = cat['name'];
            _categories.add(mainName);
            _mainCategories.add(mainName);

            final subList = <String>[];
            if (cat['subcategories'] != null) {
              for (var sub in cat['subcategories']) {
                if (sub['isArchived'] == false) {
                  subList.add(sub['name']);
                }
              }
            }
            if (subList.isNotEmpty) {
              subList.insert(0, 'All');
            }
            _subcategories[mainName] = subList;
          } else {
            _archiveCategories.add(cat['name']);
          }
        }

        _tabController?.dispose();
        _tabController = TabController(length: _categories.length, vsync: this);

        _selectedCategory = _categories.first;
        final initialSubcats = _subcategories[_selectedCategory] ?? [];
        _subTabController?.dispose();
        _subTabController = TabController(length: initialSubcats.length, vsync: this);
        _selectedSubcategory = initialSubcats.isNotEmpty ? initialSubcats.first : null;
      }
    } catch (e) {
      print('Error loading categories: $e');
    }

    setState(() => _isLoadingCategories = false);
  }

  Stream<List<QueryDocumentSnapshot>> _getProductsStream() {
    Query query = _firestore.collection('products')
        .where('isArchived', isEqualTo: false);

    if (_selectedCategory != 'All') {
      query = query.where('mainCategory', isEqualTo: _selectedCategory)
          .orderBy('createdAt', descending: true);
    }

    if (_selectedSubcategory != null &&
        _selectedSubcategory!.isNotEmpty &&
        _selectedSubcategory != 'All') {
      query = query.where('subCategory', isEqualTo: _selectedSubcategory);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs;
    });
  }

  Color OffWhite = Color(0xFFF8F4F0);
  Color Gray = Color(0xFFC5C6C7);
  Color Taupe = Color(0xFF554940);

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/images/splash_logo.png',
                height: 40,
              ),
            ),
            Expanded(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: OffWhite,
                unselectedLabelColor: Gray,
                indicatorColor: OffWhite,
                tabs: _categories.map((c) => Tab(text: c)).toList(),
                onTap: (index) {
                  final tappedCategory = _categories[index];
                  setState(() {
                    if (_lastTappedCategory == tappedCategory) {
                      _showSubcategories = !_showSubcategories;
                    } else {
                      _showSubcategories = true;
                    }

                    _selectedCategory = tappedCategory;

                    final subcats = _subcategories[_selectedCategory] ?? [];
                    _subTabController?.dispose();
                    _subTabController = TabController(length: subcats.length, vsync: this);
                    _selectedSubcategory = subcats.isNotEmpty ? subcats.first : null;

                    _lastTappedCategory = tappedCategory;
                  });
                },
              )
            ),
            Row(
              children: [
                if (_userRole == 'user') ...[
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return Badge(
                        label: Text(cart.itemCount.toString()),
                        isLabelVisible: cart.itemCount > 0,
                        child: IconButton(
                          icon: Icon(Icons.shopping_cart,
                              color: OffWhite),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const CartScreen()));
                          },
                        ),
                      );
                    },
                  ),
                  const NotificationIcon(),
                  IconButton(
                    icon:
                    Icon(Icons.receipt_long, color: OffWhite),
                    tooltip: 'My Orders',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                          const OrderHistoryScreen()));
                    },
                  ),
                ],
                if (_userRole == 'admin') ...[
                  IconButton(
                    icon: Icon(Icons.admin_panel_settings,
                        color: OffWhite),
                    tooltip: 'Admin Panel',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                          const AdminPanelScreen()));
                    },
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.person_outline,
                      color: OffWhite),
                  tooltip: 'Profile',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ProfileScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showSubcategories &&
              _selectedCategory != 'All' &&
              _subcategories[_selectedCategory] != null &&
              _subcategories[_selectedCategory]!.isNotEmpty)
            Material(
              elevation: 2,
              color: Taupe,
              child: TabBar(
                controller: _subTabController,
                isScrollable: true,
                labelColor: OffWhite,
                unselectedLabelColor: Gray,
                indicatorColor: OffWhite,
                tabs: _subcategories[_selectedCategory]!
                    .map((sub) => Tab(text: sub))
                    .toList(),
                onTap: (index) {
                  setState(() {
                    _selectedSubcategory = _subcategories[_selectedCategory]![index];
                    _showSubcategories = false;
                  });
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found in this category.'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productDoc = products[index];
                    final productData =
                    productDoc.data() as Map<String, dynamic>;
                    return ProductCard(
                      productName: productData['name'],
                      maincategory: productData['mainCategory'],
                      subcategory: productData['subCategory'],
                      description: productData['description'],
                      price: productData['price'],
                      imageUrl: productData['imageUrl'],
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productData: productData,
                            productId: productDoc.id,
                          ),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
      (_userRole == 'user' || _userRole == 'admin')
          ? (_userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('chats')
            .doc(_currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              unreadCount = (data as Map<String, dynamic>)[
              'unreadByUserCount'] ??
                  0;
            }
          }
          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : StreamBuilder<QuerySnapshot>(
        stream:
        _firestore.collection('chats').snapshots(),
        builder: (context, snapshot) {
          int totalUnreadCount = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data()
              as Map<String, dynamic>?;
              if (data != null) {
                totalUnreadCount +=
                (data['unreadByAdminCount'] ??
                    0) as int;
              }
            }
          }
          return Badge(
            label: Text('$totalUnreadCount'),
            isLabelVisible: totalUnreadCount > 0,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('View User Chats'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                    const AdminChatListScreen(),
                  ),
                );
              },
            ),
          );
        },
      ))
          : null,
    );
  }
}

