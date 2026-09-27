import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/create_profile_screen.dart';
import '../../shared/main_shell_screen.dart';
import '../../features/chats/presentation/chat_detail_screen.dart';
import '../../features/feed/presentation/create_post_screen.dart';
import '../../features/videos/presentation/upload_video_screen.dart';
import '../../features/marketplace/presentation/create_product_screen.dart';
import '../../features/marketplace/presentation/product_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/calls/presentation/call_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final otherUserId = state.extra as String? ?? '';
          return ChatDetailScreen(chatId: chatId, otherUserId: otherUserId);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/upload-video',
        builder: (context, state) => const UploadVideoScreen(),
      ),
      GoRoute(
        path: '/create-product',
        builder: (context, state) => const CreateProductScreen(),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/call',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CallScreen(
            channelId: extra['channelId'] ?? '',
            isAudioOnly: extra['isAudioOnly'] ?? false,
            otherUserName: extra['otherUserName'] ?? '',
          );
        },
      ),
    ],
  );
}
