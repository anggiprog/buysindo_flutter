import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class PLNPage extends StatefulWidget {
  const PLNPage({super.key});

  @override
  State<PLNPage> createState() => _PLNPageState();
}

class _PLNPageState extends State<PLNPage> with TickerProviderStateMixin {
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  TabController? _tabController;
  int _filterStatus = 0; // 0: Normal, 1: Termurah, 2: Termahal

  List<ProductPrabayar> _allProducts = [];
  List<String> _dynamicTypes = [];

  bool _isLoading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _meterController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? token = await SessionManager.getToken();

      if (forceRefresh) {
        await _clearProductsCache();
      }

      final products = await _apiService.getProducts(
        token,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          // Filter: Hanya ambil kategori PLN
          _allProducts = products
              .where((p) => p.category.toUpperCase().contains("PLN"))
              .toList();

          // Extract unique types
          final types = _allProducts.map((p) => p.type).toSet().toList();
          _dynamicTypes = types;

          _isLoading = false;

          // Setup TabController
          _tabController?.dispose();
          if (_dynamicTypes.isNotEmpty) {
            _tabController = TabController(
              length: _dynamicTypes.length,
              vsync: this,
            );
          }

          print('=== PLN DEBUG ===');
          print('Total Products: ${_allProducts.length}');
          print('Types: $_dynamicTypes');
          print('==================');
        });

        if (forceRefresh && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data diperbarui: ${_allProducts.length} produk'),
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

  Future<void> _clearProductsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');
      print('🗑️ Cache produk berhasil dihapus');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  Future<void> _scanBarcode() async {
    try {
      // Request camera permission - will show system dialog automatically
      final status = await Permission.camera.request();

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin kamera diperlukan untuk scan barcode'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          // Show dialog to open settings
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Kamera Diperlukan'),
              content: const Text(
                'Aplikasi memerlukan akses kamera untuk scan barcode. '
                'Silakan aktifkan izin kamera di pengaturan aplikasi.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Permission granted, proceed with scanning
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _meterController.text = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor Meter: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka scanner: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleProductTap(ProductPrabayar product) {
    if (_meterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Nomor Meter/ID Pelanggan terlebih dahulu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPulsaPage(product: product, phone: _meterController.text),
      ),
    );
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
    if (_tabController == null || _dynamicTypes.isEmpty) {
      return [];
    }

    final selectedType = _dynamicTypes[_tabController!.index];

    var filtered = _allProducts.where((p) {
      return p.type == selectedType;
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
          _buildInputSection(),
          if (_dynamicTypes.isNotEmpty) ...[
            _buildTabBar(),
            _buildProductGrid(),
          ] else
            _buildEmptyState(),
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
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'PLN Prabayar',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
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
                        children: const [
                          Text(
                            '⚡ Token PLN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Beli token listrik lebih mudah',
                            style: TextStyle(
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
                    Icons.electric_bolt,
                    color: appConfig.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Pelanggan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meter Number Input with Scan Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meterController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nomor Meter / ID Pelanggan',
                      hintText: 'Masukkan nomor meter PLN',
                      prefixIcon: Icon(
                        Icons.credit_card,
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
                ),
                const SizedBox(width: 12),
                // Scan Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        appConfig.primaryColor,
                        appConfig.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: appConfig.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _scanBarcode,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

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
                      'Pastikan nomor meter/ID pelanggan sudah benar. Anda bisa scan barcode pada struk PLN atau masukkan manual.',
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
                      hintText: 'Cari nominal...',
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

            // Products
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
    final hasDiscount = product.produkDiskon > 0;
    final int originalPrice = product.totalHarga + product.produkDiskon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: appConfig.primaryColor.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleProductTap(product),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ICON PLN from Backend
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.amber[50],
                ),
                child: product.iconUrl != null && product.iconUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.iconUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.electric_bolt,
                              color: Colors.amber[700],
                              size: 28,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amber[700],
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.electric_bolt,
                        color: Colors.amber[700],
                        size: 28,
                      ),
              ),

              // PRODUCT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // PRICE SECTION
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Original Price (if discount exists)
                  if (hasDiscount) ...[
                    Text(
                      'Rp ${originalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Sale Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rp ${product.totalHarga.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Hemat ${_formatDiscount(product.produkDiskon)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.electric_bolt_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada produk tersedia',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
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

// Barcode Scanner Screen
class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _isProcessing = true;
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            tooltip: 'Flash',
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'Flip',
            onPressed: () => cameraController.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: cameraController, onDetect: _handleBarcode),

          // Dark overlay with transparent center
          CustomPaint(painter: _ScannerOverlayPainter(), child: Container()),

          // Scanner frame and UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Scanner frame with corner brackets
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    children: [
                      // Corner brackets
                      ..._buildCornerBrackets(primaryColor),

                      // Animated scanning line
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: _animationController.value * 260,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    primaryColor.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Arahkan Kamera ke Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan barcode berada di dalam frame',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color) {
    const double size = 40;
    const double thickness = 4.0;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(2)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(2)),
          ),
        ),
      ),

      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(2)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(2)),
          ),
        ),
      ),

      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2),
            ),
          ),
        ),
      ),

      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
    ];
  }
}

// Custom painter for scanner overlay
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    const scanAreaSize = 280.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
