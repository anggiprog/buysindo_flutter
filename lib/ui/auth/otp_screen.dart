import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk HapticFeedback
import 'package:pinput/pinput.dart';
import 'package:dio/dio.dart';
import '../../core/app_config.dart';
import '../../core/network/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int _timerSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String pin) async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final authService = AuthService(dio);
      final response = await authService.verifyOtp(widget.email, pin);

      if (response.status == true) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        _showError(response.message ?? 'Verifikasi Gagal');
      }
    } catch (e) {
      _showError('Terjadi kesalahan koneksi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _resendOtp() async {
    if (_timerSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final authService = AuthService(dio);
      await authService.resendOtp(widget.email);
      _startTimer();
      _otpController.clear();
      _showSuccess("OTP baru telah dikirim!");
    } catch (e) {
      _showError('Gagal mengirim ulang OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    // PIN THEME (MODERN STYLE)
    final defaultPinTheme = PinTheme(
      width: 65,
      height: 65,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.white,
        border: Border.all(color: primaryColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Animasi / Icon Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, size: 60, color: primaryColor),
            ),
            const SizedBox(height: 32),
            const Text(
              "Verifikasi Akun",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: "Masukkan kode OTP yang kami kirim ke\n",
                  ),
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // INPUT PINPUT
            Pinput(
              length: 4,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              separatorBuilder: (index) => const SizedBox(width: 16),
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onCompleted: (pin) => _verifyOtp(pin),
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 20,
                    height: 2,
                    color: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            if (_isLoading)
              CircularProgressIndicator(color: primaryColor)
            else
              Column(
                children: [
                  _timerSeconds > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Kirim ulang dalam $_timerSeconds detik",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Text(
                              "Tidak menerima kode?",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: _resendOtp,
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: const Text(
                                "KIRIM ULANG OTP",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            const SizedBox(height: 40),

            // Tombol verifikasi manual (Optional)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _otpController.text.length == 4 && !_isLoading
                    ? () => _verifyOtp(_otpController.text)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "VERIFIKASI SEKARANG",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
