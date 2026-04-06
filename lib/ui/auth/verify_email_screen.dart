import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class VerifyEmailScreen extends StatefulWidget {
  final String? token;
  final String? status;
  final String? email;

  const VerifyEmailScreen({Key? key, this.token, this.status, this.email})
    : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late bool isSuccess;
  late Timer _timer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    isSuccess = widget.status == 'success';

    if (isSuccess && widget.token != null) {
      _saveTokenAndNavigate();
    } else {
      _startCountdown();
    }
  }

  void _saveTokenAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', widget.token!);

      // Navigate to home screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      print('Error saving token: $e');
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _timer.cancel();
            _navigateToLogin();
          }
        });
      }
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSuccess
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.red.shade50, Colors.red.shade100],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check : Icons.close,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),

                    // Title
                    Text(
                      isSuccess ? 'Verifikasi Berhasil!' : 'Verifikasi Gagal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),

                    // Message
                    Text(
                      isSuccess
                          ? 'Email Anda berhasil diverifikasi. Anda sekarang dapat menggunakan akun ini untuk login.'
                          : 'Maaf, token verifikasi tidak valid atau sudah kadaluarsa. Silakan coba mendaftar kembali.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),

                    // Email display (if available)
                    if (widget.email != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSuccess
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: isSuccess ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.email!,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 30),

                    // Countdown timer
                    Text(
                      'Mengalihkan dalam $_countdown detik...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Action buttons
                    if (isSuccess)
                      ElevatedButton(
                        onPressed: () {
                          _timer.cancel();
                          _navigateToLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Lanjut ke Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _timer.cancel();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/register',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Daftar Kembali',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _timer.cancel();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                            child: Text(
                              'Kembali ke Login',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
