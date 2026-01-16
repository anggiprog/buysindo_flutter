import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';
// Import template-template spesifik
import 'templates/ppob_template.dart';
import 'templates/ojek_online_template.dart';
import 'templates/toko_online_template.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, child) {
        final String template = appConfig.template;

        // 1. Logika Loading: Jika data API belum masuk (masih kosong)
        if (template.isEmpty) {
          // debugPrint('⏳ STATUS: Loading - Template masih kosong');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Memuat konfigurasi..."),
              ],
            ),
          );
        }

        // 2. Logika Pengalihan Halaman berdasarkan Template
        debugPrint('🔄 SWITCH TEMPLATE - Mencari template: "$template"');
        switch (template) {
          case 'PPOB':
            return const PpobTemplate();

          case 'toko_online':
            return const TokoOnlineTemplate();

          case 'ojek_online':
            return const OjekOnlineTemplate();

          default:
            return const PpobTemplate();
        }
      },
    );
  }
}
