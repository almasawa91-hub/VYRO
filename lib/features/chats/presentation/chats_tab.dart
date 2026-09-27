import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/chat_repository.dart';
import '../domain/chat_model.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ChatRepository();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Center(
        child: Text('يجب تسجيل الدخول'),
      );
    }

    return StreamBuilder<List<ChatModel>>(
      stream: repository.watchMyChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('تعذر تحميل المحادثات'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final chats = snapshot.data!;

        if (chats.isEmpty) {
          return const Center(
            child: Text('لا توجد محادثات بعد'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];

            final otherUserId = chat.participants.firstWhere(
              (id) => id != currentUid,
              orElse: () => '',
            );

            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(
                otherUserId.isEmpty ? 'محادثة' : 'مستخدم',
              ),
              subtitle: Text(
                chat.lastMessage.isEmpty
                    ? 'ابدأ المحادثة'
                    : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: chat.lastMessageAt == null
                  ? null
                  : Text(
                      _formatDate(chat.lastMessageAt!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
              onTap: otherUserId.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ChatRoute(
                            chatId: chat.chatId,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day}/${local.month}';
  }
}

class _ChatRoute extends StatelessWidget {
  final String chatId;
  final String otherUserId;

  const _ChatRoute({
    required this.chatId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return const _ChatRouteLoader();
        },
      ),
    );
  }
}

class _ChatRouteLoader extends StatelessWidget {
  const _ChatRouteLoader();

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final _ = route;

    return const SizedBox.shrink();
  }
}
