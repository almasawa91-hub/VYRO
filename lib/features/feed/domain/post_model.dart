class PostModel {
  final String postId;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String text;
  final List<String> mediaUrls;
  final String type; // 'text', 'image', 'video', 'poll'
  final String privacy; // 'public', 'friends', 'only_me'
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final Map<String, dynamic> reactions;

  PostModel({
    required this.postId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.text,
    this.mediaUrls = const [],
    this.type = 'text',
    this.privacy = 'public',
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reactions = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'text': text,
      'mediaUrls': mediaUrls,
      'type': type,
      'privacy': privacy,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'reactions': reactions,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      postId: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhoto: map['ownerPhoto'] ?? '',
      text: map['text'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      type: map['type'] ?? 'text',
      privacy: map['privacy'] ?? 'public',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (map['sharesCount'] as num?)?.toInt() ?? 0,
      reactions: Map<String, dynamic>.from(map['reactions'] ?? {}),
    );
  }
}
