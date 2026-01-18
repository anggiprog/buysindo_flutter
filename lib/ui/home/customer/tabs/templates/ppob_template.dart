import 'package:flutter/material.dart';
import '../../../../../core/app_config.dart';
import '../../../topup_modal.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../features/customer/data/models/banner_model.dart';
import '../../../../../features/customer/data/models/menu_prabayar_model.dart';
import '../../../../../features/customer/data/models/menu_pascabayar_model.dart';
import '../../../banner_slider_widget.dart'; // Import widget slider tadi
import 'package:dio/dio.dart';
import '../../../../../core/utils/format_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import library
import '../../../../../core/network/session_manager.dart';
import '../../tabs/templates/prabayar/pulsa.dart';

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

  // Menu Prabayar
  List<MenuPrabayarItem> _menuList = [];
  bool _isLoadingMenu = true;
  bool _showAllMenus = false;

  //menu pascabayar
  List<MenuPascabayarItem> _pascabayarList = [];
  bool _isLoadingPascabayar = true;

  @override
  void initState() {
    super.initState();

    // Panggil fetch setelah frame pertama dirender untuk keamanan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBanners();
      _fetchSaldo();
      _fetchMenuPrabayar();
      _fetchPascabayar();
    });
  }

  //saldo
  Future<void> _fetchSaldo() async {
    try {
      // 1. Gunakan SessionManager untuk mengambil token (bukan storage.read)
      String? token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        setState(() => _isLoadingSaldo = false);
        return;
      }

      // 2. Panggil API dengan token yang benar
      final response = await apiService.getSaldo(token);

      // Karena Anda menggunakan Dio dengan validateStatus < 500,
      // pastikan cek status code secara manual
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            // Sesuaikan dengan response body API Anda: {"saldo": "663656"}
            _saldo = response.data['saldo'].toString();
            _isLoadingSaldo = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSaldo = false);
      }
    } catch (e) {
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

  // Menu Prabayar - SIMPLE VERSION (no cache for now)
  Future<void> _fetchMenuPrabayar() async {
    try {
      // 1. Ambil token

      String? token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoadingMenu = false);
        return;
      }

      // 2. Fetch dari API dengan token

      final response = await apiService.getMenuPrabayar(token);

      if (response.statusCode == 200 && response.data != null) {
        final data = MenuPrabayarResponse.fromJson(response.data);

        if (mounted) {
          setState(() {
            _menuList = data.menus;
            _isLoadingMenu = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMenu = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMenu = false);
    }
  }

  Future<void> _fetchPascabayar() async {
    try {
      String? token = await SessionManager.getToken();

      if (token == null) {
        setState(() => _isLoadingPascabayar = false);
        return;
      }

      final response = await apiService.getMenuPascabayar(token);

      if (response.statusCode == 200) {
        final List data = response.data;

        if (mounted) {
          setState(() {
            _pascabayarList = data
                .map((item) => MenuPascabayarItem.fromJson(item))
                .toList();
            _isLoadingPascabayar = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPascabayar = false);
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
            // Grid Pascabayar
            _buildPascabayarGrid(),
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
          const SizedBox(height: 16),
          if (_isLoadingMenu)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_menuList.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(child: Text("Tidak ada menu tersedia")),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent:
                    105, // Menentukan tinggi tetap tiap item agar tidak overflow
              ),
              itemCount: _showAllMenus
                  ? _menuList.length
                  : (_menuList.length > 8 ? 8 : _menuList.length),
              itemBuilder: (context, index) {
                // Jika mencapai index ke-7 dan ada lebih dari 8 menu, dan tidak sedang showAll
                if (!_showAllMenus && _menuList.length > 8 && index == 7) {
                  return _buildMoreMenuIcon();
                }
                return _buildDynamicMenuIcon(_menuList[index]);
              },
            ),

          // Tombol Sembunyikan
          if (_showAllMenus && _menuList.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllMenus = false),
                  icon: const Icon(Icons.expand_less),
                  label: const Text("Sembunyikan"),
                  style: TextButton.styleFrom(
                    foregroundColor: appConfig.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicMenuIcon(MenuPrabayarItem menu) {
    final imageUrl = '${apiService.imageBannerBaseUrl}${menu.gambarKategori}';

    return InkWell(
      onTap: () {
        if (menu.namaKategori == "Pulsa") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PulsaPage()),
          );
        } else {
          debugPrint("Kategori ${menu.namaKategori} belum diatur");
        }
      }, // Penutup onTap yang benar
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            menu.namaKategori,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenuIcon() {
    return InkWell(
      onTap: () => setState(() => _showAllMenus = true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.more_horiz,
              color: appConfig.primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Lainnya",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: appConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: appConfig.primaryColor, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRID PASCABAYAR (Tagihan)
  // ==========================================
  Widget _buildPascabayarGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tagihan Pascabayar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            "Bayar tagihan bulanan lebih mudah",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_isLoadingPascabayar)
            const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pascabayarList.isEmpty)
            const SizedBox(
              height: 50,
              child: Center(child: Text("Menu tidak tersedia")),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 105,
              ),
              itemCount: _pascabayarList.length,
              itemBuilder: (context, index) {
                final menu = _pascabayarList[index];

                // PERBAIKAN DI SINI:
                // Gunakan imagePascabayarUrl agar mengarah ke folder /pascabayar/
                final imageUrl =
                    '${apiService.imagePascabayarUrl}${menu.gambarBrand}';

                // LOG UNTUK TESTING (Bisa dihapus setelah gambar muncul)

                return InkWell(
                  onTap: () => debugPrint("Klik: ${menu.namaBrand}"),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            // Jika URL salah atau 404, icon ini yang muncul
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.receipt_long,
                                size: 40,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        menu.namaBrand,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
