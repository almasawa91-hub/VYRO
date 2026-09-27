import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRelationshipRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream relationship status between current user and target user
  Stream<Map<String, dynamic>> getRelationshipStatus(String targetUid) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) {
      return Stream.value({'isFollowing': false, 'friendStatus': 'none'});
    }

    final followDocRef = _firestore.collection('follows').doc('${currentUid}_$targetUid');
    final friendReqRef = _firestore.collection('friendRequests').doc('${currentUid}_$targetUid');

    return followDocRef.snapshots().asyncMap((followSnap) async {
      final isFollowing = followSnap.exists;
      final friendSnap = await friendReqRef.get();
      String friendStatus = 'none';
      if (friendSnap.exists) {
        friendStatus = friendSnap.data()?['status'] ?? 'pending';
      }
      return {
        'isFollowing': isFollowing,
        'friendStatus': friendStatus,
      };
    });
  }

  // Follow / Unfollow User with transactional counter updates
  Future<void> toggleFollow(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    final followDocRef = _firestore.collection('follows').doc('${currentUid}_$targetUid');
    await _firestore.runTransaction((transaction) async {
      final followSnap = await transaction.get(followDocRef);

      if (followSnap.exists) {
        // Unfollow
        transaction.delete(followDocRef);
      } else {
        // Follow
        transaction.set(followDocRef, {
          'followerId': currentUid,
          'followingId': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Send Friend Request
  Future<void> sendFriendRequest(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    final reqRef = _firestore.collection('friendRequests').doc('${currentUid}_$targetUid');
    await reqRef.set({
      'senderId': currentUid,
      'receiverId': targetUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Accept Friend Request
  Future<void> acceptFriendRequest(String senderUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    final reqRef = _firestore.collection('friendRequests').doc('${senderUid}_$currentUid');
    final ids = [currentUid, senderUid]..sort();
    final friendRef = _firestore.collection('friends').doc('${ids[0]}_${ids[1]}');

    await _firestore.runTransaction((transaction) async {
      transaction.update(reqRef, {'status': 'accepted'});
      transaction.set(friendRef, {
        'user1': ids[0],
        'user2': ids[1],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
