class VideoModel {
  final String videoId;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;
  final List<String> hashtags;
  final String soundId;
  final DateTime createdAt;
  final double duration;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final String privacy;

  VideoModel({
    required this.videoId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    this.hashtags = const [],
    this.soundId = 'original',
    required this.createdAt,
    this.duration = 0.0,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.privacy = 'public',
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'hashtags': hashtags,
      'soundId': soundId,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'savesCount': savesCount,
      'privacy': privacy,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map, String id) {
    return VideoModel(
      videoId: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhoto: map['ownerPhoto'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      description: map['description'] ?? '',
      hashtags: List<String>.from(map['hashtags'] ?? []),
      soundId: map['soundId'] ?? 'original',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      duration: (map['duration'] as num?)?.toDouble() ?? 0.0,
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (map['sharesCount'] as num?)?.toInt() ?? 0,
      savesCount: (map['savesCount'] as num?)?.toInt() ?? 0,
      privacy: map['privacy'] ?? 'public',
    );
  }
}
