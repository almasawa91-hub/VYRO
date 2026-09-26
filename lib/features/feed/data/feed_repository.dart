import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/post_model.dart';
import '../domain/comment_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of Public Feed Posts with cursor pagination capability
  Stream<List<PostModel>> getFeedPosts({DocumentSnapshot? startAfterDoc}) {
    var query = _firestore
        .collection('posts')
        .where('privacy', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Create new post with image attachments
  Future<void> createPost({
    required String text,
    required String privacy,
    List<File> imageFiles = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    // Fetch author details
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final ownerName = userDoc.data()?['displayName'] ?? 'مستخدم VYRO';
    final ownerPhoto = userDoc.data()?['photoUrl'] ?? '';

    final postId = _firestore.collection('posts').doc().id;
    List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final ref = _storage.ref().child('posts/${user.uid}/$postId/image_$i.jpg');
      await ref.putFile(imageFiles[i]);
      final url = await ref.getDownloadURL();
      uploadedUrls.add(url);
    }

    final newPost = PostModel(
      postId: postId,
      ownerId: user.uid,
      ownerName: ownerName,
      ownerPhoto: ownerPhoto,
      text: text,
      mediaUrls: uploadedUrls,
      type: uploadedUrls.isNotEmpty ? 'image' : 'text',
      privacy: privacy,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').doc(postId).set(newPost.toMap());
  }

  // Toggle reaction with support for 7 distinct reaction types ('like', 'love', 'support', 'haha', 'wow', 'sad', 'angry')
  Future<void> toggleReaction(String postId, String reactionType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    final reactionRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final reactionSnap = await transaction.get(reactionRef);

      if (reactionSnap.exists) {
        final currentType = reactionSnap.data()?['type'];
        if (currentType == reactionType) {
          // Remove reaction
          transaction.delete(reactionRef);
          transaction.update(postRef, {'likesCount': FieldValue.increment(-1)});
        } else {
          // Change reaction type
          transaction.update(reactionRef, {
            'type': reactionType,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Add new reaction
        transaction.set(reactionRef, {
          'type': reactionType,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likesCount': FieldValue.increment(1)});
      }
    });
  }

  // Stream comments for post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add Comment
  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final ownerName = userDoc.data()?['displayName'] ?? 'مستخدم VYRO';
    final ownerPhoto = userDoc.data()?['photoUrl'] ?? '';

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    final comment = CommentModel(
      commentId: commentRef.id,
      postId: postId,
      ownerId: user.uid,
      ownerName: ownerName,
      ownerPhoto: ownerPhoto,
      text: text,
      createdAt: DateTime.now(),
    );

    await commentRef.set(comment.toMap());
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }
}
