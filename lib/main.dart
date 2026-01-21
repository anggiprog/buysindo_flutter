import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/network/api_service.dart';
import 'core/network/session_manager.dart';
import 'core/app_config.dart';
import 'ui/splash_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/home/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'ui/home/customer/notifications_page.dart';
import 'dart:io';
import 'package:flutter/services.dart' as services;
import 'package:path_provider/path_provider.dart';

// Global navigator key so we can navigate from background/message handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin instance
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // Ensure Flutter bindings are initialized for native calls and plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables if used by DefaultFirebaseOptions
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // ignore - .env may not exist in all environments (CI/tests)
  }

  // Initialize Firebase synchronously so any Firebase API usage after this
  // point (including in tests) has a default app available.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register background message handler and request permission for messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  } catch (e) {
    // Log the error but allow the app to continue. Tests or environments without
    // Firebase credentials will still be able to run UI logic that doesn't
    // require Firebase.
    debugPrint('Firebase initialization error: $e');
  }

  // 4. Load cached config dari SharedPreferences (FAST - dari local storage ~50-100ms)
  await appConfig.loadLocalConfig();

  // 5. Start API initialization in background - TANPA AWAIT
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
    // 1. Initialize Firebase with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Firebase init timeout'),
    );

    // 2. Setup notification channels for Android with timeout
    await _initializeNotificationChannels().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Notification channels timeout'),
    );

    // 3. Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Request notification permission with timeout
    await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          provisional: false,
          sound: true,
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Permission request timeout'),
        );

    // 5. Get initial FCM token with timeout
    try {
      await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('FCM token timeout'),
      );
    } catch (e) {
      // Token fetch failed, continue anyway
    }

    // 6. Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Handle token refresh
    });
  } catch (e) {
    // Firebase init failed but app should still work
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
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    final apiService = ApiService(dio);
    await appConfig
        .initializeApp(apiService)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('API config timeout'),
        );
  } catch (e) {
    // API config failed, app will use cached config
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
    // After first frame, verify device token match and logout if mismatch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceTokenMismatch();
    });
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
      // Also check device token mismatch whenever the app resumes
      _checkDeviceTokenMismatch();
    }
  }

  /// Check whether the saved auth token is still valid on the backend.
  /// If invalid, clear local session and force navigation to /login.
  Future<void> _checkDeviceTokenMismatch() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return;
      final api = ApiService(Dio());
      final valid = await api.isAuthTokenValid(token);
      if (!valid) {
        debugPrint('⚠️ Auth token is invalid or expired. Forcing logout.');
        // Try to call logout endpoint (best-effort) but don't block on it
        try {
          await api.logout(token);
        } catch (e) {
          debugPrint('⚠️ Logout endpoint call failed (ignored): $e');
        }
        await SessionManager.clearSession();
        // Navigate to login clearing navigation stack
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error while validating auth token: $e');
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
    try {
      final route =
          data['route'] ?? data['screen'] ?? data['click_action_activity'] ?? 'notifications';

      // Normalize route names
      final routeName = route.toString();

      if (routeName.toLowerCase().contains('notification') ||
          routeName == 'NotificationListActivity' ||
          routeName == 'notifications') {
        // Try named navigation first, with a timeout-safe helper
        try {
          await _safeNavigate('/notifications');
          return;
        } catch (e) {
          debugPrint('⚠️ _safeNavigate failed: $e -- falling back to direct push');
        }

        // Fallback: push MaterialPageRoute directly to avoid any route table issues
        try {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
              } catch (e) {
                debugPrint('❌ Fallback navigation failed: $e');
              }
            });
          }
        } catch (e) {
          debugPrint('❌ Error while navigating to NotificationsPage: $e');
        }
      }
    } catch (e) {
      // Catch any error to prevent crash on notification tap
      debugPrint('❌ Unexpected error in _handleNotificationTap: $e');
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

      // Load asset bytes (use prefixed rootBundle to avoid collisions)
      final byteData = await services.rootBundle.load('assets/images/logo.png');
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
            // Make the default AppBar visually removed across the app
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: appConfig.textColor,
              elevation: 0,
              toolbarHeight: 0,
              shadowColor: Colors.transparent,
              // Make title text take no space
              titleTextStyle: const TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
              toolbarTextStyle: const TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
              iconTheme: const IconThemeData(color: Colors.transparent, size: 0),
              actionsIconTheme: const IconThemeData(color: Colors.transparent, size: 0),
              // Use prefixed SystemUiOverlayStyle to avoid collision with other symbols
              systemOverlayStyle: services.SystemUiOverlayStyle.dark,
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
