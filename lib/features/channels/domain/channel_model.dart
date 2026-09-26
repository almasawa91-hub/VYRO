class ChannelModel {
  final String channelId;
  final String name;
  final String description;
  final String photoUrl;
  final String ownerId;
  final int subscribersCount;
  final DateTime createdAt;

  ChannelModel({
    required this.channelId,
    required this.name,
    this.description = '',
    this.photoUrl = '',
    required this.ownerId,
    this.subscribersCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'channelId': channelId,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'ownerId': ownerId,
      'subscribersCount': subscribersCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map, String id) {
    return ChannelModel(
      channelId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      subscribersCount: (map['subscribersCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
