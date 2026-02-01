import 'package:flutter/material.dart';
import '../../core/app_config.dart';
import '../../core/network/api_service.dart';
import '../../core/network/session_manager.dart';
import 'customer/home_customer_widget.dart';
import 'driver/home_driver_widget.dart';
import 'mitra/home_mitra_widget.dart';
import 'paket_habis.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTab;
  final int? subTabIndex;

  const HomeScreen({super.key, this.initialTab, this.subTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkPackageStatus();
  }

  Future<void> _checkPackageStatus() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return;

      final paketData = await ApiService.instance.getPaket(token);
      if (paketData != null && paketData['status'] == 'success') {
        final data = paketData['data'];
        if (data != null && data['status'] == 'expired') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaketHabisPage(
                  packageName: data['chosen_package'] ?? 'Business',
                  endDate: data['package_end_date'] ?? '-',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[HomeScreen] Gagal cek paket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract subTabIndex from route arguments if available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final effectiveSubTabIndex = args?['subTabIndex'] ?? widget.subTabIndex;

    // Kita gunakan AnimatedBuilder agar jika ada update config di tengah jalan,
    // UI langsung berubah tanpa restart.
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        final type = appConfig.appType.toLowerCase();

        // Kondisi Render berdasarkan APP_TYPE dari API
        switch (type) {
          case 'driver':
            return const HomeDriverWidget();
          case 'mitra':
            return const HomeMitraWidget();
          case 'app':
          default:
            return HomeCustomerScreen(
              initialTab: widget.initialTab,
              subTabIndex: effectiveSubTabIndex,
            );
        }
      },
    );
  }
}
