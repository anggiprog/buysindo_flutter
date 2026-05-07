import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import '../../core/app_config.dart';
import '../../core/network/api_service.dart';
import '../../core/security/signature_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscure = true;
  bool _isLoading = false;
  // Password requirement flags
  bool _pwHasMin8 = false;
  bool _pwHasDigit = false;
  bool _pwHasSpecial = false;
  String? _errorMessage;
  String? _existingUserWarning;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load API credentials at startup
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      await AppConfig.loadCredentials();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Credentials will fallback to defaults
      debugPrint('Error loading credentials: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _checkExistingUser(String email) async {
    try {
      // Check apakah email sudah pernah ada di registrasi sebelumnya
      final prefs = await SharedPreferences.getInstance();
      final registeredEmails = prefs.getStringList('registered_emails') ?? [];

      if (registeredEmails.contains(email.toLowerCase())) {
        setState(() {
          _existingUserWarning =
              'Email ini sudah pernah terdaftar sebelumnya. Silakan gunakan email lain atau login.';
        });
      } else {
        setState(() => _existingUserWarning = null);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<String> _getRegistrationDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const deviceIdKey = 'stored_device_id';

    final existingId = prefs.getString(deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final generatedId =
        'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await prefs.setString(deviceIdKey, generatedId);
    return generatedId;
  }

  Future<void> _handleRegister() async {
    _clearErrorMessage();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_existingUserWarning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Email sudah terdaftar. Gunakan email lain atau login.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AppConfig.loadCredentials();

      final dio = Dio();
      final apiService = ApiService(dio);

      // --- [1] Sanitize username ---
      final sanitizedUsername = _usernameController.text
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();

      // --- [2] Prepare request body ---
      // Important: Send null instead of empty strings to match backend signature validation
      final registrationDeviceId = await _getRegistrationDeviceId();

      final body = {
        'username': sanitizedUsername,
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'full_name': _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'referral_code': _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
        'device_token': registrationDeviceId,
      };

      // --- [3] Generate signature headers ---
      // Register V2 mengikuti backend: hanya HMAC + API key.
      final apiKey = AppConfig.runtimeApiKey;
      final apiSecret = AppConfig.runtimeApiSecret;
      final credentialSource = AppConfig.runtimeCredentialSource;
      final secretFingerprint = sha256
          .convert(apiSecret.codeUnits)
          .toString()
          .substring(0, 12);

      // 🔍 Debug: Log which credentials are being used
      debugPrint('[RegisterScreen] Using credentials:');
      debugPrint('  Source: $credentialSource');
      debugPrint('  API Key: ${apiKey.substring(0, 20)}...');
      debugPrint('  API Secret: ${apiSecret.substring(0, 20)}...');
      debugPrint('  Secret Fingerprint: $secretFingerprint');

      final headers = SignatureService.generateHeaders(
        body: body,
        apiKey: apiKey,
        secret: apiSecret,
      );
      headers['X-Credential-Source'] = credentialSource;
      headers['X-Secret-Fingerprint'] = secretFingerprint;

      // --- [4] Call registerV2 dengan signature headers ---
      final url = '${apiService.baseUrl}api/registerV2';

      final response = await dio.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      // Process response

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Sukses registrasi
        final responseData = response.data;
        final responseUserId =
            responseData is Map<String, dynamic> &&
                responseData['data'] is Map<String, dynamic>
            ? responseData['data']['user_id']
            : null;

        if (responseData['error'] == false && responseUserId != null) {
          // Simpan email ke registered_emails untuk deteksi duplikat
          final prefs = await SharedPreferences.getInstance();
          final registeredEmails =
              prefs.getStringList('registered_emails') ?? [];
          if (!registeredEmails.contains(_emailController.text.toLowerCase())) {
            registeredEmails.add(_emailController.text.toLowerCase());
            await prefs.setStringList('registered_emails', registeredEmails);
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ??
                    'Registrasi berhasil! Cek email Anda untuk verifikasi.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Redirect ke login screen setelah 2 detik
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;

          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ??
                'Registrasi belum tersimpan dengan benar. Silakan coba lagi.';
          });
        }
      } else if (response.statusCode == 400) {
        // Validation error atau input tidak valid
        final responseData = response.data;
        setState(() {
          _errorMessage =
              responseData['message'] ??
              'Data tidak valid. Silakan periksa kembali.';
        });
      } else if (response.statusCode == 401) {
        final responseData = response.data;
        setState(() {
          _errorMessage =
              responseData is Map<String, dynamic>
                  ? (responseData['message'] ??
                        'Signature HMAC atau credential API tidak sesuai dengan backend.')
                  : 'Signature HMAC atau credential API tidak sesuai dengan backend.';
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage =
              response.data['message'] ??
              'Akses ditolak oleh server.';
        });
      } else if (response.statusCode == 500) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan server. Silakan coba lagi nanti.';
        });
      } else {
        setState(() {
          _errorMessage = 'Registrasi gagal. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan back button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: appConfig.primaryColor.withAlpha(
                              (0.1 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back,
                            color: appConfig.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      Text(
                        'Daftar Akun',
                        style: TextStyle(
                          color: appConfig.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 44), // Balance spacer
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Buat akun baru untuk memulai transaksi',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.1 * 255).round()),
                        border: Border.all(
                          color: Colors.red.withAlpha((0.5 * 255).round()),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Warning Message for Existing User
                  if (_existingUserWarning != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.1 * 255).round()),
                        border: Border.all(
                          color: Colors.orange.withAlpha((0.5 * 255).round()),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _existingUserWarning!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_existingUserWarning != null) const SizedBox(height: 16),

                  // Username
                  _buildLabel('Username'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration(
                      hintText: 'Masukkan username',
                      prefixIcon: Icons.person_outline,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    onChanged: (value) {
                      _clearErrorMessage();
                      // sanitize: remove whitespace and force lowercase
                      final sanitized = value
                          .replaceAll(RegExp(r'\s+'), '')
                          .toLowerCase();
                      if (sanitized != value) {
                        // update controller and move cursor to the end
                        _usernameController.value = TextEditingValue(
                          text: sanitized,
                          selection: TextSelection.collapsed(
                            offset: sanitized.length,
                          ),
                        );
                      }
                    },
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Username harus diisi';
                      }
                      if (value!.length < 3) {
                        return 'Username minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),

                  // Email
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      hintText: 'Masukkan email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      _clearErrorMessage();
                      _checkExistingUser(value);
                    },
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email harus diisi';
                      }
                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value!)) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: _buildInputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () =>
                          setState(() => _isObscure = !_isObscure),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (value) {
                      _clearErrorMessage();
                      final hasMin8 = value.length >= 8;
                      final hasDigit = RegExp(r'\d').hasMatch(value);
                      final hasSpecial = RegExp(
                        r'[^A-Za-z0-9]',
                      ).hasMatch(value);
                      setState(() {
                        _pwHasMin8 = hasMin8;
                        _pwHasDigit = hasDigit;
                        _pwHasSpecial = hasSpecial;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Password harus diisi';
                      if (value.length < 8)
                        return 'Password minimal 8 karakter';
                      // require at least one digit and one special character
                      final pattern = RegExp(r'(?=.*\d)(?=.*[^A-Za-z0-9])');
                      if (!pattern.hasMatch(value)) {
                        return 'Password harus mengandung minimal 1 angka dan 1 karakter khusus';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Live password requirement indicators
                  Row(
                    children: [
                      Icon(
                        _pwHasMin8
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _pwHasMin8 ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Minimal 8 karakter',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _pwHasDigit
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _pwHasDigit ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Minimal 1 angka',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _pwHasSpecial
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _pwHasSpecial ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Minimal 1 karakter khusus',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Referral Code (Optional)
                  _buildLabel('Kode Referral', isOptional: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _referralCodeController,
                    decoration: _buildInputDecoration(
                      hintText: 'Masukkan kode referral (opsional)',
                      prefixIcon: Icons.card_giftcard_outlined,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (_) => _clearErrorMessage(),
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appConfig.primaryColor,
                        disabledBackgroundColor: appConfig.primaryColor
                            .withAlpha((0.5 * 255).round()),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'DAFTAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Masuk',
                              style: TextStyle(
                                color: appConfig.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ), // end Column
            ), // end Form
          ), // end Padding
        ), // end SingleChildScrollView
      ), // end SafeArea
    ); // end Scaffold
  }

  // Helper method untuk label
  Widget _buildLabel(String label, {bool isOptional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isOptional) ...[
          const SizedBox(width: 4),
          Text(
            '(Opsional)',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  // Helper method untuk input decoration
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(
        prefixIcon,
        color: appConfig.primaryColor.withAlpha((0.6 * 255).round()),
        size: 22,
      ),
      suffixIcon: suffixIcon != null
          ? GestureDetector(
              onTap: onSuffixTap,
              child: Icon(suffixIcon, color: Colors.grey[400], size: 22),
            )
          : null,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appConfig.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
