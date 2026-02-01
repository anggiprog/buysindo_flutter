import 'package:flutter/material.dart';
import '../../../core/app_config.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GantiPasswordPage extends StatefulWidget {
  const GantiPasswordPage({Key? key}) : super(key: key);

  @override
  _GantiPasswordPageState createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePasswordStrength);
  }

  void _validatePasswordStrength() {
    final value = _newPasswordController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Fokuskan kembali agar keyboard turun sebelum proses API (Opsional)
      FocusScope.of(context).unfocus();

      if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
        _showSnackBar('Password belum memenuhi kriteria', Colors.red);
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackBar('Konfirmasi password tidak sama', Colors.red);
        return;
      }

      String? token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        token = prefs.getString('token') ?? prefs.getString('access_token');
      }

      if (token == null || token.isEmpty) {
        _showSnackBar('Token tidak ditemukan, silakan login ulang', Colors.red);
        return;
      }

      final apiService = ApiService(Dio());
      _showLoading();

      try {
        bool success = await apiService.changeUserPassword(
          token: token,
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        Navigator.pop(context); // Tutup loading

        if (success) {
          _showSnackBar('Password berhasil diperbarui', Colors.green);
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _showSnackBar('Gagal memperbarui password', Colors.red);
        }
      } catch (e) {
        Navigator.pop(context);
        _showSnackBar('Terjadi kesalahan koneksi', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Mencegah overflow secara otomatis
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // BouncingScrollPhysics membantu user scroll lebih nyaman saat keyboard aktif
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ganti Password",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pastikan password baru Anda kuat untuk keamanan optimal.",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _oldPasswordController,
                        label: "Password Lama",
                        isObscure: _obscureOld,
                        onToggle: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _newPasswordController,
                        label: "Password Baru",
                        isObscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildValidationChecklist(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: "Konfirmasi Password Baru",
                        isObscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                      ),
                    ],
                  ),
                ),

                // Alih-alih Spacer, gunakan SizedBox dengan tinggi fleksibel
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Perbarui Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Padding tambahan di bawah tombol agar tidak mepet keyboard saat scroll
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationChecklist() {
    return Column(
      children: [
        _checkRow("Minimal 8 Karakter", _hasMinLength),
        _checkRow("Minimal 1 Huruf Besar (A-Z)", _hasUppercase),
        _checkRow("Minimal 1 Angka (0-9)", _hasNumber),
        _checkRow("Minimal 1 Karakter Spesial (!@#\$)", _hasSpecialChar),
      ],
    );
  }

  Widget _checkRow(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            color: isDone ? Colors.green : Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDone ? Colors.green : Colors.grey[600],
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ), // Warna input teks
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
        floatingLabelStyle: TextStyle(
          color: appConfig.primaryColor,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: Colors.black87,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appConfig.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
