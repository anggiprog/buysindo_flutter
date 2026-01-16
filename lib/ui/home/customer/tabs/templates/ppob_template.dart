import 'package:flutter/material.dart';
import '../../../../../core/app_config.dart';
import '../../../topup_modal.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../features/customer/data/models/banner_model.dart';
import '../../../banner_slider_widget.dart'; // Import widget slider tadi
import 'package:dio/dio.dart';
import '../../../../../core/utils/format_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import library

class PpobTemplate extends StatefulWidget {
  const PpobTemplate({super.key});

  @override
  State<PpobTemplate> createState() => _PpobTemplateState();
}

class _PpobTemplateState extends State<PpobTemplate> {
  final storage = const FlutterSecureStorage();
  // Langsung inisialisasi di sini agar instance selalu siap
  final ApiService apiService = ApiService(Dio());

  List<String> _bannerList = [];
  bool _isLoadingBanners = true;

  //saldo
  String _saldo = "0"; // Default saldo
  bool _isLoadingSaldo = true;

  @override
  void initState() {
    super.initState();
    // Panggil fetch setelah frame pertama dirender untuk keamanan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBanners();
      _fetchSaldo();
    });
  }

  //saldo
  Future<void> _fetchSaldo() async {
    try {
      // Membaca token dengan kunci 'user_token'
      // Pastikan saat Login, Anda menyimpan token dengan kunci yang sama
      String? token = await storage.read(key: 'user_token');

      if (token == null) {
        debugPrint("SALDO_LOG: Token tidak ditemukan.");
        return;
      }

      final response = await apiService.getSaldo(token);

      if (response.statusCode == 200) {
        setState(() {
          _saldo = response.data['saldo'].toString();
          _isLoadingSaldo = false;
        });
      }
    } catch (e) {
      debugPrint("SALDO_LOG_ERROR: $e");
      if (mounted) setState(() => _isLoadingSaldo = false);
    }
  }

  //banner
  Future<void> _fetchBanners() async {
    try {
      final String adminId = appConfig.adminId;

      final response = await apiService.getBanners(adminId);

      if (response.statusCode == 200 && response.data != null) {
        // Parsing data menggunakan model
        final data = BannerResponse.fromJson(response.data);
        if (mounted) {
          setState(() {
            _bannerList = data.banners;
            _isLoadingBanners = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBanners = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  void _showTopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TopupModal(primaryColor: appConfig.primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color dynamicPrimaryColor = appConfig.primaryColor;
    final Color darkHeaderColor = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.2),
      dynamicPrimaryColor,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: darkHeaderColor,
        elevation: 0,
        centerTitle: false, // Memastikan title tetap di kiri
        title: Row(
          children: [
            // Membungkus Logo agar menjadi Bulat
            Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24, // Background tipis jika logo transparan
              ),
              child: ClipOval(
                child: appConfig.logoUrl != null
                    ? Image.network(
                        appConfig.logoUrl!,
                        fit: BoxFit
                            .cover, // Memastikan gambar memenuhi lingkaran
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 20,
                            ),
                      )
                    : const Icon(Icons.store, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appConfig.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // --- TAMBAHAN ICON NOTIFIKASI & PESAN ---
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Navigasi ke halaman Notifikasi
                },
              ),
              // Badge merah dengan angka
              Positioned(
                top: 5, // Sesuaikan posisi agar angka terlihat jelas
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: darkHeaderColor,
                      width: 1.5,
                    ), // Border agar badge lebih kontras
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16, // Ukuran minimum agar lingkaran tidak gepeng
                    minHeight: 16,
                  ),
                  child: const Center(
                    child: Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              // Navigasi ke halaman Pesan/Chat
            },
          ),
          const SizedBox(width: 8), // Memberi sedikit jarak di paling kanan
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Area Banner Slider
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 90, color: darkHeaderColor),
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: _isLoadingBanners
                      ? const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : BannerSliderWidget(
                          banners: _bannerList,
                          baseUrl: apiService.imageBaseUrl,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 110), // Jarak di bawah slider
            // Card Saldo
            _buildBalanceCard(),

            // Grid Menu
            _buildMenuGrid(),
          ],
        ),
      ),
    );
  }

  // Pindahkan bagian Balance Card ke fungsi agar build() tidak terlalu penuh
  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Saldo Anda", style: TextStyle(color: Colors.black)),
                _isLoadingSaldo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        FormatUtil.formatRupiah(_saldo), // Hasil: Rp 858.560
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  Icons.account_balance_wallet,
                  "Isi Saldo",
                  _showTopup,
                ),
                _buildQuickAction(Icons.history, "Riwayat", () {}),
                _buildQuickAction(Icons.stars, "Poin: 0", () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Isi Ulang Harian",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            "Yuk Pilih Produk Disini",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            children: [
              _buildMenuIcon(Icons.flash_on, "PLN", Colors.black87),
              _buildMenuIcon(Icons.wallet, "E-Money", Colors.black87),
              _buildMenuIcon(Icons.phone_android, "Pulsa", Colors.black87),
              _buildMenuIcon(Icons.mail, "Sms & Telpon", Colors.black87),
              _buildMenuIcon(Icons.language, "Data", Colors.black87),
              _buildMenuIcon(Icons.sim_card, "Aktivasi", Colors.black87),
              _buildMenuIcon(Icons.access_time, "Masa Aktif", Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
