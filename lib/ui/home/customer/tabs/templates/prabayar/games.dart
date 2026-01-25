import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> with TickerProviderStateMixin {
  final TextEditingController _playerIdController = TextEditingController();
  final TextEditingController _zoneIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedBrand = ""; // Selected Game Brand (ML, FF, PUBG, etc)
  TabController? _tabController;
  int _filterStatus = 0; // 0: Normal, 1: Termurah, 2: Termahal

  List<ProductPrabayar> _allProducts = [];
  List<String> _dynamicTypes = [];
  List<String> _availableBrands = []; // List of available game brands
  Map<String, String> _brandIconUrls = {}; // Map brand to icon URL

  bool _isLoading = false;
  bool _requiresZoneId = false; // Flag untuk games yang butuh Zone ID

  late ApiService _apiService;

  // Map game brands yang memerlukan Zone ID/Server ID
  final Map<String, String> _gamesWithZoneId = {
    'MOBILE LEGENDS': 'Zone ID',
    'ML': 'Zone ID',
    'PUBG': 'Character ID',
    'PUBG MOBILE': 'Character ID',
    'AOV': 'Server ID',
    'ARENA OF VALOR': 'Server ID',
    'CALL OF DUTY': 'Character ID',
    'COD': 'Character ID',
  };

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _playerIdController.dispose();
    _zoneIdController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? token = await SessionManager.getToken();

      // Clear cache jika forceRefresh
      if (forceRefresh) {
        await _clearProductsCache();
      }

      final products = await _apiService.getProducts(
        token,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          // Filter: Hanya ambil kategori GAMES
          _allProducts = products
              .where((p) => p.category.toUpperCase().contains("GAMES"))
              .toList();

          // Extract unique brands untuk Games dan icon URLs
          final brandSet = <String>{};
          _brandIconUrls.clear();

          for (var product in _allProducts) {
            if (!brandSet.contains(product.brand)) {
              brandSet.add(product.brand);
              // Simpan icon URL untuk setiap brand (ambil yang pertama)
              if (product.iconUrl != null && product.iconUrl!.isNotEmpty) {
                _brandIconUrls[product.brand] = product.iconUrl!;
              }
            }
          }

          _availableBrands = brandSet.toList()..sort();

          _isLoading = false;

          // Debug log
          print('=== GAMES DEBUG ===');
          print('Total Products: ${_allProducts.length}');
          print('Total Brands: ${_availableBrands.length}');
          print('Brands: $_availableBrands');
          print('==================');
        });

        // Tampilkan notifikasi jika refresh
        if (forceRefresh && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data diperbarui: ${_allProducts.length} produk, ${_availableBrands.length} game',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui produk: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Clear cache products dari SharedPreferences
  Future<void> _clearProductsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');
      print('🗑️ Cache produk berhasil dihapus');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  void _selectBrand(String brand) {
    setState(() {
      _selectedBrand = brand;
      _playerIdController.clear();
      _zoneIdController.clear();

      // Check if this game requires Zone ID
      _requiresZoneId = _gamesWithZoneId.keys.any(
        (key) => brand.toUpperCase().contains(key),
      );

      _updateDynamicTabs();
    });
  }

  void _updateDynamicTabs() {
    if (_selectedBrand.isEmpty) return;

    // Filter berdasarkan Brand dan Kategori GAMES
    final filteredByBrand = _allProducts.where((p) {
      return p.brand.toUpperCase() == _selectedBrand.toUpperCase();
    }).toList();

    final types = filteredByBrand.map((p) => p.type).toSet().toList();

    if (mounted) {
      setState(() {
        _dynamicTypes = types;
        _tabController?.dispose();
        if (_dynamicTypes.isNotEmpty) {
          _tabController = TabController(
            length: _dynamicTypes.length,
            vsync: this,
          );
        }
      });
    }
  }

  void _handleProductTap(ProductPrabayar product) {
    // Validasi input
    if (_playerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan ${_getPlayerIdLabel()} terlebih dahulu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_requiresZoneId && _zoneIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan ${_getZoneIdLabel()} terlebih dahulu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Gabungkan player ID dan zone ID jika diperlukan
    final fullPlayerId = _requiresZoneId
        ? '${_playerIdController.text}|${_zoneIdController.text}'
        : _playerIdController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPulsaPage(product: product, phone: fullPlayerId),
      ),
    );
  }

  String _getPlayerIdLabel() {
    if (_selectedBrand.toUpperCase().contains('FREE FIRE') ||
        _selectedBrand.toUpperCase().contains('FF')) {
      return 'ID Player';
    } else if (_selectedBrand.toUpperCase().contains('MOBILE LEGENDS') ||
        _selectedBrand.toUpperCase().contains('ML')) {
      return 'User ID';
    } else if (_selectedBrand.toUpperCase().contains('PUBG')) {
      return 'Player ID';
    }
    return 'Player ID / User ID';
  }

  String _getZoneIdLabel() {
    final brandUpper = _selectedBrand.toUpperCase();
    for (final entry in _gamesWithZoneId.entries) {
      if (brandUpper.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Zone ID';
  }

  String _formatDiscount(num amount) {
    final intAmount = amount.toStringAsFixed(0);
    final formatted = intAmount.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  List<ProductPrabayar> _getFilteredProducts() {
    if (_selectedBrand.isEmpty || _tabController == null) {
      return [];
    }

    final selectedType = _dynamicTypes[_tabController!.index];

    var filtered = _allProducts.where((p) {
      return p.brand.toUpperCase() == _selectedBrand.toUpperCase() &&
          p.type == selectedType;
    }).toList();

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.productName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }).toList();
    }

    // Apply price sorting
    if (_filterStatus == 1) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_filterStatus == 2) {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_selectedBrand.isEmpty) ...[
            _buildBrandSelection(),
          ] else ...[
            _buildInputSection(),
            if (_dynamicTypes.isNotEmpty) ...[
              _buildTabBar(),
              _buildProductGrid(),
            ] else
              _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: appConfig.primaryColor,
      leading: IconButton(
        icon: _selectedBrand.isEmpty
            ? const Icon(Icons.arrow_back, color: Colors.white)
            : const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (_selectedBrand.isEmpty) {
            Navigator.pop(context);
          } else {
            setState(() {
              _selectedBrand = "";
              _playerIdController.clear();
              _zoneIdController.clear();
              _tabController?.dispose();
              _tabController = null;
            });
          }
        },
      ),
      actions: [
        if (_selectedBrand.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadData(forceRefresh: true),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Perbarui Data',
            onPressed: () => _loadData(forceRefresh: true),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                appConfig.primaryColor,
                appConfig.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 60),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎮 Top Up Game',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedBrand.isEmpty
                                ? 'Pilih game favoritmu'
                                : _selectedBrand,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSelection() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableBrands.isEmpty) {
      return SliverFillRemaining(
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_esports,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tidak ada game tersedia',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tarik ke bawah untuk refresh',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Game (${_availableBrands.length} tersedia)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _loadData(forceRefresh: true),
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: appConfig.primaryColor,
                      ),
                      label: Text(
                        'Refresh',
                        style: TextStyle(color: appConfig.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableBrands.length,
                  itemBuilder: (context, index) {
                    final brand = _availableBrands[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(width: 110, child: _buildGameCard(brand)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tarik ke bawah untuk refresh data',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(String brand) {
    final iconUrl = _brandIconUrls[brand];

    return InkWell(
      onTap: () => _selectBrand(brand),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appConfig.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dari Backend
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: appConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.sports_esports,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : const Icon(
                      Icons.sports_esports,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                brand,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    color: appConfig.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Player ID Input
            TextField(
              controller: _playerIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                labelText: _getPlayerIdLabel(),
                hintText: 'Masukkan ${_getPlayerIdLabel()}',
                prefixIcon: Icon(Icons.gamepad, color: appConfig.primaryColor),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: appConfig.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            // Zone ID Input (jika diperlukan)
            if (_requiresZoneId) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _zoneIdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: _getZoneIdLabel(),
                  hintText: 'Masukkan ${_getZoneIdLabel()}',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: appConfig.primaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: appConfig.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _requiresZoneId
                          ? 'Masukkan ${_getPlayerIdLabel()} dan ${_getZoneIdLabel()} yang benar'
                          : 'Masukkan ${_getPlayerIdLabel()} yang benar',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: appConfig.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: appConfig.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: _dynamicTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: appConfig.primaryColor,
                      size: 20,
                    ),
                  ),
                  onSelected: (value) => setState(() => _filterStatus = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Normal')),
                    const PopupMenuItem(value: 1, child: Text('Termurah')),
                    const PopupMenuItem(value: 2, child: Text('Termahal')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Products - Only render if TabController is ready
            if (_tabController != null && _dynamicTypes.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  children: _dynamicTypes.map((type) {
                    final products = _getFilteredProducts();

                    if (products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Tidak ada produk tersedia',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(products[index]);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductPrabayar product) {
    final iconUrl = product.iconUrl;
    final hasDiscount = product.produkDiskon > 0;

    return InkWell(
      onTap: () => _handleProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: appConfig.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge with Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appConfig.primaryColor,
                        appConfig.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconUrl != null && iconUrl.isNotEmpty) ...[
                        Image.network(
                          iconUrl,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.sports_esports,
                              size: 16,
                              color: Colors.white,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                      ] else ...[
                        const Icon(
                          Icons.sports_esports,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          product.brand,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product Image - Full width
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: iconUrl != null && iconUrl.isNotEmpty
                                ? Image.network(
                                    iconUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.sports_esports,
                                        size: 70,
                                        color: Colors.grey[400],
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  )
                                : Icon(
                                    Icons.sports_esports,
                                    size: 70,
                                    color: Colors.grey[400],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Product Name - Text Hitam
                        Text(
                          product.productName,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Price - Tanpa simbol $
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Rp ${product.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Discount Badge - Shows discount amount
            if (hasDiscount)
              Positioned(
                top: 30,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Rp. ${_formatDiscount(product.produkDiskon)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      child: Center(
        child: Text(
          'Tidak ada produk tersedia',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// Helper class untuk sticky tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
