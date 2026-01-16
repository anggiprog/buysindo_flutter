import 'package:flutter/material.dart';
import '../../core/app_config.dart';
import 'customer/home_customer_widget.dart';
import 'driver/home_driver_widget.dart';
import 'mitra/home_mitra_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            return const HomeCustomerScreen();
        }
      },
    );
  }
}
