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
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../notifications_page.dart';

class PpobTemplate extends StatefulWidget {
  const PpobTemplate({super.key});

  @override
  State<PpobTemplate> createState() => _PpobTemplateState();
}

class _PpobTemplateState extends State<PpobTemplate> {
  final storage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  // Langsung inisialisasi di sini agar instance selalu siap
  late ApiService _apiService;
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

  // Refresh controller
  bool _isRefreshing = false;

  // Notifikasi
  int _notifCount = 0;
  bool _isNotifLoading = false;
  String? _lastNotifResponse;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize SharedPreferences once
    _prefs = await SharedPreferences.getInstance();

    // Load dari cache terlebih dahulu untuk kecepatan
    _loadFromCache();

    // Panggil fetch setelah frame pertama dirender untuk keamanan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  // Load semua data dari cache
  void _loadFromCache() {
    if (mounted) {
      setState(() {
        // Load banners dari cache
        final cachedBanners = _prefs.getStringList('cached_banners');
        if (cachedBanners != null && cachedBanners.isNotEmpty) {
          _bannerList = cachedBanners;
          _isLoadingBanners = false;
        }

        // Load menu prabayar dari cache
        final cachedMenu = _prefs.getString('cached_menu_prabayar');
        if (cachedMenu != null) {
          try {
            final List<dynamic> data = jsonDecode(cachedMenu);
            _menuList = data
                .map((item) => MenuPrabayarItem.fromJson(item))
                .toList();
            _isLoadingMenu = false;
          } catch (e) {
            debugPrint('Error loading cached menu: $e');
          }
        }

        // Load menu pascabayar dari cache
        final cachedPascabayar = _prefs.getString('cached_menu_pascabayar');
        if (cachedPascabayar != null) {
          try {
            final List<dynamic> data = jsonDecode(cachedPascabayar);
            _pascabayarList = data
                .map((item) => MenuPascabayarItem.fromJson(item))
                .toList();
            _isLoadingPascabayar = false;
          } catch (e) {
            debugPrint('Error loading cached pascabayar: $e');
          }
        }

        // Load saldo dari cache
        final cachedSaldo = _prefs.getString('cached_saldo');
        if (cachedSaldo != null) {
          _saldo = cachedSaldo;
          _isLoadingSaldo = false;
        }
      });
    }
  }

  // Fetch semua data dari API
  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchBanners(),
      _fetchSaldo(),
      _fetchMenuPrabayar(),
      _fetchPascabayar(),
      _loadNotifCount(),
    ]);
  }

  // Refresh semua data
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _fetchAllData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
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
        final saldo = response.data['saldo'].toString();

        // Cache to SharedPreference
        await _prefs.setString('cached_saldo', saldo);

        if (mounted) {
          setState(() {
            _saldo = saldo;
            _isLoadingSaldo = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSaldo = false);
      }
    } catch (e) {
      debugPrint('Error fetching saldo: $e');
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

        // Cache to SharedPreference
        await _prefs.setStringList('cached_banners', data.banners);

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
      debugPrint('Error fetching banners: $e');
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  // Menu Prabayar - WITH CACHE
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

        // Cache to SharedPreference
        final menusJson = jsonEncode(
          data.menus.map((m) => m.toJson()).toList(),
        );
        await _prefs.setString('cached_menu_prabayar', menusJson);

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
      debugPrint('Error fetching menu prabayar: $e');
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
        final pascabayarList = data
            .map((item) => MenuPascabayarItem.fromJson(item))
            .toList();

        // Cache to SharedPreference
        final pascabayarJson = jsonEncode(
          pascabayarList.map((p) => p.toJson()).toList(),
        );
        await _prefs.setString('cached_menu_pascabayar', pascabayarJson);

        if (mounted) {
          setState(() {
            _pascabayarList = pascabayarList;
            _isLoadingPascabayar = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching pascabayar: $e');
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pastikan memanggil ulang saat dependencies berubah (mis. token tersimpan setelah login)
    _loadNotifCount();
  }

  Future<void> _loadNotifCount() async {
    setState(() => _isNotifLoading = true);
    try {
      final String? token = await SessionManager.getToken();
      debugPrint('🔔 [_loadNotifCount] token from SessionManager: $token');

      // Panggil API meskipun token null — ApiService menangani header optional
      final count = await _api_service_getCountSafe(token);
      debugPrint('🔔 [_loadNotifCount] fetched count: $count');
      if (!mounted) return;
      setState(() {
        _notifCount = count;
        _isNotifLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading notif count: $e');
      if (!mounted) return;
      setState(() {
        _notifCount = 0;
        _isNotifLoading = false;
      });
    }
  }

  // Wrapper yang menyimpan last response string untuk debug dan mengembalikan count
  Future<int> _api_service_getCountSafe(String? token) async {
    try {
      final dioCount = await _api_service_getCount(token);
      _lastNotifResponse = 'OK: $dioCount';
      return dioCount;
    } catch (e) {
      _lastNotifResponse = 'Error: $e';
      return 0;
    }
  }

  // Memanggil ApiService dan juga menyimpan raw response jika memungkinkan
  Future<int> _api_service_getCount(String? token) async {
    // langsung gunakan apiService yang sudah ada
    final count = await _api_service_call(token: token);
    return count;
  }

  Future<int> _api_service_call({String? token}) async {
    // ApiService sudah mengeluarkan debugPrint dari response; tapi kembalikan count
    final count = await _api_service_getRaw(token);
    return count;
  }

  // Akhir: panggil langsung ApiService.getAdminNotificationCount dan simpan string respons
  Future<int> _api_service_getRaw(String? token) async {
    try {
      if (token == null || token.isEmpty) {
        _lastNotifResponse = 'No token';
        return 0;
      }
      final resp = await _apiService.getUserUnreadCount(token);
      debugPrint('🔔 [_api_service_getRaw] unread-count status: ${resp.statusCode} data: ${resp.data}');
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        final Map<String, dynamic> map = {};
        if (data is Map) {
          data.forEach((k, v) => map[k.toString()] = v);
        }
        final possible = map['jumlah_belum_dibaca'] ?? map['data'] ?? map['count'] ?? 0;
        final parsed = int.tryParse(possible?.toString() ?? '0') ?? 0;
        _lastNotifResponse = 'count=$parsed';
        return parsed;
      }
      _lastNotifResponse = 'unexpected status ${resp.statusCode}';
      return 0;
    } catch (e) {
      _lastNotifResponse = 'error: $e';
      return 0;
    }
  }

  Widget _buildNotifBadge() {
    final display = _notifCount > 99 ? '99+' : _notifCount.toString();
    return GestureDetector(
      onTap: () async {
        // Navigate to notifications page
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
        // refresh count when returning
        _loadNotifCount();
      },
      onLongPress: () {
        final msg = _lastNotifResponse ?? 'No response cached';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notif debug: $msg')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _isNotifLoading
              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
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
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                  _loadNotifCount();
                },
              ),
              // Badge merah dengan angka
              Positioned(
                top: 5, // Sesuaikan posisi agar angka terlihat jelas
                right: 5,
                child: _buildNotifBadge(),
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

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 40.0,
        strokeWidth: 2.5,
        color: dynamicPrimaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
    // 👈 Use gambar_url from API if available, fallback to manual URL building
    final imageUrl =
        menu.gambarUrl ??
        '${apiService.imageBannerBaseUrl}${menu.gambarKategori}';

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
                // Gunakan gambarUrl dari API jika tersedia, fallback ke manual construction
                final imageUrl =
                    menu.gambarUrl ??
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
                          color: Colors.black,
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
