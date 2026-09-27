import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../features/feed/presentation/feed_tab.dart';
import '../features/chats/presentation/chats_tab.dart';
import '../features/stories/presentation/stories_tab.dart';
import '../features/marketplace/presentation/marketplace_tab.dart';
import '../features/profile/presentation/profile_tab.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 2; // Default to Home Feed Tab

  final List<Widget> _tabs = [
    const ChatsTab(),
    const StoriesTab(),
    const FeedTab(),
    const MarketplaceTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'VYRO - فايرو',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.video_call_outlined, color: AppColors.textPrimary),
            tooltip: 'رفع فيديو',
            onPressed: () => context.push('/upload-video'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryGreen,
              onPressed: () => context.push('/create-post'),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : _currentIndex == 3
              ? FloatingActionButton(
                  backgroundColor: AppColors.primaryPink,
                  onPressed: () => context.push('/create-product'),
                  child: const Icon(Icons.add, color: Colors.black),
                )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble, color: AppColors.primaryGreen),
            label: 'الدردشات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.amp_stories_outlined),
            activeIcon: Icon(Icons.amp_stories, color: AppColors.primaryBlue),
            label: 'القصص',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppColors.primaryGreen),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront, color: AppColors.primaryPink),
            label: 'السوق',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: AppColors.primaryGreen),
            label: 'أنا',
          ),
        ],
      ),
    );
  }
}
