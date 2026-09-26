class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String text;
  final String type; // 'text', 'image', 'voice', 'location', 'contact'
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String status; // 'sending', 'sent', 'delivered', 'read'

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.mediaUrl = '',
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.status = 'sent',
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'status': status,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: map['deliveredAt'] != null ? DateTime.tryParse(map['deliveredAt']) : null,
      readAt: map['readAt'] != null ? DateTime.tryParse(map['readAt']) : null,
      status: map['status'] ?? 'sent',
    );
  }
}
