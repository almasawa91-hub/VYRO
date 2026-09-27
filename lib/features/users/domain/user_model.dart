import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final String photoUrl;
  final String coverUrl;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int postsCount;
  final int videosCount;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    this.photoUrl = '',
    this.coverUrl = '',
    this.bio = '',
    required this.createdAt,
    required this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.postsCount = 0,
    this.videosCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'friendsCount': friendsCount,
      'postsCount': postsCount,
      'videosCount': videosCount,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      bio: map['bio'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now())
          : DateTime.now(),
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      friendsCount: (map['friendsCount'] as num?)?.toInt() ?? 0,
      postsCount: (map['postsCount'] as num?)?.toInt() ?? 0,
      videosCount: (map['videosCount'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? (map['lastSeen'] is Timestamp ? (map['lastSeen'] as Timestamp).toDate() : DateTime.tryParse(map['lastSeen']?.toString() ?? '')) : null,
    );
  }
}
