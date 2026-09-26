class GroupModel {
  final String groupId;
  final String name;
  final String photoUrl;
  final List<String> memberIds;
  final List<String> adminIds;
  final String createdBy;
  final DateTime createdAt;

  GroupModel({
    required this.groupId,
    required this.name,
    this.photoUrl = '',
    this.memberIds = const [],
    this.adminIds = const [],
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'photoUrl': photoUrl,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
