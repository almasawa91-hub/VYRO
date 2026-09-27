import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoriesTab extends StatelessWidget {
  const StoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    final stream = FirebaseFirestore.instance.collection('stories')
        .where('privacy', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(50).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل القصص'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final now = DateTime.now();
        final stories = snapshot.data!.docs.where((doc) {
          final expiresAt = _parseDate(doc.data()['expiresAt']);
          return expiresAt == null || expiresAt.isAfter(now);
        }).toList();

        if (stories.isEmpty) return const Center(child: Text('لا توجد قصص حاليًا'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: stories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = stories[index].data();
            final ownerName = _stringValue(data['ownerName'], fallback: 'مستخدم');
            final text = _stringValue(data['text']);
            final mediaUrl = _stringValue(data['mediaUrl']);
            final type = _stringValue(data['type'], fallback: 'text');

            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.auto_stories)),
                    title: Text(ownerName),
                  ),
                  if (mediaUrl.isNotEmpty && type == 'image')
                    Image.network(
                      mediaUrl,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 120,
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  if (text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(text),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}