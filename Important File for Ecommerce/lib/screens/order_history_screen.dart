import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/widgets/order_card.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: user == null
          ? const Center(
        child: Text('Please log in to see your orders.'),
      )
          : StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('You have not placed any orders yet.'),
            );
          }

          final orderDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              final orderData = orderDocs[index].data() as Map<String, dynamic>;

              return OrderCard(orderData: orderData);
            },
          );
        },
      ),
    );
  }
}
