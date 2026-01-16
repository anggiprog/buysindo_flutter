import 'dart:async';
import 'package:flutter/material.dart';
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
    _timerSeconds = 60;
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

  // FUNGSI VERIFIKASI (BACKEND: verifyOtp)
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Verifikasi Gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      debugPrint('OTP verification error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI KIRIM ULANG (BACKEND: resendOtp)
  Future<void> _resendOtp() async {
    if (_timerSeconds > 0) return;

    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final authService = AuthService(dio);

      await authService.resendOtp(widget.email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP baru telah dikirim!"),
          backgroundColor: Colors.green,
        ),
      );
      _startTimer();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      debugPrint('Resend OTP error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    // Tema Pinput (Kotak Angka)
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.mark_email_read_outlined, size: 80, color: primaryColor),
            const SizedBox(height: 24),
            const Text(
              "Verifikasi OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Masukkan 4 digit kode yang dikirim ke\n${widget.email}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),

            // INPUT OTP
            Pinput(
              length: 4,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: primaryColor, width: 2),
                ),
              ),
              onCompleted: (pin) => _verifyOtp(pin),
            ),

            const SizedBox(height: 40),

            _isLoading
                ? CircularProgressIndicator(color: primaryColor)
                : Column(
                    children: [
                      Text(
                        "Tidak menerima kode?",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: _timerSeconds == 0 ? _resendOtp : null,
                        child: Text(
                          _timerSeconds == 0
                              ? "KIRIM ULANG"
                              : "Kirim ulang dalam $_timerSeconds detik",
                          style: TextStyle(
                            color: _timerSeconds == 0
                                ? primaryColor
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
