import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/services/toko_online_cache_service.dart';
import '../../../banner_slider_widget.dart';
import '../../../../pages/toko_online/product_list_page.dart';
import '../../../../pages/toko_online/product_detail_page.dart';

class TokoOnlineTemplate extends StatefulWidget {
  const TokoOnlineTemplate({super.key});

  @override
  State<TokoOnlineTemplate> createState() => _TokoOnlineTemplateState();
}

class _TokoOnlineTemplateState extends State<TokoOnlineTemplate> {
  final ApiService _apiService = ApiService(Dio());
  List<String> _bannerList = [];
  bool _isLoadingBanners = true;

  // Menu/Category data
  List<Map<String, dynamic>> _menuList = [];
  bool _isLoadingMenus = true;

  // Product data
  List<Map<String, dynamic>> _productList = [];
  bool _isLoadingProducts = true;

  // Max visible menus before showing "Lainnya"
  static const int _maxVisibleMenus = 8;

  // Currency formatter
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _loadData();
  }

  /// Load data with cache-first strategy
  Future<void> _loadData() async {
    // Try to load from cache first
    await _loadFromCache();

    // Then fetch fresh data from API in background
    _fetchMenus();
    _fetchProducts();
  }

  /// Load cached data for instant display
  Future<void> _loadFromCache() async {
    final cachedMenus = await tokoOnlineCache.getMenus();
    final cachedProducts = await tokoOnlineCache.getProducts();

    if (cachedMenus != null && cachedMenus.isNotEmpty) {
      setState(() {
        _menuList = cachedMenus;
        _isLoadingMenus = false;
      });
      debugPrint('Loaded ${cachedMenus.length} menus from cache');
    }

    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      setState(() {
        _productList = cachedProducts;
        _isLoadingProducts = false;
      });
      debugPrint('Loaded ${cachedProducts.length} products from cache');
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _apiService.getBanners(appConfig.adminId);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _bannerList = List<String>.from(response.data['banners'] ?? []);
          _isLoadingBanners = false;
        });
      } else {
        setState(() => _isLoadingBanners = false);
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      setState(() => _isLoadingBanners = false);
    }
  }

  Future<void> _fetchMenus() async {
    try {
      final response = await _apiService.getTokoOnlineMenus(appConfig.adminId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final menus = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        setState(() {
          _menuList = menus;
          _isLoadingMenus = false;
        });
        // Save to cache
        await tokoOnlineCache.saveMenus(menus);
        debugPrint('Menus loaded and cached: ${menus.length}');
      } else {
        setState(() => _isLoadingMenus = false);
      }
    } catch (e) {
      debugPrint('Error fetching menus: $e');
      setState(() => _isLoadingMenus = false);
    }
  }

  Future<void> _fetchProducts({int? menuId}) async {
    // Don't show loading if we have cached data
    if (_productList.isEmpty) {
      setState(() => _isLoadingProducts = true);
    }
    try {
      final response = await _apiService.getTokoOnlineProducts(
        adminUserId: appConfig.adminId,
        menuId: menuId,
        perPage: 50, // Fetch more products for caching
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final products = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        setState(() {
          _productList = products;
          _isLoadingProducts = false;
        });
        // Save to cache
        await tokoOnlineCache.saveProducts(products);
        debugPrint('Products loaded and cached: ${products.length}');
      } else {
        setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  void _navigateToProductList(Map<String, dynamic> menu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListPage(
          menuId: menu['id'] as int,
          menuTitle: menu['title'] ?? 'Produk',
        ),
      ),
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  void _showAllMenusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAllMenusSheet(),
    );
  }

  Widget _buildAllMenusSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Semua Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appConfig.primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _menuList.length,
              itemBuilder: (context, index) {
                final menu = _menuList[index];
                final iconUrl = menu['icon_url'] as String?;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToProductList(menu);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appConfig.primaryColor.withValues(alpha: 0.1),
                        ),
                        child: ClipOval(
                          child: iconUrl != null && iconUrl.isNotEmpty
                              ? Image.network(
                                  iconUrl,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.category,
                                    color: appConfig.primaryColor,
                                    size: 24,
                                  ),
                                )
                              : Icon(
                                  Icons.category,
                                  color: appConfig.primaryColor,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 60,
                        child: Text(
                          menu['title'] ?? 'Menu',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 252),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header & Search Bar
            _buildHeader(),

            // 2. Banner Promo Slider
            _buildPromoBanner(),

            // 3. Kategori Horizontal
            _buildSectionTitle(
              "Kategori Belanja",
              onTap: _showAllMenusBottomSheet,
            ),
            _buildCategoryList(),

            // 4. Grid Produk Terpopuler
            _buildSectionTitle("Produk Terbaru"),
            _buildProductGrid(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: appConfig.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: "Cari produk favoritmu...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    if (_isLoadingBanners) {
      return Container(
        margin: const EdgeInsets.all(20),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: appConfig.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_bannerList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              appConfig.primaryColor,
              appConfig.primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                "Promo Spesial Segera Hadir!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: BannerSliderWidget(
        banners: _bannerList,
        baseUrl: _apiService.imageBaseUrl,
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: appConfig.primaryColor,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  "Lihat Semua",
                  style: TextStyle(
                    color: appConfig.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: appConfig.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoadingMenus) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: appConfig.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_menuList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Belum ada kategori',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Determine which menus to show
    final showLainnya = _menuList.length > _maxVisibleMenus;
    final displayMenus = showLainnya
        ? _menuList.sublist(0, _maxVisibleMenus - 1)
        : _menuList;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: displayMenus.length + (showLainnya ? 1 : 0),
        itemBuilder: (context, index) {
          // Show "Lainnya" button at the end
          if (showLainnya && index == displayMenus.length) {
            return _buildLainnyaMenuItem();
          }

          final menu = displayMenus[index];
          final iconUrl = menu['icon_url'] as String?;

          return GestureDetector(
            onTap: () => _navigateToProductList(menu),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appConfig.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: appConfig.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: iconUrl != null && iconUrl.isNotEmpty
                          ? Image.network(
                              iconUrl,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.category,
                                  color: appConfig.primaryColor,
                                );
                              },
                            )
                          : Icon(Icons.category, color: appConfig.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      menu['title'] ?? 'Menu',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLainnyaMenuItem() {
    return GestureDetector(
      onTap: _showAllMenusBottomSheet,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Icon(
                Icons.more_horiz,
                color: Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lainnya',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            color: appConfig.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_productList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'Belum ada produk',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: _productList.length,
      itemBuilder: (context, index) {
        final product = _productList[index];
        final imageUrl = product['gambar'] as String?;
        final harga = (product['harga'] as num?)?.toDouble() ?? 0;
        final hargaDiskon = (product['harga_diskon'] as num?)?.toDouble() ?? 0;
        final hasDiscount = hargaDiskon > 0 && hargaDiskon < harga;

        return GestureDetector(
          onTap: () => _navigateToProductDetail(product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey.shade400,
                                        size: 40,
                                      ),
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
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey.shade400,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                      // Discount badge
                      if (hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${((harga - hargaDiskon) / harga * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Product Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['nama_barang'] ?? 'Produk',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.2),
                      ),
                      const SizedBox(height: 5),
                      // Price
                      if (hasDiscount) ...[
                        Text(
                          _currencyFormatter.format(harga),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          _currencyFormatter.format(hargaDiskon),
                          style: TextStyle(
                            color: appConfig.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ] else
                        Text(
                          _currencyFormatter.format(harga),
                          style: TextStyle(
                            color: appConfig.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Stock info
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product['stok'] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
