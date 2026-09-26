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
    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      final followSnap = await transaction.get(followDocRef);

      if (followSnap.exists) {
        // Unfollow
        transaction.delete(followDocRef);
        transaction.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
        transaction.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        // Follow
        transaction.set(followDocRef, {
          'followerId': currentUid,
          'followingId': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
        transaction.update(targetUserRef, {'followersCount': FieldValue.increment(1)});
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
    final friendRef1 = _firestore.collection('friends').doc('${currentUid}_$senderUid');
    final friendRef2 = _firestore.collection('friends').doc('${senderUid}_$currentUid');

    await _firestore.runTransaction((transaction) async {
      transaction.update(reqRef, {'status': 'accepted'});
      transaction.set(friendRef1, {
        'user1': currentUid,
        'user2': senderUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(friendRef2, {
        'user1': senderUid,
        'user2': currentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(_firestore.collection('users').doc(currentUid), {'friendsCount': FieldValue.increment(1)});
      transaction.update(_firestore.collection('users').doc(senderUid), {'friendsCount': FieldValue.increment(1)});
    });
  }
}
