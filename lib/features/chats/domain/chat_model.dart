class ChatModel {
  final String chatId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }

  factory ChatModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      try {
        final dynamic timestamp = value;
        return timestamp.toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      try {
        final dynamic timestamp = value;
        return timestamp.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return ChatModel(
      chatId: id,
      participants: List<String>.from(
        map['participants'] ?? const <String>[],
      ),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageAt: parseNullableDate(map['lastMessageAt']),
    );
  }
}
