import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/video_model.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of ranking videos for "For You"
  Stream<List<VideoModel>> getForYouVideos() {
    return _firestore
        .collection('videos')
        .where('privacy', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Upload Video file with progress callback
  Future<void> uploadVideo({
    required File videoFile,
    required String description,
    required List<String> hashtags,
    required Function(double progress) onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final ownerName = userDoc.data()?['displayName'] ?? 'مستخدم VYRO';
    final ownerPhoto = userDoc.data()?['photoUrl'] ?? '';

    final videoId = _firestore.collection('videos').doc().id;

    final storageRef = _storage.ref().child('videos/${user.uid}/$videoId/video.mp4');
    final uploadTask = storageRef.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    await uploadTask;
    final videoUrl = await storageRef.getDownloadURL();

    final videoModel = VideoModel(
      videoId: videoId,
      ownerId: user.uid,
      ownerName: ownerName,
      ownerPhoto: ownerPhoto,
      videoUrl: videoUrl,
      thumbnailUrl: '', // Generated or video poster
      description: description,
      hashtags: hashtags,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('videos').doc(videoId).set(videoModel.toMap());
    await _firestore.collection('users').doc(user.uid).update({
      'videosCount': FieldValue.increment(1),
    });
  }

  // Toggle video like
  Future<void> toggleLike(String videoId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final videoRef = _firestore.collection('videos').doc(videoId);
    final likeRef = _firestore.collection('videos').doc(videoId).collection('likes').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(likeRef);
      if (doc.exists) {
        transaction.delete(likeRef);
        transaction.update(videoRef, {'likesCount': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(videoRef, {'likesCount': FieldValue.increment(1)});
      }
    });
  }

  // Anti-inflation view tracking: records view doc videoViews/{videoId}_{viewerId}
  Future<void> recordView(String videoId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final viewDocRef = _firestore.collection('videoViews').doc('${videoId}_${user.uid}');
    final videoRef = _firestore.collection('videos').doc(videoId);

    final viewSnap = await viewDocRef.get();
    if (!viewSnap.exists) {
      await viewDocRef.set({
        'videoId': videoId,
        'viewerId': user.uid,
        'watchedAt': FieldValue.serverTimestamp(),
      });
      await videoRef.update({'viewsCount': FieldValue.increment(1)});
    }
  }

  // Share count increment
  Future<void> incrementShareCount(String videoId) async {
    await _firestore.collection('videos').doc(videoId).update({
      'sharesCount': FieldValue.increment(1),
    });
  }
}
