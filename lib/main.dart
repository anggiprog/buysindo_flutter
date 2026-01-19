import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:rutino_customer/core/network/api_service.dart';
import 'package:rutino_customer/core/app_config.dart';
import 'package:rutino_customer/ui/splash_screen.dart';
import 'package:rutino_customer/ui/auth/login_screen.dart';
import 'package:rutino_customer/ui/home/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  // 1. Ensure binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase FIRST (required before other operations)
  debugPrint('🔥 Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Request notification permission
    await FirebaseMessaging.instance.requestPermission();
    debugPrint('✅ Notification permission requested');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // 3. Load cached config dari SharedPreferences (FAST - dari local storage)
  debugPrint('📥 Loading cached config from SharedPreferences...');
  await appConfig.loadLocalConfig();
  debugPrint('✅ Cached config loaded. Tampilan: "${appConfig.tampilan}"');

  // 4. Start API initialization in background (fire and forget)
  debugPrint('🌐 Starting API config fetch in background...');
  _fetchConfigAsync();

  runApp(const MyApp());
}

/// Initialize Firebase & API config in background tanpa blocking UI
Future<void> _fetchConfigAsync() async {
  try {
    debugPrint('🌐 [BACKGROUND] Fetching config dari API...');
    final dio = Dio();
    final apiService = ApiService(dio);
    await appConfig.initializeApp(apiService);
    debugPrint(
      '✅ [BACKGROUND] Config dari API selesai. Tampilan: "${appConfig.tampilan}"',
    );
  } catch (e) {
    debugPrint('❌ [BACKGROUND] API config fetch error: $e');
  }
}

/// Background message handler for Firebase Cloud Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        return MaterialApp(
          title: appConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: appConfig.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: appConfig.primaryColor,
              brightness: appConfig.primaryColor.computeLuminance() > 0.5
                  ? Brightness.light
                  : Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: appConfig.textColor,
            ),
          ),
          routes: {
            '/login': (ctx) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
