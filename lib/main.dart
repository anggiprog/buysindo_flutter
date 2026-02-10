import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
// Import semua template prabayar
import 'ui/home/customer/tabs/templates/prabayar/pulsa.dart';
import 'ui/home/customer/tabs/templates/prabayar/data.dart';
import 'ui/home/customer/tabs/templates/prabayar/aktivasi_perdana.dart';
import 'ui/home/customer/tabs/templates/prabayar/aktivasi_voucher.dart';
import 'ui/home/customer/tabs/templates/prabayar/e_money.dart';
import 'ui/home/customer/tabs/templates/prabayar/games.dart';
import 'ui/home/customer/tabs/templates/prabayar/gas.dart';
import 'ui/home/customer/tabs/templates/prabayar/masa_aktif.dart';
import 'ui/home/customer/tabs/templates/prabayar/pln.dart';
import 'ui/home/customer/tabs/templates/prabayar/sms.dart';
import 'ui/home/customer/tabs/templates/prabayar/streaming.dart';
import 'ui/home/customer/tabs/templates/prabayar/tv.dart';
import 'ui/home/customer/tabs/templates/prabayar/voucher.dart';

//menu menu utama
import 'ui/home/customer/tabs/account_tab.dart';
import 'ui/home/customer/tabs/transaction_history_tab.dart';
import 'ui/home/customer/notifications_page.dart';
import 'ui/home/topup_modal.dart';
import 'ui/home/tentang_kami.dart';
import 'ui/home/chat_admin.dart';
import 'ui/home/kontak_admin.dart';
import 'ui/home/customer/poin/poin.dart';
import 'ui/home/customer/tabs/akun/buat_toko.dart';
import 'ui/home/akun/ganti_password.dart';
import 'ui/home/pin.dart';
import 'ui/home/referral/referral.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'features/topup/screens/topup_history_screen.dart';
import 'features/customer/data/models/transaction_pascabayar_model.dart';
import 'features/customer/data/models/transaction_mutasi_model.dart';
import 'ui/home/customer/tabs/templates/transaction_pascabayar_detail_page.dart';
import 'ui/home/customer/tabs/templates/transaction_detail_page.dart';
import 'ui/home/customer/tabs/templates/transaction_mutasi_detail_page.dart';
import 'package:flutter/services.dart' as services;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Conditional imports for mobile-only features
import 'main_io_stub.dart' if (dart.library.io) 'main_io.dart';

// Global navigator key so we can navigate from background/message handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin instance
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Widget placeholder untuk halaman yang belum diimplementasi
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Halaman $title belum tersedia',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

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

// Helper widget to show logout confirmation dialog when /logout route is pushed
class _LogoutConfirmPage extends StatefulWidget {
  @override
  State<_LogoutConfirmPage> createState() => _LogoutConfirmPageState();
}

class _LogoutConfirmPageState extends State<_LogoutConfirmPage> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ya, Keluar'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          // Perform logout
          try {
            final token = await SessionManager.getToken();
            if (token != null) {
              final api = ApiService(Dio());
              await api.logout(token);
            }
          } catch (e) {
            debugPrint('Logout API error (ignored): $e');
          }
          await SessionManager.clearSession();
          // Navigate to login and clear stack
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } else if (mounted) {
          // User cancelled, go back
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }
}

// Helper widget to trigger TopupModal as a bottom sheet when /topup route is pushed
class _TopupModalRoutePage extends StatefulWidget {
  @override
  State<_TopupModalRoutePage> createState() => _TopupModalRoutePageState();
}

