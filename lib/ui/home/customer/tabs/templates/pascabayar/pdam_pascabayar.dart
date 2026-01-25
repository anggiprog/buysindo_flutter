import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../../features/customer/data/models/product_pascabayar_model.dart';
import 'detail_cek_tagihan.dart';

class PdamPascabayar extends StatefulWidget {
  const PdamPascabayar({super.key});

  @override
  State<PdamPascabayar> createState() => _PdamPascabayarState();
}

class _PdamPascabayarState extends State<PdamPascabayar> {
  final TextEditingController _customerIdController = TextEditingController();

  late ApiService _apiService;

  // Products Data
  List<ProductPascabayar> _allProducts = [];
  List<ProductPascabayar> _products = [];
  List<String> _availableBrands = [];
  ProductPascabayar? _selectedProduct;
  String _selectedBrand = '';
  bool _hasShownBrandDialog = false;
  bool _isRefreshing = false;

  static const String _cacheKey = 'pdam_products_cache';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _loadProducts();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  // Load pascabayar products (with cache support)
  Future<void> _loadProducts({bool forceRefresh = false}) async {
    print('🔄 [PDAM] _loadProducts called (forceRefresh: $forceRefresh)');

    try {
      // Cek cache terlebih dahulu jika bukan force refresh
      if (!forceRefresh) {
        final cachedProducts = await _loadFromCache();
        if (cachedProducts.isNotEmpty) {
          print('📦 [PDAM] Using cached products: ${cachedProducts.length}');
          if (mounted) {
            setState(() {
              _allProducts = cachedProducts;
              _availableBrands =
                  _allProducts.map((p) => p.productName).toSet().toList()
                    ..sort();
            });

            // Show dialog jika belum pernah ditampilkan
            if (!_hasShownBrandDialog && _availableBrands.isNotEmpty) {
              _hasShownBrandDialog = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showBrandSelectionDialog();
              });
            }
          }
          return;
        }
      }

      // Fetch dari API
      final token = await SessionManager.getToken();
      print('🔑 [PDAM] Token: ${token?.substring(0, 20)}...');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('🌐 [PDAM] Fetching from API...');
      final response = await _apiService.getPascabayarProducts(token);

      print('📥 [PDAM] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final productResponse = ProductPascabayarResponse.fromJson(
          response.data,
        );

        // Filter hanya produk PDAM
        final pdamProducts = productResponse.products
            .where((p) => p.brand.toUpperCase().contains('PDAM'))
            .toList();

        print('📦 [PDAM] PDAM products fetched: ${pdamProducts.length}');

        // Simpan ke cache
        await _saveToCache(pdamProducts);

