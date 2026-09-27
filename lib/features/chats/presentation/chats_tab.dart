import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';
import 'chat_detail_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ChatRepository();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    return StreamBuilder<List<ChatModel>>(
      stream: repository.watchMyChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المحادثات'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final chats = snapshot.data!;
        if (chats.isEmpty) return const Center(child: Text('لا توجد محادثات بعد'));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUserId = chat.participants.firstWhere((id) => id != currentUid, orElse: () => '');
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(otherUserId.isEmpty ? 'محادثة' : 'مستخدم'),
              subtitle: Text(
                chat.lastMessage.isEmpty ? 'ابدأ المحادثة' : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: chat.lastMessageAt == null
                  ? null
                  : Text(
                      '${chat.lastMessageAt!.day}/${chat.lastMessageAt!.month}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
              onTap: otherUserId.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(chatId: chat.chatId, otherUserId: otherUserId),
                        ),
                      ),
            );
          },
        );
      },
    );
  }
}