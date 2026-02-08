import 'package:flutter/material.dart';
import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../notifications_page.dart';
import 'templates/ppob_template.dart';
import 'templates/ojek_online_template.dart';
import 'templates/toko_online_template.dart';
import 'templates/app_custom_template.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with WidgetsBindingObserver {
  Timer? _timeoutTimer;
  int _adminNotifCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAdminNotifCount();
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
    if (state == AppLifecycleState.resumed) {
      _fetchAdminNotifCount();
      _checkAppUpdate();
    }
  }

  Future<void> _checkAppUpdate() async {
    try {
      String? token = await SessionManager.getToken();
      if (token == null) return;
      final updateData = await ApiService.instance.getAppUpdate(token);
      if (updateData != null && updateData['status'] == 'success') {
        final data = updateData['data'];
        final serverVersion = data['version_code'].toString().trim();
        final packageInfo = await PackageInfo.fromPlatform();
        if (serverVersion != packageInfo.version.trim()) {
          _showUpdateDialog(
            version: serverVersion,
            url: data['download_url'],
            mandatory: data['is_mandatory'] == 1,
            notes: data['keterangan'] ?? "",
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [UpdateCheck] Error: $e');
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
      builder: (context) => PopScope(
        canPop: !mandatory,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Update Versi $version"),
          content: Text(notes),
          actions: [
            if (!mandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
            ElevatedButton(
              onPressed: () async => await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: appConfig.primaryColor,
              ),
              child: const Text(
                "Update Sekarang",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAdminNotifCount() async {
    try {
      String? token = await SessionManager.getToken();
      final count = await ApiService.instance.getAdminNotificationCount(token);
      if (mounted) setState(() => _adminNotifCount = count);
    } catch (e) {
      debugPrint('❌ Notif Count Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        final String tampilan = appConfig.tampilan.toLowerCase().trim();

        if (tampilan.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // PERBAIKAN: AppBar hanya sembunyi jika showAppbar == 0
        // Syarat "|| tampilan == 'app_custom'" dihapus
        final bool hideAppBar = appConfig.showAppbar == 0;

        Widget content;
        switch (tampilan) {
          case 'ppob':
            content = const PpobTemplate();
            break;
          case 'toko_online':
            content = const TokoOnlineTemplate();
            break;
          case 'ojek_online':
            content = const OjekOnlineTemplate();
            break;
          case 'app_custom':
            content = const AppCustomTemplate();
            break;
          default:
            content = const PpobTemplate();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: hideAppBar
              ? null
              : AppBar(
                  title: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  actions: [
                    _buildNotificationIcon(),
                    const SizedBox(width: 12),
                  ],
                ),
          body: content,
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.notifications, color: appConfig.textColor),
          ),
          if (_adminNotifCount > 0)
            Positioned(
              right: 0,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_adminNotifCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
