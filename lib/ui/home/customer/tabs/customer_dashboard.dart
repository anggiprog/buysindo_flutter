import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/app_config.dart';
// Import template-template spesifik
import 'templates/ppob_template.dart';
import 'templates/ojek_online_template.dart';
import 'templates/toko_online_template.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Set timeout untuk loading screen - max 10 detik
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      debugPrint('⏱️ Loading timeout! Showing default template (ppob)');
      if (mounted) {
        setState(() {}); // Force rebuild
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
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
        switch (tampilan.toLowerCase().trim()) {
          case 'ppob':
            debugPrint('✅ Navigasi ke: PpobTemplate');
            return const PpobTemplate();

          case 'toko_online':
            debugPrint('✅ Navigasi ke: TokoOnlineTemplate');
            return const TokoOnlineTemplate();

          case 'ojek_online':
            debugPrint('✅ Navigasi ke: OjekOnlineTemplate');
            return const OjekOnlineTemplate();

          default:
            debugPrint(
              '⚠️ Template "$tampilan" tidak dikenali, default ke: PpobTemplate',
            );
            return const PpobTemplate();
        }
      },
    );
  }
}
