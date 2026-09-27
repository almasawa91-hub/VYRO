import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../chats/data/chat_repository.dart';

import '../../users/domain/user_model.dart';
import '../../users/data/user_relationship_repository.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepo = AuthRepository();
  final _relationRepo = UserRelationshipRepository();
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _authRepo.getUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _userModel = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('الملف الشخصي غير موجود')),
        body: const Center(child: Text('تعذر العثور على حساب هذا المستخدم')),
      );
    }

    final user = _userModel!;
    final isMe = user.uid == _currentUid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('@${user.username}'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover & Avatar Header
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.surfaceLight,
                  child: user.coverUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: user.coverUrl, fit: BoxFit.cover)
                      : const Icon(Icons.panorama, size: 50, color: AppColors.textMuted),
                ),
                Positioned(
                  bottom: -40,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.background,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.surface,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 42, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Name & Bio
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: const TextStyle(fontSize: 14, color: AppColors.primaryGreen),
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  user.bio,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Followers / Following / Friends Counter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('المتابعون', '${user.followersCount}'),
                _buildStatColumn('يتابع', '${user.followingCount}'),
                _buildStatColumn('الأصدقاء', '${user.friendsCount}'),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            if (!isMe)
              StreamBuilder<Map<String, dynamic>>(
                stream: _relationRepo.getRelationshipStatus(user.uid),
                builder: (context, snapshot) {
                  final status = snapshot.data ?? {'isFollowing': false, 'friendStatus': 'none'};
                  final isFollowing = status['isFollowing'] == true;
                  final friendStatus = status['friendStatus'] as String;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _relationRepo.toggleFollow(user.uid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? AppColors.surfaceLight : AppColors.primaryGreen,
                            ),
                            child: Text(
                              isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                              style: TextStyle(color: isFollowing ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (friendStatus == 'none') {
                                _relationRepo.sendFriendRequest(user.uid);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            child: Text(
                              friendStatus == 'pending'
                                  ? 'تم الإرسال'
                                  : friendStatus == 'accepted'
                                      ? 'صديق'
                                      : 'إضافة صديق',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen),
                          onPressed: () async {
                            try {
                              final chatId = await ChatRepository().getOrCreateChat(user.uid);
                              if (context.mounted) {
                                context.push('/chat/$chatId', extra: user.uid);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تعذر فتح المحادثة: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const Divider(color: AppColors.divider, height: 32),
            const Text('منشورات المستخدم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('لا توجد منشورات حتى الآن', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
