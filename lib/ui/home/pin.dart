import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Haptic Feedback
import '../../../core/app_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';

class PinPage extends StatefulWidget {
  final VoidCallback? onPinCreated;
  final bool isFromTransaction;

  const PinPage({super.key, this.onPinCreated, this.isFromTransaction = false});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // Fungsi save tetap sama secara logika, hanya UI yang berubah
  Future<void> _savePIN() async {
    if (_pinController.text.length < 6 ||
        _confirmPinController.text.length < 6) {
      setState(() => _errorMessage = 'Lengkapi 6 digit PIN Anda');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() => _errorMessage = 'Konfirmasi PIN tidak cocok');
      HapticFeedback.vibrate(); // Getar jika salah
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? token = await SessionManager.getToken();
      if (token == null) throw 'Sesi berakhir, silakan login kembali';

      final response = await _apiService.savePinData(
        _pinController.text,
        token,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccessSheet();
        }
      } else {
        throw response.data['message'] ?? 'Gagal membuat PIN';
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'PIN Berhasil Dibuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sekarang akun Anda lebih aman untuk bertransaksi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appConfig.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup sheet
                widget.onPinCreated?.call();
                Navigator.pop(context, true); // Kembali ke halaman sebelumnya
              },
              child: const Text(
                'MENGERTI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Buat PIN Keamanan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan PIN 6 digit yang sulit ditebak orang lain namun mudah Anda ingat.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              _buildLabel('PIN BARU'),
              _buildPinField(_pinController),

              const SizedBox(height: 24),

              _buildLabel('KONFIRMASI PIN BARU'),
              _buildPinField(_confirmPinController),

              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 60),

              _buildRequirementList(),

              const SizedBox(height: 40),

              _buildSubmitButton(primaryColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Widget PIN Box yang terlihat lebih modern
  Widget _buildPinField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        obscuringCharacter: '●',
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(
          fontSize: 24,
          letterSpacing: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: '••••••',
          hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (v) {
          if (v.length == 6) FocusScope.of(context).nextFocus();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildRequirementList() {
    bool isSixDigit = _pinController.text.length == 6;
    bool isMatch =
        _pinController.text.isNotEmpty &&
        _pinController.text == _confirmPinController.text;

    return Column(
      children: [
        _buildRequirementRow('6 Digit Angka Lengkap', isSixDigit),
        const SizedBox(height: 12),
        _buildRequirementRow('Konfirmasi PIN Sesuai', isMatch),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: isMet ? Colors.green : Colors.grey[300],
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? Colors.green[700] : Colors.grey[500],
            fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    bool canSubmit =
        _pinController.text.length == 6 &&
        _confirmPinController.text == _pinController.text;

    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: canSubmit && !_isLoading
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: canSubmit && !_isLoading ? _savePIN : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'SIMPAN PIN KEAMANAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
