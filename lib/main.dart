import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:rutino_customer/core/network/api_service.dart';
import 'package:rutino_customer/core/app_config.dart';
import 'package:rutino_customer/ui/splash_screen.dart';
import 'package:rutino_customer/ui/auth/login_screen.dart';
import 'package:rutino_customer/ui/auth/register_screen.dart';
import 'package:rutino_customer/ui/home/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:rutino_customer/ui/home/customer/notifications_page.dart';

// Global navigator key so we can navigate from background/message handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin instance
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  final mainStartTime = DateTime.now();

  // 1. Ensure binding is initialized (FAST - ~1ms)
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('⚡ Binding initialized');

  // 2. Load environment variables ASYNC in background
  debugPrint('📋 Loading .env file (background)...');
  _loadEnvAsync();

  // 3. Preserve native splash screen sampai Flutter UI siap (FAST - ~5ms)
  debugPrint('🎨 Preserving native splash...');
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  // 4. Load cached config dari SharedPreferences (FAST - dari local storage ~50-100ms)
  debugPrint('📥 Loading cached config...');
  final cacheStart = DateTime.now();
  await appConfig.loadLocalConfig();
  final cacheDuration = DateTime.now().difference(cacheStart);
  debugPrint(
    '✅ Cached config loaded (${cacheDuration.inMilliseconds}ms). Tampilan: "${appConfig.tampilan}"',
  );

  // 5. Initialize Firebase di background (NON-BLOCKING UI) - TANPA AWAIT
  debugPrint('🔥 Starting Firebase initialization (background)...');
  _initializeFirebaseAsync();

  // 6. Start API initialization in background - TANPA AWAIT
  debugPrint('🌐 Starting API config fetch (background)...');
  _fetchConfigAsync();

  final totalDuration = DateTime.now().difference(mainStartTime);
  debugPrint(
    '⏱️ Total main() duration: ${totalDuration.inMilliseconds}ms (READY TO SHOW APP)',
  );

  runApp(const MyApp());
}

/// Load .env file in background (non-blocking)
Future<void> _loadEnvAsync() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env loaded in background');
  } catch (e) {
    debugPrint('⚠️ .env loading failed: $e');
  }
}

/// Initialize Firebase in background (non-blocking)
Future<void> _initializeFirebaseAsync() async {
  try {
    final firebaseStart = DateTime.now();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final firebaseDuration = DateTime.now().difference(firebaseStart);
    debugPrint('✅ Firebase initialized (${firebaseDuration.inMilliseconds}ms)');

    // Setup notification channels for Android - DEFER ke later
    debugPrint('📢 [FCM] Preparing notification channels (deferred)...');
    Future.microtask(() => _initializeNotificationChannels());

    // Setup Firebase Messaging
    Future.microtask(() async {
      try {
        // 1. Request notification permission
        debugPrint('🔔 [FCM] Requesting notification permission...');
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          provisional: false,
          sound: true,
        );

        debugPrint(
          '✅ [FCM] Notification permission: ${settings.authorizationStatus}',
        );

        // 2. Register background message handler
        debugPrint('📨 [FCM] Registering background message handler...');
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        debugPrint('✅ [FCM] Background message handler registered');

        // 3. Get initial FCM token
        debugPrint('🔑 [FCM] Getting initial device token...');
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('✅ [FCM] Device Token: $token');

        // 4. Listen to token refresh
        debugPrint('👂 [FCM] Listening to token refresh...');
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 [FCM] Token refreshed: $newToken');
          // TODO: Send new token to your backend
        });

        debugPrint('✅ [FCM] Firebase Messaging fully initialized!');
      } catch (e) {
        debugPrint('⚠️ [FCM] Error during FCM setup: $e');
      }
    });
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
}

/// Initialize notification channels for Android
Future<void> _initializeNotificationChannels() async {
  try {
    // Android notification channel initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel for FCM
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'buysindo_fcm_channel', // id
      'Buysindo Notifications', // title
      description: 'Notifications from Buysindo',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('✅ [Notification] Channel created: buysindo_fcm_channel');
  } catch (e) {
    debugPrint('⚠️ [Notification] Error creating channels: $e');
  }
}

