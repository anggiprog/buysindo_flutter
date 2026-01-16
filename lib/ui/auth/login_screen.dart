import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/app_config.dart';
import '../../core/network/auth_service.dart';
import '../../core/network/session_manager.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password harus diisi")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final authService = AuthService(dio);

      debugPrint('🔐 Attempting login with email: ${_emailController.text}');

      final loginResponse = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      debugPrint(
        '📋 Login Response: status=${loginResponse.status}, requireOtp=${loginResponse.requireOtp}, hasToken=${loginResponse.accessToken != null}',
      );

      if (!mounted) return;

      // Check if OTP is required
      if (loginResponse.requireOtp == true) {
        debugPrint('🔑 OTP REQUIRED - Navigating to OTP Screen');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OtpScreen(email: _emailController.text.trim()),
            ),
          );
        }
        return;
      }

      // If no OTP required and token is available, save and navigate
      if (loginResponse.status == true && loginResponse.accessToken != null) {
        debugPrint(
          '✅ Login successful, token received: ${loginResponse.accessToken}',
        );

        await SessionManager.saveToken(loginResponse.accessToken!);
        debugPrint('✅ Token disimpan di SessionManager');

        // Delay untuk memastikan token tersimpan dengan baik
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) {
          debugPrint('❌ Widget unmounted, cannot navigate');
          return;
        }

        debugPrint('🚀 Navigating to /home route...');
        Navigator.of(context)
            .pushReplacementNamed('/home')
            .then((_) {
              debugPrint('✅ Successfully navigated to /home');
            })
            .catchError((e) {
              debugPrint('❌ Navigation error: $e');
            });
      } else {
        final errorMsg = loginResponse.message ?? 'Login gagal';
        debugPrint('❌ Login failed: $errorMsg');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;

      final errorMsg =
          e.response?.data?['message'] ??
          'Koneksi gagal. Periksa email dan password Anda.';
      debugPrint('❌ Dio Error: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Unexpected Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: appConfig,
        builder: (context, child) {
          final primaryColor = appConfig.primaryColor;

          return Stack(
            children: [
              // Latar belakang header berwarna dinamis
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                color: primaryColor,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        // Card Putih Floating
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(primaryColor),
                              const SizedBox(height: 30),
                              const Text(
                                "LOGIN",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Input Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  hintStyle: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.black,
                                  ),
                                  prefixIconColor: Colors.black,
                                  labelText: "Email",
                                  labelStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Input Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isObscure,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration:
                                    InputDecoration(
                                      hintText: "Password",
                                      hintStyle: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outlined,
                                        color: Colors.black,
                                      ),
                                      prefixIconColor: Colors.black,
                                      labelText: "Password",
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                          width: 2.5,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isObscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.black,
                                        ),
                                        onPressed: () => setState(
                                          () => _isObscure = !_isObscure,
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 30),

                              // Tombol Login dengan Loading Indicator
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildFooterLinks(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget Helper tetap dipertahankan
  Widget _buildHeader(Color primaryColor) {
    return Row(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF081F3D),
            borderRadius: BorderRadius.circular(15),
          ),
          child: appConfig.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    appConfig.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.white),
                  ),
                )
              : const Icon(Icons.cell_tower, color: Colors.white, size: 40),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            appConfig.appName.toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text(
              "Lupa Password",
              style: TextStyle(
                color: Color(0xFFC24660),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Belum Punya Akun "),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "DAFTAR",
                style: TextStyle(
                  color: Color(0xFF1A56BE),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
