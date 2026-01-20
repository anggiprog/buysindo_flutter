import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:rutino_customer/core/app_config.dart';
import 'package:rutino_customer/core/network/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Animasi state
  double _opacity = 0;
  double _scale = 0.8;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _initApp();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1;
          _scale = 1.0;
        });
      }
    });
  }

  Future<void> _initApp() async {
    try {
      // Ambil token user (cepat dari local storage)
      final startTime = DateTime.now();
      String? token = await SessionManager.getToken();
      final tokenDuration = DateTime.now().difference(startTime);
      debugPrint(
        '⏱️ SessionManager.getToken: ${tokenDuration.inMilliseconds}ms',
      );

      // MINIMUM delay untuk animasi (300ms cukup)
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Remove native splash screen sebelum navigate
      debugPrint('🗑️ Removing native splash screen...');
      FlutterNativeSplash.remove();

      debugPrint(
        '✅ Splash screen removed, navigating to: ${token != null && token.isNotEmpty ? '/home' : '/login'}',
      );

      // Navigasi ke halaman selanjutnya
      _navigateToNext(token != null && token.isNotEmpty ? '/home' : '/login');
    } catch (e) {
      debugPrint("❌ Error inisialisasi: $e");
      FlutterNativeSplash.remove();
      if (mounted) _navigateToNext('/login');
    }
  }

  void _navigateToNext(String routeName) {
    debugPrint('🚀 Navigating to: $routeName');
    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;
    // Membuat warna secondary yang lebih gelap untuk gradasi
    final Color secondaryColor = HSLColor.fromColor(primaryColor)
        .withLightness(
          (HSLColor.fromColor(primaryColor).lightness - 0.1).clamp(0, 1),
        )
        .toColor();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Decoration (Opsional: Membuat lingkaran halus di background)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _scale,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: _opacity,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: Column(
                    children: [
                      Text(
                        appConfig.appName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 40,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer / Loading di bawah
            Positioned(
              bottom: 60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _opacity,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Transaksi Mudah, Cepat, dan Aman",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