/// Initialize Firebase & API config in background tanpa blocking UI
Future<void> _fetchConfigAsync() async {
  try {
    debugPrint('🌐 [BACKGROUND] Fetching config dari API...');
    final apiStart = DateTime.now();
    final dio = Dio();
    final apiService = ApiService(dio);
    await appConfig.initializeApp(apiService);
    final apiDuration = DateTime.now().difference(apiStart);
    debugPrint(
      '✅ [BACKGROUND] Config dari API selesai (${apiDuration.inMilliseconds}ms). Tampilan: "${appConfig.tampilan}"',
    );
  } catch (e) {
    debugPrint('❌ [BACKGROUND] API config fetch error: $e');
  }
}

/// Background message handler for Firebase Cloud Messaging
/// This runs when app is in background or terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BACKGROUND FCM] Message received: ${message.messageId}');
  debugPrint('📌 [BACKGROUND FCM] Title: ${message.notification?.title}');
  debugPrint('📌 [BACKGROUND FCM] Body: ${message.notification?.body}');
  debugPrint('📌 [BACKGROUND FCM] Data: ${message.data}');

  // Anda bisa add custom logic di sini untuk handle background notifications
  // Misalnya: simpan ke local storage, trigger background fetch, dll
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupForegroundMessageHandler();
  }

  /// Setup foreground message handler
  /// This runs when app is in foreground
  void _setupForegroundMessageHandler() {
    debugPrint('📱 [FCM] Setting up foreground message handler...');

    // 1. Handle message received when app in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FOREGROUND FCM] Message received: ${message.messageId}');
      debugPrint('📌 [FOREGROUND FCM] Title: ${message.notification?.title}');
      debugPrint('📌 [FOREGROUND FCM] Body: ${message.notification?.body}');
      debugPrint('📌 [FOREGROUND FCM] Data: ${message.data}');

      // Show notification using local notifications plugin
      if (message.notification != null) {
        _displayNotification(message);
      }
    });

    // 2. Handle notification tap when app is in foreground/background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '👆 [FCM] Notification tapped (app running): ${message.messageId}',
      );
      debugPrint('📌 [FCM] Data: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // 3. Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint(
          '🔁 [FCM] App opened from terminated state by message: ${message.messageId}',
        );
        debugPrint('📌 [FCM] Data: ${message.data}');
        // Delay navigation slightly to allow app to finish init
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(message.data);
        });
      }
    });

    // 4. Handle local notification tap (when user clicks the local notification)
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('👆 [LOCAL NOTIFICATION] Tapped: ${response.payload}');
        try {
          if (response.payload != null && response.payload!.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            debugPrint('📌 [LOCAL NOTIFICATION] Decoded data: $data');
            _handleNotificationTap(data);
          }
        } catch (e) {
          debugPrint('❌ [LOCAL NOTIFICATION] Error parsing payload: $e');
        }
      },
    );

    debugPrint('✅ [FCM] Foreground message handler setup complete');
  }

  /// Handle notification tap and navigate to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    final route =
        data['route'] ??
        data['screen'] ??
        data['click_action_activity'] ??
        'notifications';

    debugPrint('🔍 [NOTIFICATION TAP] Parsed route: "$route"');

    // Map different route names to the same notifications page
    if (route.toString().toLowerCase().contains('notification') ||
        route == 'NotificationListActivity' ||
        route == 'notifications') {
      debugPrint('✅ [NAVIGATION] Navigating to NotificationsPage');
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    } else {
      debugPrint('⚠️ [NAVIGATION] Unknown route: $route');
    }
  }

  /// Display notification using flutter_local_notifications
  Future<void> _displayNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;

      // Prepare payload dengan route info agar ketika user klik, bisa di-handle dengan benar
      final payload = {
        ...message.data,
        'title': notification?.title ?? '',
        'body': notification?.body ?? '',
      };

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'buysindo_fcm_channel',
            'Buysindo Notifications',
            channelDescription: 'Notifications from Buysindo',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        platformChannelSpecifics,
        payload: jsonEncode(payload),
      );

      debugPrint(
        '✅ [Notification] Local notification displayed with route: ${message.data['route']}',
      );
    } catch (e) {
      debugPrint('❌ [Notification] Error displaying notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        return MaterialApp(
          title: appConfig.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
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
            '/register': (ctx) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
