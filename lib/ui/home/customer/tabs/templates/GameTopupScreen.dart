import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../features/customer/data/models/banner_model.dart';
import '../../../../../core/utils/format_util.dart';
import '../../../banner_slider_widget.dart';
import '../../../topup/topup_otomatis.dart';
import '../../../topup/topup_manual.dart';
import '../../../topup_modal.dart';
import '../../../../../features/topup/screens/topup_history_screen.dart';
import '../../poin/poin.dart';
import 'detail_pulsa_page.dart';
import '../../../../../../ui/widgets/user_id_zone_dialog.dart';

class GameTopupScreen extends StatefulWidget {
  const GameTopupScreen({Key? key}) : super(key: key);

  @override
  _GameTopupScreenState createState() => _GameTopupScreenState();
}

class _GameTopupScreenState extends State<GameTopupScreen> {
  late ApiService _apiService;
  late SharedPreferences _prefs;

  List<ProductPrabayar> _allProducts = [];
  List<ProductPrabayar> _filteredProducts = [];
  List<String> _availableBrands = [];
  List<Map<String, dynamic>> _topupBrands = []; // From backend
  Map<String, String> _brandIconUrls = {};
  String _selectedBrand = "";
  String _searchQuery = "";

  // Banner & Saldo state
  List<String> _bannerList = [];
  String _saldo = "0";
  int _totalPoin = 0;
  bool _isLoadingBanners = true;
  bool _isLoadingSaldo = true;
  bool _isLoadingPoin = true;
  bool _isLoadingProducts = false;
  bool _isRefreshing = false;

