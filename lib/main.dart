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

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Request notification permission
    await FirebaseMessaging.instance.requestPermission();

    // 1. Load data dari memori HP (Shared Preferences)
    await appConfig.loadLocalConfig();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // 3. Initialize ApiService
  final dio = Dio();
  final apiService = ApiService(dio);

  // 4. Load application configuration
  await appConfig.initializeApp(apiService);

  runApp(const MyApp());
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
