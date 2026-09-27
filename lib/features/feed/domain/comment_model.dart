import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String postId;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String text;
  final DateTime createdAt;
  final int likesCount;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.text,
    required this.createdAt,
    this.likesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      commentId: id,
      postId: map['postId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhoto: map['ownerPhoto'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now())
          : DateTime.now(),
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
