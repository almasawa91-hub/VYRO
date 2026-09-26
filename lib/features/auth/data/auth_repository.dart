import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../users/domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verify Phone Number with real Firebase Phone Auth
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerified(credential);
      },
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Verify OTP
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String userOtp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: userOtp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  // Get User Profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Create Profile & atomic username claim using Firestore Transaction to eliminate race conditions
  Future<void> createProfile({
    required String displayName,
    required String username,
    required String bio,
    File? avatarFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    final String cleanUsername = username.trim().toLowerCase();

    // Upload avatar first if exists
    String photoUrl = '';
    if (avatarFile != null) {
      final storageRef = _storage.ref().child('users/${user.uid}/avatar.jpg');
      await storageRef.putFile(avatarFile);
      photoUrl = await storageRef.getDownloadURL();
    }

    final usernameDocRef = _firestore.collection('usernames').doc(cleanUsername);
    final userDocRef = _firestore.collection('users').doc(user.uid);

    // Atomic transaction ensuring zero race conditions
    await _firestore.runTransaction((transaction) async {
      final usernameSnap = await transaction.get(usernameDocRef);
      if (usernameSnap.exists) {
        throw Exception('اسم المستخدم محجوز بالفعل، يرجى اختيار اسم آخر');
      }

      transaction.set(usernameDocRef, {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newUser = UserModel(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        displayName: displayName.trim(),
        username: cleanUsername,
        photoUrl: photoUrl,
        bio: bio.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      transaction.set(userDocRef, newUser.toMap());
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account completely
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final username = userDoc.data()?['username'];
      if (username != null) {
        await _firestore.collection('usernames').doc(username).delete();
      }
    }

    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
  }
}
