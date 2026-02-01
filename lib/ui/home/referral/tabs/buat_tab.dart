import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
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

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _saveReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      final response = await _apiService.saveReferralCode(token, code);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kode Referral berhasil disimpan!")),
          );
        }
        _referralController.clear();
        widget.onSaved();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? "Gagal menyimpan"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan. Coba kode lain.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareReferral() {
    if (widget.currentCode == "-") return;
    Share.share(
      "Yuk gabung di ${appConfig.appName}! Gunakan kode referral saya: ${widget.currentCode} untuk mendapatkan keuntungan menarik. Download sekarang!",
    );
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
