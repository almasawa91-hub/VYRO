import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/chat_model.dart';
import '../domain/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  String buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final uid = currentUid;

    if (uid == null) {
      throw StateError('يجب تسجيل الدخول أولاً.');
    }

    if (otherUserId.isEmpty || otherUserId == uid) {
      throw ArgumentError('المستخدم الآخر غير صالح.');
    }

    final chatId = buildChatId(uid, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      final now = FieldValue.serverTimestamp();

      await chatRef.set({
        'chatId': chatId,
        'participants': [uid, otherUserId],
        'createdAt': now,
        'updatedAt': now,
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageAt': null,
      });
    }

    return chatId;
  }

  Stream<List<ChatModel>> watchMyChats() {
    final uid = currentUid;

    if (uid == null) {
      return Stream.value(const <ChatModel>[]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) {
            final chats = snapshot.docs
                .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
                .toList();
            chats.sort((a, b) =>
                (b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
            return chats;
          },
        );
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MessageModel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = currentUid;

    if (uid == null) {
      throw StateError('يجب تسجيل الدخول أولاً.');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'messageId': messageRef.id,
      'chatId': chatId,
      'senderId': uid,
      'text': cleanText,
      'type': 'text',
      'mediaUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'deliveredAt': null,
      'readAt': null,
      'status': 'sent',
    });

    batch.update(chatRef, {
      'lastMessage': cleanText,
      'lastMessageSenderId': uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final uid = currentUid;

    if (uid == null) return;

    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: uid)
        .where('readAt', isNull: true)
        .limit(50)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
        'status': 'read',
      });
    }

    await batch.commit();
  }
}
