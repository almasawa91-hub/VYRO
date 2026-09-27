import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول')));

    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد إشعارات'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final read = data['read'] == true;

              return ListTile(
                tileColor: read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .25),
                leading: Icon(read ? Icons.notifications_none : Icons.notifications_active_outlined),
                title: Text((data['title'] ?? 'إشعار').toString()),
                subtitle: Text((data['body'] ?? '').toString()),
                trailing: read ? null : const Icon(Icons.circle, size: 9),
                onTap: read
                    ? null
                    : () async {
                        try {
                          await doc.reference.update({
                            'read': true,
                            'readAt': FieldValue.serverTimestamp(),
                          });
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر تحديث الإشعار: ' + error.toString())),
                            );
                          }
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}
