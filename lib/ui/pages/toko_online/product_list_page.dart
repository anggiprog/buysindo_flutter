import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/app_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/toko_online_cache_service.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final int menuId;
  final String menuTitle;

  const ProductListPage({
    super.key,
    required this.menuId,
    required this.menuTitle,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService _apiService = ApiService(Dio());
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _productList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _perPage = 20;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  /// Load data with cache-first strategy
  Future<void> _loadData() async {
    // Try cache first for instant display
    final cachedProducts = tokoOnlineCache.getProductsByMenuId(widget.menuId);
    if (cachedProducts.isNotEmpty) {
      setState(() {
        _productList = cachedProducts;
        _isLoading = false;
      });
      // debugPrint('Loaded ${cachedProducts.length} products from cache');
    }

    // Fetch fresh data from API
    await _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreProducts();
    }
  }

  Future<void> _fetchProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _productList = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    // Don't show loading if we already have cached data
    if (_productList.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _apiService.getTokoOnlineProducts(
        adminUserId: appConfig.adminUserId,
        menuId: widget.menuId,
        page: _currentPage,
        perPage: _perPage,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newProducts = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        final pagination = response.data['pagination'];

        setState(() {
          if (refresh || _currentPage == 1) {
            _productList = newProducts;
          } else {
            _productList.addAll(newProducts);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMoreData =
              pagination != null &&
              pagination['current_page'] < pagination['last_page'];
        });

        // Add to cache
        await tokoOnlineCache.addProducts(newProducts);
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      // debugPrint('Error fetching products: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _fetchProducts();
  }

  void _navigateToDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.menuTitle,
          style: TextStyle(
            color: appConfig.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: appConfig.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: appConfig.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: appConfig.textColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: appConfig.primaryColor),
            )
          : _productList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: appConfig.primaryColor,
              onRefresh: () => _fetchProducts(refresh: true),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _productList.length + (_isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= _productList.length) {
                    return _buildLoadingCard();
                  }
                  return _buildProductCard(_productList[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Produk untuk kategori ini belum tersedia',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: appConfig.primaryColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = product['gambar'] as String?;
    final harga = (product['harga'] as num?)?.toDouble() ?? 0;
    final hargaDiskon = (product['harga_diskon'] as num?)?.toDouble() ?? 0;
    final hasDiscount = hargaDiskon > 0 && hargaDiskon < harga;
    final stok = product['stok'] ?? 0;

    return GestureDetector(
      onTap: () => _navigateToDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImagePlaceholder();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: appConfig.primaryColor,
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
                          : _buildImagePlaceholder(),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${((harga - hargaDiskon) / harga * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Stock Badge
                  if (stok <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Stok Habis',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product['nama_barang'] ?? 'Produk',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                      const SizedBox(height: 2),
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
                          color: stok > 0 ? Colors.grey.shade500 : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: $stok',
                          style: TextStyle(
                            fontSize: 11,
                            color: stok > 0 ? Colors.grey.shade500 : Colors.red,
                          ),
                        ),
                      ],
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

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 40),
    );
  }
}
