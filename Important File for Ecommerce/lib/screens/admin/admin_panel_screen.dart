import 'package:flutter/material.dart';
import 'package:ecommerce_app/screens/admin/admin_order_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_add_product_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_product_management.dart';
import 'package:ecommerce_app/screens/admin/admin_add_remove_category_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();

  Color RichBlack = Color(0xFF1D1F24);
  Color OffWhite = Color(0xFFF8F4F0);
  Color Charcoal = Color(0xFF73787C);
  Color Gray = Color(0xFFC5C6C7);
  Color PaleBlue = Color(0xFFD7E5F0);
  Color Beige = Color(0xFFC9AD93);
  Color Taupe = Color(0xFF554940);
  Color SoftGreen = Color(0xFF879A77);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Manage All Orders'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminOrderScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Manage Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AdminProductPanelScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Add Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminAddProductScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Add Category'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminAddRemoveCategory(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
