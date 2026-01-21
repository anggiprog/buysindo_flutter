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
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

// Global navigator key so we can navigate from background/message handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin instance
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  final mainStartTime = DateTime.now();

  // 1. Ensure binding is initialized (FAST - ~1ms)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables ASYNC in background
  _loadEnvAsync();

  // 3. Preserve native splash screen sampai Flutter UI siap (FAST - ~5ms)
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  // 4. Load cached config dari SharedPreferences (FAST - dari local storage ~50-100ms)
  await appConfig.loadLocalConfig();

  // 5. Start Firebase initialization in background (non-blocking)
  _initializeFirebaseAsync();

  // 6. Start API initialization in background - TANPA AWAIT
  _fetchConfigAsync();

  runApp(const MyApp());
}

/// Load .env file in background (non-blocking)
Future<void> _loadEnvAsync() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Handle error silently
  }
}

/// Initialize Firebase in background (non-blocking)
Future<void> _initializeFirebaseAsync() async {
  try {
    final firebaseStart = DateTime.now();

    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Setup notification channels for Android
    await _initializeNotificationChannels();

    // 3. Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Request notification permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      provisional: false,
      sound: true,
    );

    // 5. Get initial FCM token
    try {
      final token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // Handle error silently
    }

    // 6. Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Handle token refresh
    });
  } catch (e) {
    // Handle error silently
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

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Callback when user taps on a displayed local notification
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        try {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(payload);
            final route =
                data['route'] ??
                data['screen'] ??
                data['click_action_activity'];
            if (route == 'notifications' ||
                route == 'NotificationListActivity') {
              // Use navigatorKey to navigate to NotificationsPage; schedule if navigator not ready
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState?.pushNamed('/notifications');
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  navigatorKey.currentState?.pushNamed('/notifications');
                });
              }
            }
          }
        } catch (e) {
          // Handle error silently
        }
      },
      // For older versions of the plugin, provide onSelectNotification fallback
      onDidReceiveBackgroundNotificationResponse: null,
    );

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
  } catch (e) {
    // Silently handle notification channel creation errors
  }
}

/// Initialize Firebase & API config in background tanpa blocking UI
Future<void> _fetchConfigAsync() async {
  try {
    final dio = Dio();
    final apiService = ApiService(dio);
    await appConfig.initializeApp(apiService);
  } catch (e) {
    // Handle error silently
  }
}

/// Background message handler for Firebase Cloud Messaging
/// This runs when app is in background or terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message

  // Anda bisa add custom logic di sini untuk handle background notifications
  // Misalnya: simpan ke local storage, trigger background fetch, dll
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundMessageHandler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning to foreground, re-check initial message as a fallback
    if (state == AppLifecycleState.resumed) {
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
            if (message != null && message.data.isNotEmpty) {
              // Schedule navigation after frame to ensure navigator is ready
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleNotificationTap(message.data);
              });
            }
          })
          .catchError((e) {
            // Handle error silently
          });
    }
  }

  /// Setup foreground message handler
  /// This runs when app is in foreground
  void _setupForegroundMessageHandler() {
    // 1. Handle message received when app in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show notification using local notifications plugin
      if (message.notification != null) {
        _displayNotification(message);
      }
    });

    // 2. Handle notification tap when app is in foreground/background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Ensure navigation occurs after frame if navigator not ready
      if (navigatorKey.currentState != null) {
        _handleNotificationTap(message.data);
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNotificationTap(message.data),
        );
      }
    });

    // 3. Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        // Delay navigation slightly to allow app to finish init
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentState != null) {
            _handleNotificationTap(message.data);
          } else {
            // try again next frame
            WidgetsBinding.instance.addPostFrameCallback(
              (__) => _handleNotificationTap(message.data),
            );
          }
        });
      }
    });

    // 4. Handle local notification tap (when user clicks the local notification)
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        try {
          if (response.payload != null && response.payload!.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          }
        } catch (e) {
          // Handle error silently
        }
      },
    );
  }

  /// Safe navigation helper that retries until navigatorKey.currentState is available
  Future<void> _safeNavigate(String routeName) async {
    // Try immediate
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamed(routeName);
      return;
    }

    // Retry for a short period until navigator is ready
    final end = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(end)) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamed(routeName);
        return;
      }
    }
  }

  /// Handle notification tap and navigate to appropriate screen
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final route =
        data['route'] ??
        data['screen'] ??
        data['click_action_activity'] ??
        'notifications';

    // Map different route names to the same notifications page
    if (route.toString().toLowerCase().contains('notification') ||
        route == 'NotificationListActivity' ||
        route == 'notifications') {
      await _safeNavigate('/notifications');
    }
  }

  // Cache path for the large icon file so we don't write it every time
  String? _cachedLargeIconPath;

  /// Ensure asset image is written to a file and return the file path
  Future<String?> _ensureLargeIconFile() async {
    try {
      if (_cachedLargeIconPath != null) {
        final f = File(_cachedLargeIconPath!);
        if (await f.exists()) return _cachedLargeIconPath;
      }

      // Load asset bytes
      final byteData = await rootBundle.load('assets/images/logo.png');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notif_large_icon.png');
      await file.writeAsBytes(bytes, flush: true);
      _cachedLargeIconPath = file.path;
      return _cachedLargeIconPath;
    } catch (e) {
      return null;
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

      // Try to include the app logo as largeIcon on Android (cached file path)
      final largeIconPath = await _ensureLargeIconFile();

      // Create AndroidNotificationDetails dynamically so we can include FilePathAndroidBitmap
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          largeIconPath != null
          ? AndroidNotificationDetails(
              'buysindo_fcm_channel',
              'Buysindo Notifications',
              channelDescription: 'Notifications from Buysindo',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              largeIcon: FilePathAndroidBitmap(largeIconPath),
            )
          : AndroidNotificationDetails(
              'buysindo_fcm_channel',
              'Buysindo Notifications',
              channelDescription: 'Notifications from Buysindo',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        platformChannelSpecifics,
        payload: jsonEncode(payload),
      );
    } catch (e) {
      // Handle error silently
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
            '/notifications': (ctx) => const NotificationsPage(),
            '/home': (context) => const HomeScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
