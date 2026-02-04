import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';

class BuatTab extends StatefulWidget {
  final String currentCode;
  final VoidCallback onSaved;

  const BuatTab({super.key, required this.currentCode, required this.onSaved});

  @override
  State<BuatTab> createState() => _BuatTabState();
}

class _BuatTabState extends State<BuatTab> {
  final TextEditingController _referralController = TextEditingController();
  final ApiService _apiService = ApiService(Dio());
  bool _isLoading = false;

  // SharedPreferences key
  static const String _referralCodeKey = 'cached_referral_code';

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _saveReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Referral code tidak boleh kosong.")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired. Silakan login ulang."),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final response = await _apiService.saveReferralCode(token, code);
      debugPrint('[BuatTab] Save referral response: ${response.data}');

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] == true;
        final message = data['message']?.toString() ?? '';
        final savedCode = data['referral_code'];

        if (success && savedCode != null) {
          // Cache the new referral code
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_referralCodeKey, savedCode.toString());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.isNotEmpty
                      ? message
                      : "Kode Referral berhasil dibuat!",
                ),
                backgroundColor: Colors.green,
              ),
            );
            _referralController.clear();
            widget.onSaved();
          }
        } else {
          // success: false - show error message from backend
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.isNotEmpty
                      ? message
                      : "Gagal menyimpan referral code",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          final errorMsg = (response.data is Map)
              ? (response.data['message'] ?? "Gagal menyimpan")
              : "Gagal menyimpan";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('[BuatTab] Error saving referral: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareReferral() {
    if (widget.currentCode == "-" || widget.currentCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Buat kode referral terlebih dahulu")),
      );
      return;
    }

    // Generate Play Store link dynamically from app_config
    final subdomain = appConfig.subdomain;
    final appType = appConfig.appType;
    final playStoreLink =
        'https://play.google.com/store/apps/details?id=com.$subdomain.$appType';

    final shareMessage =
        '''
🎉 *Hai, Sobat!* 🎉

Aku mau ngajak kamu pakai *${appConfig.appName}* - aplikasi yang bikin hidupmu lebih mudah! 📱✨

🎁 *BONUS SPESIAL* buat kamu yang daftar pakai kode referral aku:

👉 *${widget.currentCode}* 👈

📥 *Download sekarang di Play Store:*
$playStoreLink

Caranya gampang:
1️⃣ Download aplikasi
2️⃣ Daftar akun baru
3️⃣ Masukkan kode referral: *${widget.currentCode}*
4️⃣ Nikmati bonus-nya! 🎊

Yuk, buruan download! Jangan sampai ketinggalan ya! 🚀
''';

    Share.share(shareMessage.trim());
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Kode Referral Saat Ini",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.currentCode,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _referralController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: "Buat kode baru...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              fillColor: Colors.grey[50],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveReferral,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Bagikan ke sosial media kamu!",
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: _shareReferral,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.share, color: primaryColor, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
