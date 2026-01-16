import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rutino_customer/core/app_config.dart';
import 'package:rutino_customer/core/network/api_service.dart';
import 'package:rutino_customer/core/network/session_manager.dart'; // Pastikan diimport

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final dio = Dio();
    final apiService = ApiService(dio);

    try {
      // 1. Ambil Konfigurasi Aplikasi (Warna, Nama, Logo)
      await appConfig.initializeApp(apiService);

      // 2. AMBIL TOKEN dari SessionManager (Penting!)
      String? token = await SessionManager.getToken();

      // 3. Jeda visual agar user bisa melihat logo
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 4. Logika Percabangan Halaman
      if (token != null && token.isNotEmpty) {
        // Jika ada token, pergi ke Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Jika tidak ada token, pergi ke Login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Error saat inisialisasi splash: $e");
      // Jika terjadi error (misal offline), arahkan ke login sebagai fallback
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
    // Note: Blok 'finally' dihapus agar tidak menimpa navigasi di atas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appConfig.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            // App Name
            Text(
              appConfig.appName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
