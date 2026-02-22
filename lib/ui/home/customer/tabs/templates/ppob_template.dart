import 'package:buysindo_app/ui/home/customer/tabs/templates/pascabayar/gas_pascabayar.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/app_config.dart';
import '../../../topup_modal.dart';
import '../../../topup/topup_manual.dart';
import '../../../topup/topup_otomatis.dart';
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
import '../../tabs/templates/prabayar/data.dart';
import '../../tabs/templates/prabayar/sms.dart';
import '../../tabs/templates/prabayar/masa_aktif.dart';
import '../../tabs/templates/prabayar/e_money.dart';
import '../../tabs/templates/prabayar/games.dart';
import '../../tabs/templates/prabayar/pln.dart';
import '../../tabs/templates/prabayar/aktivasi_voucher.dart';
import '../../tabs/templates/prabayar/aktivasi_perdana.dart';
import '../../tabs/templates/prabayar/gas.dart';
import '../../tabs/templates/prabayar/voucher.dart';
import '../../tabs/templates/prabayar/tv.dart';
import '../../tabs/templates/prabayar/streaming.dart';
import '../../tabs/templates/pascabayar/pln_pascabayar.dart';
import '../../tabs/templates/pascabayar/pdam_pascabayar.dart';
import '../../tabs/templates/pascabayar/bpjs_kesehatan.dart';
import '../../tabs/templates/pascabayar/hp_pascabayar.dart';
import '../../tabs/templates/pascabayar/internet_pascabayar.dart';
import '../../tabs/templates/pascabayar/multifinance_pascabayar.dart';
import '../../tabs/templates/pascabayar/pbb_pascabayar.dart';
import '../../tabs/templates/pascabayar/tv_pascabayar.dart';
import '../../tabs/templates/pascabayar/pln_nontaglis_pascabayar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../features/topup/screens/topup_history_screen.dart';
import '../../tabs/templates/pascabayar/emoney_pascabayar.dart';
import '../../tabs/templates/pascabayar/byu_pascabayar.dart';
import '../../tabs/templates/pascabayar/indosat_only4u_pascabayar.dart';
import '../../tabs/templates/pascabayar/xl_axis_cuanku_pascabayar.dart';
import '../../tabs/templates/pascabayar/telkomsel_omni_pascabayar.dart';
import '../../tabs/templates/pascabayar/tri_cuanmax_pascabayar.dart';
import 'popup.dart';
import '../../poin/poin.dart';

class PpobTemplate extends StatefulWidget {
  const PpobTemplate({super.key});

  @override
  State<PpobTemplate> createState() => _PpobTemplateState();
}

class _PpobTemplateState extends State<PpobTemplate> {
  final storage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  final ApiService apiService = ApiService(Dio());

  List<String> _bannerList = [];
  bool _isLoadingBanners = true;

  //saldo
  String _saldo = "0"; // Default saldo
  bool _isLoadingSaldo = true;

  // Poin
  int _totalPoin = 0;
  bool _isLoadingPoin = true;

  // Menu Prabayar
  List<MenuPrabayarItem> _menuList = [];
  bool _isLoadingMenu = true;
  bool _showAllMenus = false;

  //menu pascabayar
  List<MenuPascabayarItem> _pascabayarList = [];
  bool _isLoadingPascabayar = true;

  // Refresh controller
  bool _isRefreshing = false;

  // Popup Manager
  late PopupManager _popupManager;

