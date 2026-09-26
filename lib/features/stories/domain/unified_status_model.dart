class UnifiedStatusModel {
  final String statusId;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String mediaUrl;
  final String text;
  final String type; // 'image', 'video', 'text'
  final bool isStory;
  final bool isShortVideo;
  final bool isSocialPost;
  final DateTime createdAt;
  final DateTime expiresAt;

  UnifiedStatusModel({
    required this.statusId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.mediaUrl,
    this.text = '',
    this.type = 'image',
    this.isStory = true,
    this.isShortVideo = false,
    this.isSocialPost = false,
    required this.createdAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'mediaUrl': mediaUrl,
      'text': text,
      'type': type,
      'isStory': isStory,
      'isShortVideo': isShortVideo,
      'isSocialPost': isSocialPost,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory UnifiedStatusModel.fromMap(Map<String, dynamic> map, String id) {
    return UnifiedStatusModel(
      statusId: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhoto: map['ownerPhoto'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'image',
      isStory: map['isStory'] ?? true,
      isShortVideo: map['isShortVideo'] ?? false,
      isSocialPost: map['isSocialPost'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt']) ?? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
