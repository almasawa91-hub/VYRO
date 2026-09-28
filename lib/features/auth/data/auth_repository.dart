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

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'لا يوجد مستخدم مسجل الدخول.',
      );
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore
        .collection('usernames')
        .doc(username.trim().toLowerCase())
        .get();

    return !doc.exists;
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(
        doc.data()!,
        doc.id,
      );
    }

    return null;
  }

  Future<void> createProfile({
    required String displayName,
    required String username,
    required String bio,
    File? avatarFile,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final String cleanUsername =
        username.trim().toLowerCase();

    String photoUrl = '';

    if (avatarFile != null) {
      final storageRef = _storage
          .ref()
          .child('users/${user.uid}/avatar.jpg');

      await storageRef.putFile(avatarFile);

      photoUrl = await storageRef.getDownloadURL();
    }

    final usernameDocRef = _firestore
        .collection('usernames')
        .doc(cleanUsername);

    final userDocRef = _firestore
        .collection('users')
        .doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final usernameSnap =
          await transaction.get(usernameDocRef);

      if (usernameSnap.exists) {
        throw Exception(
          'اسم المستخدم محجوز بالفعل، يرجى اختيار اسم آخر',
        );
      }

      transaction.set(
        usernameDocRef,
        {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      final now = DateTime.now();

      final newUser = UserModel(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        displayName: displayName.trim(),
        username: cleanUsername,
        photoUrl: photoUrl,
        bio: bio.trim(),
        createdAt: now,
        updatedAt: now,
      );

      transaction.set(
        userDocRef,
        newUser.toMap(),
      );
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final uid = user.uid;

    final userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final username = userDoc.data()?['username'];

      if (username != null) {
        await _firestore
            .collection('usernames')
            .doc(username)
            .delete();
      }
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .delete();

    await user.delete();
  }
}
