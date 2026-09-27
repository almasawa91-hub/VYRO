import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/feed_repository.dart';
import '../domain/post_model.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = FeedRepository();
    return StreamBuilder<List<PostModel>>(
      stream: repo.getFeedPosts(),
      builder: (context, snap) {
        if (snap.hasError) return _StateMessage('تعذر تحميل المنشورات');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snap.data!;
        if (posts.isEmpty) {
          return _EmptyState(
            icon: Icons.dynamic_feed_outlined,
            title: 'لا توجد منشورات بعد',
            action: 'أنشئ أول منشور',
            onTap: () => context.push('/create-post'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => await Future<void>.delayed(const Duration(milliseconds: 250)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (_, i) => _PostCard(post: posts[i], repo: repo),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final FeedRepository repo;
  const _PostCard({required this.post, required this.repo});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: post.ownerPhoto.isEmpty ? null : CachedNetworkImageProvider(post.ownerPhoto),
              child: post.ownerPhoto.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(post.ownerName, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text('${post.createdAt.day}/${post.createdAt.month}'),
          ]),
          if (post.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.text, style: const TextStyle(fontSize: 16)),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: post.mediaUrls.first, height: 260, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            IconButton(
              onPressed: () => repo.toggleReaction(post.postId, 'like'),
              icon: const Icon(Icons.thumb_up_alt_outlined),
            ),
            Text('${post.likesCount}'),
            const SizedBox(width: 16),
            Icon(Icons.comment_outlined, size: 20),
            const SizedBox(width: 5),
            Text('${post.commentsCount}'),
          ]),
        ]),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String text;
  const _StateMessage(this.text);
  @override Widget build(BuildContext context) => Center(child: Text(text));
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, action; final VoidCallback onTap;
  const _EmptyState({required this.icon, required this.title, required this.action, required this.onTap});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 60),
    const SizedBox(height: 12),
    Text(title),
    const SizedBox(height: 12),
    FilledButton(onPressed: onTap, child: Text(action)),
  ]));
}
