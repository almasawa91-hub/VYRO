import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:vyro/core/theme/app_theme.dart';
import 'package:vyro/core/routing/app_router.dart';

bool isFirebaseInitialized = false;
String? firebaseInitError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
  } catch (e) {
    isFirebaseInitialized = false;
    firebaseInitError = e.toString();
    debugPrint('[VYRO FIREBASE INIT ERROR]: $e');
  }

  runApp(
    const ProviderScope(
      child: VyroApp(),
    ),
  );
}

class VyroApp extends StatelessWidget {
  const VyroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VYRO - فايرو',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Full RTL Language Support (Arabic default)
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: AppRouter.router,
    );
  }
}
