import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _markNotificationAsRead(DocumentReference docRef) async {
    await docRef.update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _user!.uid)
            .orderBy('isRead', descending: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no notifications.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isUnread = data['isRead'] == false;
              final timestamp = data['createdAt'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat('MM/dd/yy hh:mm a').format(timestamp.toDate())
                  : '';

              return ListTile(
                onTap: () async {
                  if (isUnread) {
                    await doc.reference.update({'isRead': true});
                  }
                },
                leading: isUnread
                    ? const Icon(Icons.circle, color: Colors.red, size: 12)
                    : const Icon(Icons.circle_outlined, color: Colors.grey, size: 12),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${data['body'] ?? ''}\n$formattedDate'),
                isThreeLine: true,

                tileColor: isUnread ? Colors.white : Colors.grey,
              );
            },
          );
        },
      ),
    );
  }
}
