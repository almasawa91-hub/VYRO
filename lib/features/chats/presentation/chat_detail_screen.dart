import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  const ChatDetailScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Chat: $chatId')));
  }
}