class _TopupModalRoutePageState extends State<_TopupModalRoutePage> {
  bool _modalShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modalShown) {
      _modalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TopupModal(
            primaryColor: appConfig.primaryColor,
            apiService: ApiService(Dio()),
          ),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return an empty Scaffold to avoid blank screen flash
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
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
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
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
      } else {
        debugPrint('⚠️ [FCM] Tidak ada notification payload, hanya data');
      }
    });

    // 2. Handle notification tap when app is in foreground/background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Ensure navigation occurs after frame if navigator not ready
      if (navigatorKey.currentState != null) {
        _handleNotificationTap(message.data);
      } else {
        debugPrint('⚠️ [FCM] Navigator belum ready, tunggu next frame');
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
            debugPrint('⚠️ [FCM] Navigator belum ready, coba next frame');
            // try again next frame
            WidgetsBinding.instance.addPostFrameCallback(
              (__) => _handleNotificationTap(message.data),
            );
          }
        });
      } else {
        debugPrint('🔵 [FCM] App dibuka normal (bukan dari notifikasi)');
      }
    });

    // 4. Initialize local notifications with channel configuration
    _initializeLocalNotifications();

    // 5. Set foreground notification presentation for Android 11+
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize local notifications with Android channel
  Future<void> _initializeLocalNotifications() async {
    try {
      // Create Android notification channel for proper notification delivery
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'buysindo_fcm_channel',
        'BuySindo Notifications',
        description: 'Notifikasi dari BuySindo',
        importance: Importance.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
        ledColor: Color.fromARGB(255, 255, 0, 0),
      );

      // Create the channel on Android
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Android notification channel created');

      // Initialize local notifications
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          try {
            debugPrint('📲 Local notification tapped: ${response.payload}');
            if (response.payload != null && response.payload!.isNotEmpty) {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              _handleNotificationTap(data);
            }
          } catch (e) {
            debugPrint('❌ Error handling local notification tap: $e');
          }
        },
      );

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  /// Handle notification tap and navigate to appropriate screen
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    try {
      // Extract route from data
      final route =
          data['route'] ??
          data['screen'] ??
          data['click_action_activity'] ??
          'notifications';

      debugPrint('📍 Route extracted: $route');
      debugPrint('📍 Activity: ${data['click_action_activity'] ?? "N/A"}');
      debugPrint('📍 Transaction ID: ${data['transaction_id'] ?? "N/A"}');
      debugPrint('📍 Ref ID: ${data['ref_id'] ?? "N/A"}');
      debugPrint('========================================\n');

      // Handle topup history route (HistoryTopupActivity)
      if (route == 'topup_history' || route == 'HistoryTopupActivity') {
        debugPrint('✅ Topup history route confirmed');

        try {
          if (navigatorKey.currentState != null) {
            debugPrint(
              '✅ Navigator state available - navigating to topup history',
            );
            navigatorKey.currentState!.pushNamed('/topup_history');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Direct navigation failed: $e');
        }

        // Fallback: Wait for navigator to be ready
        debugPrint('⚠️ Using fallback navigation method for topup history');
        int retries = 0;
        while (retries < 50 && navigatorKey.currentState == null) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (navigatorKey.currentState != null) {
          try {
            debugPrint(
              '✅ Navigator ready after ${retries * 100}ms - navigating to topup history',
            );
            navigatorKey.currentState!.pushNamed('/topup_history');
          } catch (e) {
            debugPrint('❌ Navigation failed even after waiting: $e');
          }
        }
        return;
      }

      // Handle transaction history route (for other transaction types)
      if (route.toString().toLowerCase().contains('transaction') ||
          route == 'transaction_history' ||
          route == 'RiwayatPrabayarActivity') {
        debugPrint('✅ Transaction history route confirmed');

        // Extract tab index if provided
        final tabIndex =
            int.tryParse(data['tab_index']?.toString() ?? '1') ?? 1;
        debugPrint('📲 Main tab index: $tabIndex');

        try {
          if (navigatorKey.currentState != null) {
            debugPrint(
              '✅ Navigator state available - navigating to home with transaction tab',
            );
            // Navigate to home with transaction history tab selected
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {
                'initialTab': tabIndex,
              }, // Pass tab index to home screen
            );
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Direct navigation failed: $e');
        }

        // Fallback: Wait for navigator to be ready
        debugPrint(
          '⚠️ Using fallback navigation method for transaction history',
        );
        int retries = 0;
        while (retries < 50 && navigatorKey.currentState == null) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (navigatorKey.currentState != null) {
          try {
            debugPrint(
              '✅ Navigator ready after ${retries * 100}ms - navigating to transaction history',
            );
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {'initialTab': tabIndex},
            );
          } catch (e) {
            debugPrint('❌ Navigation failed even after waiting: $e');
          }
        }
        return;
      }

      // Handle pascabayar detail route
      if (route == 'pascabayar_detail') {
        debugPrint('\n========================================');
        debugPrint('✅ [Routing] PASCABAYAR DETAIL ROUTE');
        debugPrint('========================================');

        // Extract transaction data from notification
        final transactionId =
            int.tryParse(data['transaction_id']?.toString() ?? '0') ?? 0;
        final refId = data['ref_id']?.toString() ?? '';
        final brand = data['brand']?.toString() ?? '';
        final customerNo = data['customer_no']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        if (transactionId > 0) {
          // Wait for navigator to be ready
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            try {
              debugPrint(
                '✅ [Pascabayar] Navigator ready - fetching transaction data...',
              );

              // Fetch full transaction data from API
              final token = await SessionManager.getToken();
              debugPrint(
                '🔑 [Pascabayar] Token: ${token != null ? "Available" : "NULL"}',
              );

              if (token != null) {
                debugPrint(
                  '🌐 [Pascabayar] Calling API getTransactionDetailPascabayar...',
                );
                final apiService = ApiService(Dio());
                final response = await apiService
                    .getTransactionDetailPascabayar(token);

                if (response.statusCode == 200 && response.data != null) {
                  final transactions = TransactionPascabayarResponse.fromJson(
                    response.data,
                  );

                  debugPrint(
                    '📋 [Pascabayar] Total transaksi: ${transactions.data.length}',
                  );
                  debugPrint(
                    '🔍 [Pascabayar] Mencari transaction dengan ID=$transactionId atau RefID=$refId',
                  );

                  // Find transaction by ID or ref_id
                  final transaction = transactions.data.firstWhere(
                    (t) => t.id == transactionId || t.refId == refId,
                    orElse: () => throw Exception('Transaction not found'),
                  );

                  navigatorKey.currentState!.push(
                    MaterialPageRoute(
                      builder: (context) => TransactionPascabayarDetailPage(
                        transaction: transaction,
                      ),
                    ),
                  );
                  return;
                }
              }

              debugPrint(
                '\n⚠️ [Pascabayar] Failed to fetch transaction - navigating to history tab',
              );
              debugPrint(
                '🛣️ [Pascabayar] Akan redirect ke tab Pascabayar (index 2)\n',
              );
              // Fallback: Navigate to pascabayar history tab
              navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {'initialTab': 2}, // Pascabayar tab
              );
            } catch (e) {
              debugPrint('❌ [Pascabayar] Error loading transaction detail:');
              debugPrint('   Error: $e');
              debugPrint('   Fallback: Navigating to history tab (index 2)');
              // Fallback to history tab on error
              navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {'initialTab': 2},
              );
            }
          }
        } else {
          debugPrint('⚠️ No transaction ID - navigating to history tab');
          // Navigate to pascabayar history tab as fallback
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {'initialTab': 2},
            );
          }
        }
        return;
      }

      // Handle mutasi detail route
      if (route == 'mutasi_detail' || route == 'MutasiDetailActivity') {
        debugPrint('\n========================================');
        debugPrint('✅ [Routing] MUTASI DETAIL ROUTE');
        debugPrint('========================================');

        // Extract transaction data from notification
        final trxId = data['trx_id']?.toString() ?? '';
        final type = data['type']?.toString() ?? '';
        final amount = int.tryParse(data['amount']?.toString() ?? '0') ?? 0;
        final saldoAwal =
            int.tryParse(data['saldo_awal']?.toString() ?? '0') ?? 0;
        final saldoAkhir =
            int.tryParse(data['saldo_akhir']?.toString() ?? '0') ?? 0;
        final keterangan = data['keterangan']?.toString() ?? '';

        debugPrint('📦 [Mutasi] Transaction Data:');
        debugPrint('   - Trx ID: $trxId');
        debugPrint('   - Type: $type');
        debugPrint('   - Amount: $amount');
        debugPrint('   - Saldo Awal: $saldoAwal');
        debugPrint('   - Saldo Akhir: $saldoAkhir');
        debugPrint('   - Keterangan: $keterangan');
        debugPrint('========================================\n');

        if (trxId.isNotEmpty) {
          // Wait for navigator to be ready
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            try {
              debugPrint(
                '✅ [Mutasi] Navigator ready - fetching transaction data...',
              );

              // Fetch full transaction data from API
              final token = await SessionManager.getToken();
              debugPrint(
                '🔑 [Mutasi] Token: ${token != null ? "Available" : "NULL"}',
              );

              if (token != null) {
                debugPrint('🌐 [Mutasi] Calling API getLogTransaksiMutasi...');
                final apiService = ApiService(Dio());
                final response = await apiService.getLogTransaksiMutasi(token);

                debugPrint('📥 [Mutasi] API Response:');
                debugPrint('   - Status Code: ${response.statusCode}');
                debugPrint('   - Has Data: ${response.data != null}');

                if (response.statusCode == 200 && response.data != null) {
                  final responseData = response.data;
                  final isSuccess =
                      responseData['status'] == true ||
                      responseData['status'] == 'success';
                  final transactionList = responseData['data'] as List?;

                  debugPrint(
                    '📋 [Mutasi] Total transaksi: ${transactionList?.length ?? 0}',
                  );

                  if (isSuccess &&
                      transactionList != null &&
                      transactionList.isNotEmpty) {
                    // Find transaction by trx_id
                    final transactionData = transactionList.firstWhere(
                      (t) => t['trx_id']?.toString() == trxId,
                      orElse: () => transactionList.first,
                    );

                    // Parse to TransactionMutasi model
                    final transaction = TransactionMutasi.fromJson(
                      transactionData,
                    );

                    navigatorKey.currentState!.push(
                      MaterialPageRoute(
                        builder: (context) => TransactionMutasiDetailPage(
                          transaction: transaction,
                        ),
                      ),
                    );
                    return;
                  }
                }
              }

              debugPrint(
                '\n⚠️ [Mutasi] Failed to fetch transaction - navigating to history tab',
              );
              debugPrint(
                '🛣️ [Mutasi] Akan redirect ke tab Mutasi (index 3)\n',
              );
              // Fallback: Navigate to mutasi history tab
              navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {'initialTab': 3}, // Mutasi tab
              );
            } catch (e) {
              debugPrint('❌ [Mutasi] Error loading transaction detail:');
              debugPrint('   Error: $e');
              debugPrint('   Fallback: Navigating to history tab (index 3)');
              // Fallback to history tab on error
              navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {'initialTab': 3},
              );
            }
          }
        } else {
          debugPrint('⚠️ No trx_id - navigating to history tab');
          // Navigate to mutasi history tab as fallback
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {'initialTab': 3},
            );
          }
        }
        return;
      }

      // Handle prabayar detail route
      if (route == 'prabayar_detail') {
        debugPrint('\n========================================');
        debugPrint('✅ [Routing] PRABAYAR DETAIL ROUTE');
        debugPrint('========================================');

        // Extract transaction data from notification
        final transactionId = data['transaction_id']?.toString() ?? '';
        final refId = data['ref_id']?.toString() ?? '';
        final trxId = data['trx_id']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        debugPrint('📦 [Prabayar] Transaction Data:');
        debugPrint('   - Transaction ID: $transactionId');
        debugPrint('   - Ref ID: $refId');
        debugPrint('   - Trx ID: $trxId');
        debugPrint('   - Status: $status');
        debugPrint('========================================\n');

        if (refId.isNotEmpty && transactionId.isNotEmpty) {
          // Wait for navigator to be ready
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            try {
              debugPrint(
                '✅ [Prabayar] Navigator ready - navigating to detail page...',
              );
              debugPrint(
                '🛣️ [Prabayar] Opening TransactionDetailPage with refId=$refId, transactionId=$transactionId',
              );

              navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (context) => TransactionDetailPage(
                    refId: refId,
                    transactionId: transactionId,
                  ),
                ),
              );
              return;
            } catch (e) {
              debugPrint('❌ [Prabayar] Error navigating to detail page:');
              debugPrint('   Error: $e');
              debugPrint('   Fallback: Navigating to history tab (index 1)');
              // Fallback to history tab on error
              navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {'initialTab': 1},
              );
            }
          }
        } else {
          debugPrint(
            '⚠️ [Prabayar] No ref_id or transaction_id - navigating to history tab',
          );
          // Navigate to prabayar history tab as fallback
          int retries = 0;
          while (retries < 50 && navigatorKey.currentState == null) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }

          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {'initialTab': 1},
            );
          }
        }
        return;
      }

      // Check if it's a notification route
      if (route.toString().toLowerCase().contains('notification') ||
          route == 'NotificationListActivity' ||
          route == 'notifications') {
        debugPrint('✅ Notification route confirmed');

        // Simple direct navigation - don't create page in builder
        // Just push to existing route
        try {
          if (navigatorKey.currentState != null) {
            debugPrint('✅ Navigator state available - pushing route');
            navigatorKey.currentState!.pushNamed('/notifications');
            return;
          } else {
            debugPrint('⚠️ Navigator state is null, queueing navigation');
          }
        } catch (e) {
          debugPrint('⚠️ Named route push failed: $e');
        }

        // Fallback: Wait for navigator to be ready then navigate
        debugPrint('⚠️ Using fallback navigation method');
        int retries = 0;
        while (retries < 50 && navigatorKey.currentState == null) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (navigatorKey.currentState != null) {
          try {
            debugPrint(
              '✅ Navigator ready after ${retries * 100}ms - navigating',
            );
            navigatorKey.currentState!.pushNamed('/notifications');
          } catch (e) {
            debugPrint('❌ Navigation failed even after waiting: $e');
          }
        } else {
          debugPrint('❌ Navigator still not ready after 5 seconds');
        }
      }
    } catch (e) {
      debugPrint(
        '❌ Error in _handleNotificationTap: $e\n${StackTrace.current}',
      );
    }
  }

  // Cache path for the large icon file so we don't write it every time
  String? _cachedLargeIconPath;

  /// Ensure asset image is written to a file and return the file path
  /// Returns null on Web platform since local files aren't supported
  Future<String?> _ensureLargeIconFile() async {
    // Skip file operations on Web platform
    if (kIsWeb) return null;

    try {
      if (_cachedLargeIconPath != null) {
        final exists = await MainIoHelper.fileExists(_cachedLargeIconPath!);
        if (exists) return _cachedLargeIconPath;
      }

      // Load asset bytes (use prefixed rootBundle to avoid collisions)
      final byteData = await services.rootBundle.load('assets/images/logo.png');
      final bytes = byteData.buffer.asUint8List();

      _cachedLargeIconPath = await MainIoHelper.writeNotificationIcon(bytes);
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
            // AppBar theme - NORMAL, tidak disembunyikan
            appBarTheme: AppBarTheme(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: appConfig.textColor,
              elevation: 1,
              toolbarHeight: kToolbarHeight,
              shadowColor: Colors.black.withOpacity(0.2),
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appConfig.textColor,
              ),
              iconTheme: IconThemeData(color: appConfig.textColor, size: 24),
              actionsIconTheme: IconThemeData(
                color: appConfig.textColor,
                size: 24,
              ),
              // Use prefixed SystemUiOverlayStyle to avoid collision with other symbols
              systemOverlayStyle: services.SystemUiOverlayStyle(
                statusBarColor: appConfig.primaryColor,
                statusBarBrightness:
                    appConfig.primaryColor.computeLuminance() > 0.5
                    ? Brightness.light
                    : Brightness.dark,
                statusBarIconBrightness:
                    appConfig.primaryColor.computeLuminance() > 0.5
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/register':
                return MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                );
              case '/notifications':
                return MaterialPageRoute(
                  builder: (_) => const NotificationsPage(),
                );
              case '/topup_history':
                return MaterialPageRoute(
                  builder: (_) => const TopupHistoryScreen(),
                );
              case '/home':
                final args = settings.arguments as Map<String, dynamic>?;
                final initialTab = args?['initialTab'] as int?;
                return MaterialPageRoute(
                  builder: (_) => HomeScreen(initialTab: initialTab),
                );
              case '/info':
                return MaterialPageRoute(
                  builder: (_) => const NotificationsPage(),
                );
              case '/transaksi':
                return MaterialPageRoute(
                  builder: (_) => const TransactionHistoryTab(),
                );
              case '/chat':
                // Ganti dengan halaman chat asli jika ada
                return MaterialPageRoute(builder: (_) => const ChatPage());
              case '/akun':
                return MaterialPageRoute(builder: (_) => const AccountTab());
              case '/cs':
                // Ganti dengan halaman CS asli jika ada
                return MaterialPageRoute(
                  builder: (_) => const KontakAdminPage(),
                );
              case '/referral':
                // Ganti dengan halaman referral asli jika ada
                return MaterialPageRoute(builder: (_) => const ReferralPage());
              case '/topup':
                // Show TopupModal as a bottom sheet dialog from route
                return MaterialPageRoute(
                  builder: (context) => _TopupModalRoutePage(),
                );

              case '/histori_topup':
                return MaterialPageRoute(
                  builder: (_) => const TopupHistoryScreen(),
                );
              case '/poin':
                // Ganti dengan halaman Poin asli jika ada
                return MaterialPageRoute(builder: (_) => const PoinPage());
              case '/privacy_policy':
                // Open privacy policy in external browser with agicell subdomain from appConfig
                return MaterialPageRoute(
                  builder: (context) {
                    final subdomain = appConfig.subdomain ?? 'agicell';
                    final url =
                        'https://buysindo.com/privacy-policy/$subdomain';
                    Future.microtask(() async {
                      await launchUrlString(url, webOnlyWindowName: '_blank');
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                    // Show a placeholder while launching browser
                    return const Scaffold(
                      body: Center(child: Text('Membuka Privacy Policy...')),
                    );
                  },
                );
              case '/toko':
                // Ganti dengan halaman Toko asli jika ada
                return MaterialPageRoute(builder: (_) => const BuatTokoPage());
              case '/password':
                // Ganti dengan halaman Password asli jika ada
                return MaterialPageRoute(
                  builder: (_) => const GantiPasswordPage(),
                );
              case '/pin':
                // Ganti dengan halaman PIN asli jika ada
                return MaterialPageRoute(builder: (_) => const PinPage());
              case '/tentang_kami':
                // Ganti dengan halaman Tentang Kami asli jika ada
                return MaterialPageRoute(
                  builder: (_) => const TentangKamiPage(),
                );
              case '/logout':
                // Show logout confirmation dialog
                return MaterialPageRoute(builder: (_) => _LogoutConfirmPage());

              // Prabayar routes
              case '/prabayar/pulsa':
                return MaterialPageRoute(builder: (_) => const PulsaPage());
              case '/prabayar/data':
                return MaterialPageRoute(builder: (_) => const DataPage());
              case '/prabayar/aktivasi_perdana':
                return MaterialPageRoute(
                  builder: (_) => const AktivasiPerdanaPage(),
                );
              case '/prabayar/aktivasi_voucher':
                return MaterialPageRoute(
                  builder: (_) => const AktivasiVoucherPage(),
                );
              case '/prabayar/gas':
                return MaterialPageRoute(builder: (_) => const GasPage());
              case '/prabayar/e_money':
                return MaterialPageRoute(builder: (_) => const EMoneyPage());
              case '/prabayar/games':
                return MaterialPageRoute(builder: (_) => const GamesPage());
              case '/prabayar/sms':
                return MaterialPageRoute(builder: (_) => const SmsPage());
              case '/prabayar/streaming':
                return MaterialPageRoute(builder: (_) => const StreamingPage());
              case '/prabayar/voucher':
                return MaterialPageRoute(builder: (_) => const VoucherPage());
              case '/prabayar/tv':
                return MaterialPageRoute(builder: (_) => const TVPage());
              case '/prabayar/masa_aktif':
                return MaterialPageRoute(builder: (_) => const MasaAktifPage());
              case '/prabayar/pln':
                return MaterialPageRoute(builder: (_) => const PLNPage());

              default:
                // Handle dinamis prabayar/pascabayar
                if (settings.name != null &&
                    settings.name!.startsWith('/prabayar/')) {
                  final slug = settings.name!.substring('/prabayar/'.length);
                  // TODO: mapping ke halaman prabayar dinamis jika ada
                  return MaterialPageRoute(
                    builder: (_) => PlaceholderWidget('Prabayar: $slug'),
                  );
                }
                if (settings.name != null &&
                    settings.name!.startsWith('/pascabayar/')) {
                  final slug = settings.name!.substring('/pascabayar/'.length);
                  // TODO: mapping ke halaman pascabayar dinamis jika ada
                  return MaterialPageRoute(
                    builder: (_) => PlaceholderWidget('Pascabayar: $slug'),
                  );
                }
                return null;
            }
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
