class CallSignalModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final bool isAudioOnly;
  final String status; // 'offered', 'answered', 'rejected', 'ended'
  final DateTime createdAt;

  CallSignalModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.isAudioOnly,
    this.status = 'offered',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'isAudioOnly': isAudioOnly,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CallSignalModel.fromMap(Map<String, dynamic> map, String id) {
    return CallSignalModel(
      callId: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      isAudioOnly: map['isAudioOnly'] ?? true,
      status: map['status'] ?? 'offered',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