  @override
  void initState() {
    super.initState();
    _popupManager = PopupManager(apiService: apiService);
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
      // Show popup after data is loaded (with 1-hour interval check)
      _checkAndShowPopup();
    });
  }

  /// Check and show popup dialog if conditions are met
  Future<void> _checkAndShowPopup() async {
    // Small delay to ensure screen is fully rendered
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _popupManager.checkAndShowPopup(context);
    }
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
            // Handle error silently
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
            // Handle error silently
          }
        }

        // Load saldo dari cache
        final cachedSaldo = _prefs.getString('cached_saldo');
        if (cachedSaldo != null) {
          _saldo = cachedSaldo;
          _isLoadingSaldo = false;
        }

        // Load poin dari cache
        final cachedPoin = _prefs.getInt('cached_poin');
        if (cachedPoin != null) {
          _totalPoin = cachedPoin;
          _isLoadingPoin = false;
        }
      });
    }
  }

  // Fetch semua data dari API
  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchBanners(),
      _fetchSaldo(),
      _fetchPoin(),
      _fetchMenuPrabayar(),
      _fetchPascabayar(),
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
      if (mounted) setState(() => _isLoadingSaldo = false);
    }
  }

  // Fetch Poin
  Future<void> _fetchPoin() async {
    try {
      String? token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        setState(() => _isLoadingPoin = false);
        return;
      }

      final response = await apiService.getPoinSummary(token);

      if (response.statusCode == 200 && response.data != null) {
        final totalPoin = (response.data['total_poin'] ?? 0).toInt();

        // Cache to SharedPreference
        await _prefs.setInt('cached_poin', totalPoin);

        if (mounted) {
          setState(() {
            _totalPoin = totalPoin;
            _isLoadingPoin = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPoin = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPoin = false);
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
      if (mounted) setState(() => _isLoadingPascabayar = false);
    }
  }

  void _showTopup() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopupModal(
        primaryColor: appConfig.primaryColor,
        apiService: apiService,
      ),
    );

    // Handle navigation based on result
    if (result is Map && result['action'] != null && mounted) {
      if (result['action'] == 'navigate_manual') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TopupManual(
              amount: result['amount'],
              primaryColor: appConfig.primaryColor,
              apiService: apiService,
            ),
          ),
        );
      } else if (result['action'] == 'navigate_auto') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TopupOtomatis(
              amount: result['amount'],
              primaryColor: appConfig.primaryColor,
              apiService: apiService,
            ),
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Shimmer loaders
  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 105,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPascabayarShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 105,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color dynamicPrimaryColor = appConfig.primaryColor;
    final Color primaryColor = appConfig.primaryColor;
    // Update status bar color to match app primary color
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Use services prefix for SystemChrome if available
        // import at top: import 'package:flutter/services.dart' as services;
      } catch (_) {}
    });

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 40.0,
      strokeWidth: 2.5,
      color: dynamicPrimaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area Banner Slider
            _buildBannerArea(primaryColor),
            const SizedBox(height: 110), // Jarak di bawah slider
            // Card Saldo
            _buildBalanceCard(),

            // Grid Menu Header + Grid Content
            _buildMenuGrid(),
            _buildMenuGridContent(),

            // Grid Pascabayar Header + Content
            _buildPascabayarGrid(),
            _buildPascabayarGridContent(),
          ],
        ),
      ),
    );
  }

  // 🎨 Extract Banner Area untuk optimalkan rebuild
  Widget _buildBannerArea(Color primaryColor) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(height: 90, color: primaryColor),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: _isLoadingBanners
                ? _buildBannerShimmer()
                : BannerSliderWidget(
                    banners: _bannerList,
                    baseUrl: apiService.imageBaseUrl,
                  ),
          ),
        ],
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
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Saldo Anda", style: TextStyle(color: Colors.black)),
                _isLoadingSaldo
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 150,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    : Text(
                        FormatUtil.formatRupiah(_saldo),
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
                _buildQuickAction(Icons.history, "Histori", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopupHistoryScreen(),
                    ),
                  );
                }),
                _buildQuickAction(
                  Icons.stars,
                  _isLoadingPoin ? "Poin: ..." : "Poin: $_totalPoin",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PoinPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 12, right: 12, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Isi Ulang Harian",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            "Yuk Pilih Produk Disini",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 🎨 Separate grid content untuk optimalkan rebuild dengan RepaintBoundary
  Widget _buildMenuGridContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 0),
      child: RepaintBoundary(
        child: Column(
          children: [
            if (_isLoadingMenu)
              _buildMenuShimmer()
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
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 82,
                ),
                itemCount: _showAllMenus
                    ? _menuList.length
                    : (_menuList.length > 8 ? 8 : _menuList.length),
                itemBuilder: (context, index) {
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
        } else if (menu.namaKategori == "Data") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataPage()),
          );
        } else if (menu.namaKategori == "Paket SMS & Telpon") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SmsPage()),
          );
        } else if (menu.namaKategori == "Masa Aktif") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MasaAktifPage()),
          );
        } else if (menu.namaKategori == "E-Money") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EMoneyPage()),
          );
        } else if (menu.namaKategori == "Games") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GamesPage()),
          );
        } else if (menu.namaKategori == "PLN") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PLNPage()),
          );
        } else if (menu.namaKategori == "Aktivasi Voucher") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AktivasiVoucherPage(),
            ),
          );
        } else if (menu.namaKategori == "Aktivasi Perdana") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AktivasiPerdanaPage(),
            ),
          );
        } else if (menu.namaKategori == "Gas") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GasPage()),
          );
        } else if (menu.namaKategori == "Voucher") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VoucherPage()),
          );
        } else if (menu.namaKategori == "TV") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TVPage()),
          );
        } else if (menu.namaKategori == "Streaming") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StreamingPage()),
          );
        } else {
          // Menu category not handled
        }
      },
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
                cacheHeight: 40,
                cacheWidth: 40,
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
      padding: const EdgeInsets.only(top: 30, left: 12, right: 12, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Tagihan Pascabayar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            "Bayar tagihan bulanan lebih mudah",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _buildPascabayarGridContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 12, right: 12, bottom: 0),
      child: RepaintBoundary(
        child: Column(
          children: [
            if (_isLoadingPascabayar)
              _buildPascabayarShimmer()
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
                  final imageUrl =
                      menu.gambarUrl ??
                      '${apiService.imagePascabayarUrl}${menu.gambarBrand}';

                  return InkWell(
                    onTap: () {
                      // Handle brand tap - Navigate based on brand name
                      final brand = menu.namaBrand.toLowerCase();
                      if (brand.contains('nontaglis')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PlnNontaglisPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('pln')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlnPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('pdam')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PdamPascabayar(),
                          ),
                        );
                      } else if (brand.contains('bpjs')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BpjsKesehatanPage(),
                          ),
                        );
                      } else if (brand.contains('hp')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HpPascabayar(),
                          ),
                        );
                      } else if (brand.contains('internet')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InternetPascabayar(),
                          ),
                        );
                      } else if (brand.contains('multifinance')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MultifinancePascabayar(),
                          ),
                        );
                      } else if (brand.contains('pbb')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PbbPascabayar(),
                          ),
                        );
                      } else if (brand.contains('tv')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TvPascabayar(),
                          ),
                        );
                      } else if (brand.contains('gas')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GasPascabayar(),
                          ),
                        );
                      } else if (brand.contains('e-money') ||
                          brand.contains('emoney')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmoneyPascabayar(),
                          ),
                        );
                      } else if (brand.contains('by.u') ||
                          brand.contains('by.u')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ByuPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('indosat only4u') ||
                          brand.contains('indosat only4u')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const IndosatOnly4uPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('telkomsel omni') ||
                          brand.contains('telkomsel omni')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TelkomselOmniPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('xl axis cuanku') ||
                          brand.contains('xl axis cuanku')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const XlAxisCuankuPascabayarPage(),
                          ),
                        );
                      } else if (brand.contains('tri cuanmax') ||
                          brand.contains('tri cuanmax')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TriCuanMaxPascabayarPage(),
                          ),
                        );
                      } else {
                        // For other pascabayar brands, show coming soon
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${menu.namaBrand} coming soon'),
                            backgroundColor: appConfig.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
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
                              cacheHeight: 40,
                              cacheWidth: 40,
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
      ),
    );
  }
}