  int _bannerIndex = 0;
  Timer? _bannerTimer;
  Timer? _autoRefreshTimer;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
      _startBannerAutoPlay();
    });
  }

  void _loadFromCache() {
    if (mounted) {
      setState(() {
        // Load banners dari cache
        final cachedBanners = _prefs.getStringList('cached_banners');
        if (cachedBanners != null && cachedBanners.isNotEmpty) {
          _bannerList = cachedBanners;
          _isLoadingBanners = false;
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

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchBanners(),
      _fetchSaldo(),
      _fetchPoin(),
      _loadGamesData(),
    ]);
  }

  Future<void> _fetchBanners() async {
    try {
      final String adminId = appConfig.adminUserId;
      final response = await _apiService.getBanners(adminId);

      if (response.statusCode == 200 && response.data != null) {
        // Parsing data menggunakan model seperti ppob_template
        final data = BannerResponse.fromJson(response.data);

        // Get cached banners to compare
        final cachedBanners = _prefs.getStringList('cached_banners') ?? [];

        // Check if banners have changed (new banners added or removed)
        bool bannersChanged =
            cachedBanners.length != data.banners.length ||
            !cachedBanners.every((banner) => data.banners.contains(banner));

        if (bannersChanged) {
          // Banners changed, update cache
          await _prefs.setStringList('cached_banners', data.banners);
          if (mounted) {
            setState(() {
              _bannerList = data.banners;
              _isLoadingBanners = false;
            });
          }
        } else {
          // Banners unchanged, just update loading state
          if (mounted) setState(() => _isLoadingBanners = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingBanners = false);
      }
    } catch (e) {
      // debugPrint('Error fetching banners: $e');
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  Future<void> _fetchSaldo() async {
    try {
      final String? token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        setState(() => _isLoadingSaldo = false);
        return;
      }

      final response = await _apiService.getSaldo(token);

      if (response.statusCode == 200 && response.data != null) {
        final newSaldo = response.data['saldo'].toString();

        // Get cached saldo to compare
        final cachedSaldo = _prefs.getString('cached_saldo');

        // Only update if saldo changed
        if (cachedSaldo != newSaldo) {
          await _prefs.setString('cached_saldo', newSaldo);
          if (mounted) {
            setState(() {
              _saldo = newSaldo;
              _isLoadingSaldo = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingSaldo = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingSaldo = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSaldo = false);
    }
  }

  Future<void> _fetchPoin() async {
    try {
      final String? token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        setState(() => _isLoadingPoin = false);
        return;
      }

      final response = await _apiService.getPoinSummary(token);

      if (response.statusCode == 200 && response.data != null) {
        final newPoin = (response.data['poin'] ?? 0).toInt();

        // Get cached poin to compare
        final cachedPoin = _prefs.getInt('cached_poin');

        // Only update if poin changed
        if (cachedPoin != newPoin) {
          await _prefs.setInt('cached_poin', newPoin);
          if (mounted) {
            setState(() {
              _totalPoin = newPoin;
              _isLoadingPoin = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingPoin = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingPoin = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPoin = false);
    }
  }

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

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (mounted && _bannerList.isNotEmpty) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _bannerList.length;
        });
      }
    });
  }

  Future<void> _loadGamesData() async {
    if (!mounted) return;

    // Load dari cache dulu
    _loadGamesFromCache();

    try {
      final String? token = await SessionManager.getToken();
      if (token == null) return;

      final products = await _apiService.getProducts(
        token,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          final gameProducts = products
              .where((p) => p.category.toUpperCase().contains("GAMES"))
              .toList();

          // Cek apakah ada perubahan produk
          bool productsChanged =
              gameProducts.length != _allProducts.length ||
              !gameProducts.every(
                (p) => _allProducts.any((ap) => ap.skuCode == p.skuCode),
              );

          if (productsChanged) {
            // Ada perubahan, update products
            _allProducts = gameProducts;
            _filteredProducts = _allProducts;
            _updateBrandsFromProducts();

            // Cache ke SharedPreferences
            _cacheGamesProducts(gameProducts);
          }

          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
      // debugPrint('Error loading games: $e');
    }
  }

  void _loadGamesFromCache() {
    try {
      final cachedProducts = _prefs.getString('cached_games_products');
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        final List<dynamic> data = jsonDecode(cachedProducts);
        _allProducts = data
            .map((item) => ProductPrabayar.fromJson(item))
            .toList();
        _filteredProducts = _allProducts;
        _updateBrandsFromProducts();
        setState(() => _isLoadingProducts = false);
      } else {
        setState(() => _isLoadingProducts = true);
      }
    } catch (e) {
      // debugPrint('Error loading games from cache: $e');
      setState(() => _isLoadingProducts = true);
    }
  }

  void _updateBrandsFromProducts() {
    final brandSet = <String>{};
    final brandMap = <String, Map<String, dynamic>>{};
    _brandIconUrls.clear();

    // Extract brands dan informasi dari produk
    for (var product in _allProducts) {
      if (!brandSet.contains(product.brand)) {
        brandSet.add(product.brand);
        if (product.iconUrl != null && product.iconUrl!.isNotEmpty) {
          _brandIconUrls[product.brand] = product.iconUrl!;
        }

        // Simpan brand info untuk topup categories
        brandMap[product.brand] = {
          'brand': product.brand,
          'icon': product.iconUrl ?? '',
          'title': product.brand,
        };
      }
    }

    _availableBrands = brandSet.toList()..sort();

    // Convert top 4 brands jadi topup categories untuk ditampilkan
    _topupBrands = _availableBrands.take(4).map((brand) {
      return brandMap[brand] ?? {'brand': brand, 'icon': '', 'title': brand};
    }).toList();

    if (_availableBrands.isNotEmpty) {
      _selectedBrand = _availableBrands.first;
    }
  }

  Future<void> _cacheGamesProducts(List<ProductPrabayar> products) async {
    try {
      final productsJson = jsonEncode(products.map((p) => p.toJson()).toList());
      await _prefs.setString('cached_games_products', productsJson);
    } catch (e) {
      // debugPrint('Error caching games products: $e');
    }
  }

  void _updateSearchResults() {
    if (mounted) {
      setState(() {
        if (_searchQuery.isEmpty) {
          _filteredProducts = _allProducts
              .where((p) => p.brand == _selectedBrand)
              .toList();
        } else {
          _filteredProducts = _allProducts
              .where(
                (p) =>
                    p.brand == _selectedBrand &&
                    p.productName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }
      });
    }
  }

  bool _productNeedsZoneId(String brand) {
    final brandUpperCase = brand.toUpperCase();
    const gamesNeedingZoneId = [
      'FREE FIRE',
      'FF',
      'MOBILE LEGENDS',
      'ML',
      'PUBG',
    ];

    return gamesNeedingZoneId.any((game) => brandUpperCase.contains(game));
  }

  void _showUserIdZoneDialogBeforeCheckout(ProductPrabayar product) {
    // debugPrint(
    //   'GameTopupScreen - Dialog akan ditampilkan untuk: ${product.productName}',
    // );
    // debugPrint('  Brand: ${product.brand}');
    // debugPrint('  needsZoneId: ${_productNeedsZoneId(product.brand)}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserIdZoneDialog(
        productName: product.productName,
        productBrand: product.brand,
        needsZoneId: _productNeedsZoneId(product.brand),
        onSubmit: (userId, zoneId) {
          debugPrint('GameTopupScreen - Dialog onSubmit:');
          debugPrint('  userId: $userId');
          debugPrint('  zoneId: $zoneId');

          // Gabungkan userId dan zoneId tanpa separator (087800001233)
          final fullPlayerId = zoneId != null && zoneId.isNotEmpty
              ? '$userId$zoneId'
              : userId;

          debugPrint('  fullPlayerId: $fullPlayerId');

          // Navigate to DetailPulsaPage dengan phone parameter (backward compatible)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPulsaPage(
                product: product,
                phone: fullPlayerId,
                userId: userId,
                zoneId: zoneId,
              ),
            ),
          );
        },
        onCancel: () {
          // User cancelled, stay on current page
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildBannerAreaSliver(),
            _buildBalanceCard(),
            _buildTopupCategorySection(),
            _buildGameCategoriesSection(),
            _buildSearchSection(),
            if (!_isLoadingProducts && _selectedBrand.isNotEmpty)
              _buildGameProductsSection(),
            if (_isLoadingProducts)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: appConfig.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAreaSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: appConfig.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingBanners
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : _bannerList.isNotEmpty
              ? BannerSliderWidget(
                  banners: _bannerList,
                  baseUrl: _apiService.imageBaseUrl,
                )
              : _buildEmptyBannerFallback(),
        ),
      ),
    );
  }

  Widget _buildEmptyBannerFallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            appConfig.primaryColor.withOpacity(0.8),
            appConfig.primaryColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Banner sedang dimuat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return SliverToBoxAdapter(
      child: Padding(
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
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Saldo Anda",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        MaterialPageRoute(
                          builder: (context) => const PoinPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: appConfig.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTopup() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopupModal(
        primaryColor: appConfig.primaryColor,
        apiService: _apiService,
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
              apiService: _apiService,
            ),
          ),
        );
      } else if (result['action'] == 'navigate_auto') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TopupOtomatis(
              amount: result['amount'],
              primaryColor: appConfig.primaryColor,
              apiService: _apiService,
            ),
          ),
        );
      }
    }
  }

  Widget _buildTopupCategorySection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Top Up Games Populer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          if (_topupBrands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Tidak ada game tersedia',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 120,
                ),
                itemCount: _topupBrands.length,
                itemBuilder: (context, index) {
                  final category = _topupBrands[index];
                  final brand = category['brand'] as String;
                  final iconUrl = category['icon'] as String? ?? '';
                  final title = category['title'] as String? ?? brand;

                  return GestureDetector(
                    onTap: () {
                      final brandIndex = _availableBrands.indexWhere(
                        (b) => b.toUpperCase() == brand.toUpperCase(),
                      );
                      if (brandIndex != -1) {
                        setState(() {
                          _selectedBrand = _availableBrands[brandIndex];
                          _searchQuery = "";
                          _searchController.clear();
                        });
                        _updateSearchResults();
                        // Scroll to products section
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(
                          color: appConfig.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: appConfig.primaryColor.withOpacity(0.1),
                            ),
                            child: iconUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      iconUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.sports_esports,
                                        color: appConfig.primaryColor,
                                        size: 32,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.sports_esports,
                                    color: appConfig.primaryColor,
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            _searchQuery = value;
            _updateSearchResults();
          },
          decoration: InputDecoration(
            hintText:
                'Cari produk ${_selectedBrand.isEmpty ? "..." : "untuk $_selectedBrand"}',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: appConfig.primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchQuery = "";
                      _updateSearchResults();
                    },
                    child: Icon(Icons.close, color: Colors.grey.shade500),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: appConfig.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Pilih Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: _availableBrands.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada game tersedia',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _availableBrands.length,
                    itemBuilder: (context, index) {
                      final brand = _availableBrands[index];
                      final isSelected = _selectedBrand == brand;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBrand = brand;
                            _searchQuery = "";
                            _searchController.clear();
                          });
                          _updateSearchResults();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade100,
                            border: isSelected
                                ? Border.all(
                                    color: appConfig.primaryColor,
                                    width: 2,
                                  )
                                : Border.all(color: Colors.grey.shade300),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: appConfig.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: _brandIconUrls[brand] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _brandIconUrls[brand]!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.games,
                                            color: appConfig.primaryColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.games,
                                        color: appConfig.primaryColor,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                brand,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? appConfig.primaryColor
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProductsSection() {
    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Tidak ada produk untuk game ini'
                    : 'Produk tidak ditemukan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = _filteredProducts[index];
          return _buildProductCard(product);
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildProductCard(ProductPrabayar product) {
    return GestureDetector(
      onTap: () {
        _showUserIdZoneDialogBeforeCheckout(product);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - 45% flex
            Expanded(
              flex: 45,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Color(0xFFF0F2F5),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: product.iconUrl != null && product.iconUrl!.isNotEmpty
                      ? Image.network(
                          product.iconUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.sports_esports,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
            // Product Info - 55% flex
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: appConfig.primaryColor.withOpacity(0.1),
                      ),
                      child: Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: appConfig.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
