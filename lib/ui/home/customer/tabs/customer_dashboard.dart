import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../notifications_page.dart';
// Import template-template spesifik
import 'templates/ppob_template.dart';
import 'templates/ojek_online_template.dart';
import 'templates/toko_online_template.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with WidgetsBindingObserver {
  Timer? _timeoutTimer;
  int _adminNotifCount = 0;
  bool _isLoadingNotif = true;

  final ApiService _apiService = ApiService(Dio());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set timeout untuk loading screen - max 10 detik
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      debugPrint('⏱️ Loading timeout! Showing default template (ppob)');
      if (mounted) {
        setState(() {}); // Force rebuild
      }
    });

    // Initial fetch for admin notification count
    _fetchAdminNotifCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh notification count when returning to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchAdminNotifCount();
    }
  }

  Future<void> _fetchAdminNotifCount() async {
    try {
      String? token = await SessionManager.getToken();
      final count = await _apiService.getAdminNotificationCount(token);
      if (!mounted) return;
      setState(() {
        _adminNotifCount = count;
        _isLoadingNotif = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch admin notif count: $e');
      if (!mounted) return;
      setState(() {
        _adminNotifCount = 0;
        _isLoadingNotif = false;
      });
    }
  }

  Widget _buildTopNav() {
    final Color bg = appConfig.primaryColor;
    final Color textColor = appConfig.textColor;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              height: 40,
              width: 40,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            // App name
            Expanded(
              child: Text(
                appConfig.appName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Notification icon with badge
            GestureDetector(
              onTap: () async {
                // Navigate to notifications page via named route to ensure MaterialApp routing
                try {
                  Navigator.of(context).pushNamed('/notifications');
                } catch (e) {
                  // Fallback to direct push if named route not available
                  try {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  } catch (e2) {
                    debugPrint('❌ Navigation to NotificationsPage failed: $e / $e2');
                  }
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.notifications, color: textColor),
                  ),
                  if (_adminNotifCount > 0)
                    Positioned(
                      right: 0,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            _adminNotifCount > 99 ? '99+' : '$_adminNotifCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        final String tampilan = appConfig.tampilan;

        debugPrint(
          '🔍 CustomerDashboard.build - tampilan: "$tampilan" (isEmpty: ${tampilan.isEmpty})',
        );

        // 1. Logika Loading: Jika data API belum masuk (masih kosong) - tapi max 10 detik
        if (tampilan.isEmpty) {
          debugPrint(
            '⏳ STATUS: Loading - Template masih kosong, menunggu API...',
          );
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Memuat konfigurasi..."),
                SizedBox(height: 5),
                Text(
                  "(Max 10 detik, akan default ke PPOB)",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Cancel timeout jika tampilan sudah ada
        if (_timeoutTimer?.isActive ?? false) {
          _timeoutTimer?.cancel();
          debugPrint('✅ Loading complete, tampilan diterima: "$tampilan"');
        }

        // 2. Logika Pengalihan Halaman berdasarkan Template
        debugPrint('🔄 SWITCH TEMPLATE - Mencari template: "$tampilan"');
        Widget content;
        switch (tampilan.toLowerCase().trim()) {
          case 'ppob':
            debugPrint('✅ Navigasi ke: PpobTemplate');
            content = const PpobTemplate();
            break;

          case 'toko_online':
            debugPrint('✅ Navigasi ke: TokoOnlineTemplate');
            content = const TokoOnlineTemplate();
            break;

          case 'ojek_online':
            debugPrint('✅ Navigasi ke: OjekOnlineTemplate');
            content = const OjekOnlineTemplate();
            break;

          default:
            debugPrint(
              '⚠️ Template "$tampilan" tidak dikenali, default ke: PpobTemplate',
            );
            content = const PpobTemplate();
        }

        // Wrap template with top navbar
        return Column(
          children: [
            _buildTopNav(),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