        if (mounted) {
          setState(() {
            _allProducts = pdamProducts;
            _availableBrands =
                _allProducts.map((p) => p.productName).toSet().toList()..sort();
          });

          // Show brand selection dialog on first load
          if (!_hasShownBrandDialog && _availableBrands.isNotEmpty && mounted) {
            _hasShownBrandDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showBrandSelectionDialog();
              }
            });
          }

          print('✅ [PDAM] Products loaded: ${_availableBrands.length} brands');
        }
      } else {
        print('❌ [PDAM] Response status not 200: ${response.statusCode}');
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      print('❌ [PDAM] Error loading products: $e');
      print('❌ [PDAM] Error type: ${e.runtimeType}');
      if (mounted) {
        _showSnackbar('Error loading products: ${e.toString()}', Colors.red);
      }
    }
  }

  // Load products from SharedPreferences cache
  Future<List<ProductPascabayar>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList
            .map((json) => ProductPascabayar.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('⚠️ [PDAM] Error loading from cache: $e');
    }
    return [];
  }

  // Save products to SharedPreferences cache
  Future<void> _saveToCache(List<ProductPascabayar> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      print('💾 [PDAM] Saved ${products.length} products to cache');
    } catch (e) {
      print('⚠️ [PDAM] Error saving to cache: $e');
    }
  }

  // Refresh products from backend
  Future<void> _refreshProducts() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadProducts(forceRefresh: true);
      if (mounted) {
        _showSnackbar('Data PDAM berhasil diperbarui', Colors.green);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Show brand selection dialog
  void _showBrandSelectionDialog() {
    final primaryColor = appConfig.primaryColor;
    String searchQuery = ''; // Moved outside builder

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredBrands = _availableBrands
              .where(
                (brand) =>
                    brand.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih PDAM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Pilih daerah PDAM Anda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isRefreshing
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _refreshProducts();
                                  if (mounted) {
                                    _showBrandSelectionDialog();
                                  }
                                },
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          tooltip: 'Refresh daftar PDAM',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari daerah PDAM....',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: filteredBrands.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'PDAM tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredBrands.length,
                            itemBuilder: (context, index) {
                              final productName = filteredBrands[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.grey[50]!],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _selectBrand(productName);
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.water_drop,
                                              color: primaryColor,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              productName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: primaryColor,
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // Select brand and filter products
  void _selectBrand(String productName) {
    print('🏢 [PDAM] Brand selected: $productName');

    setState(() {
      _selectedBrand = productName;
      _products = _allProducts
          .where((p) => p.productName == productName)
          .toList();

      // Auto select first product
      if (_products.isNotEmpty) {
        _selectedProduct = _products.first;
        print(
          '✅ [PDAM] Auto-selected product: ${_selectedProduct!.productName}',
        );
      }
    });
  }

  // Cek Tagihan menggunakan widget global
  Future<void> _checkBill() async {
    print('🔍 [PDAM] _checkBill called');
    print('🔍 [PDAM] Selected Product: $_selectedProduct');
    print('🔍 [PDAM] Customer ID: ${_customerIdController.text}');

    if (_selectedProduct == null) {
      print('⚠️ [PDAM] No product selected');
      _showSnackbar('Pilih PDAM terlebih dahulu', Colors.orange);
      return;
    }

    if (_customerIdController.text.isEmpty) {
      print('⚠️ [PDAM] Customer ID is empty');
      _showSnackbar('Masukkan ID pelanggan terlebih dahulu', Colors.orange);
      return;
    }

    try {
      // Get admin ID from AppConfig
      final adminUserId = int.parse(appConfig.adminId);

      print('📝 [PDAM] Admin User ID (from AppConfig): $adminUserId');
      print('📝 [PDAM] Product Name: ${_selectedProduct!.productName}');
      print('📝 [PDAM] Brand: ${_selectedProduct!.brand}');
      print('📝 [PDAM] Buyer SKU Code: ${_selectedProduct!.buyerSkuCode}');

      // Show bottom sheet cek tagihan
      print('🚀 [PDAM] Showing CekTagihan bottom sheet...');
      final billData = await CekTagihanPascabayar.showCekTagihan(
        context: context,
        productName: _selectedProduct!.productName,
        brand: _selectedProduct!.brand,
        buyerSkuCode: _selectedProduct!.buyerSkuCode,
        adminUserId: adminUserId,
        cachedCustomerNo: _customerIdController.text,
      );

      print('📥 [PDAM] Bill Data Response: $billData');

      // Bottom sheet ditutup, tidak perlu action lagi di sini
      if (billData != null) {
        print('✅ [PDAM] Bill data received from bottom sheet');
      } else {
        print('ℹ️ [PDAM] User cancelled the bill check');
      }
    } catch (e) {
      print('❌ [PDAM] Error in _checkBill: $e');
      print('❌ [PDAM] Error type: ${e.runtimeType}');
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  // Show Snackbar
  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
          _customerIdController.text = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID Pelanggan: $result'),
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          'PDAM Pascabayar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderCard(primaryColor),
              _buildCustomerIdInput(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDAM Pascabayar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedBrand.isNotEmpty
                      ? _selectedBrand
                      : 'Bayar tagihan air Anda',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedBrand.isNotEmpty)
            InkWell(
              onTap: _showBrandSelectionDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerIdInput(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, primaryColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.badge, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Pelanggan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Masukkan nomor pelanggan PDAM',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerIdController,
                  keyboardType: TextInputType.text,
                  maxLength: 20,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 123456789',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.normal,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 2.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Cek Tagihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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
