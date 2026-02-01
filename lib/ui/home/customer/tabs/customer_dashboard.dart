import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _CustomerDashboardState extends State<CustomerDashboard>
    with WidgetsBindingObserver {
  Timer? _timeoutTimer;
  int _adminNotifCount = 0;

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
    // Cek update aplikasi
    _checkAppUpdate();
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
      _checkAppUpdate();
    }
  }

  Future<void> _checkAppUpdate() async {
    try {
      String? token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return;

      final updateData = await ApiService.instance.getAppUpdate(token);
      if (updateData != null && updateData['status'] == 'success') {
        final data = updateData['data'];
        final serverVersion = data['version_code'].toString().trim();
        final downloadUrl = data['download_url'];
        final isMandatory = data['is_mandatory'] == 1;
        final keterangan =
            data['keterangan'] ?? "Pembaruan versi baru telah tersedia.";

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version.trim();

        debugPrint(
          '🔍 [UpdateCheck] Server: $serverVersion, Device: $currentVersion',
        );

        if (serverVersion != currentVersion) {
          if (!mounted) return;
          _showUpdateDialog(
            version: serverVersion,
            url: downloadUrl,
            mandatory: isMandatory,
            notes: keterangan,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [UpdateCheck] Gagal: $e');
    }
  }

  void _showUpdateDialog({
    required String version,
    required String url,
    required bool mandatory,
    required String notes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !mandatory,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !mandatory,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text("Update Versi $version"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Versi terbaru telah tersedia!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(notes),
                if (mandatory)
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Text(
                      "* Update ini wajib dilakukan untuk tetap menggunakan aplikasi.",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (!mandatory)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appConfig.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Update Sekarang",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchAdminNotifCount() async {
    try {
      String? token = await SessionManager.getToken();
      final count = await _apiService.getAdminNotificationCount(token);
      if (!mounted) return;
      setState(() {
        _adminNotifCount = count;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch admin notif count: $e');
      if (!mounted) return;
      setState(() {
        _adminNotifCount = 0;
      });
    }
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

        // Wrap template dengan Scaffold dan AppBar
        return Scaffold(
          backgroundColor: appConfig.primaryColor,
          appBar: AppBar(
            title: Row(
              children: [
                // Logo - Circular
                ClipOval(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // App name
                Text(
                  appConfig.appName,
                  style: TextStyle(
                    color: appConfig.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            backgroundColor: appConfig.primaryColor,
            elevation: 1,
            centerTitle: false,
            leading: null,
            leadingWidth: 0,
            actions: [
              GestureDetector(
                onTap: () {
                  try {
                    Navigator.of(context).pushNamed('/notifications');
                  } catch (e) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.notifications,
                        color: appConfig.textColor,
                      ),
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
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              _adminNotifCount > 99
                                  ? '99+'
                                  : '$_adminNotifCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Container(color: Colors.white, child: content),
        );
      },
    );
  }
}
