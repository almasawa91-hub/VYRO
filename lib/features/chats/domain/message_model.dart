import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String status;

  const MessageModel({
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
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'status': status,
    };
  }

  factory MessageModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return MessageModel(
      messageId: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'] ?? '',
      createdAt: parseDate(map['createdAt']),
      deliveredAt: parseNullableDate(map['deliveredAt']),
      readAt: parseNullableDate(map['readAt']),
      status: map['status'] ?? 'sent',
    );
  }
}
