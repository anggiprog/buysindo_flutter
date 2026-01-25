import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../../../../../../features/customer/data/models/product_pascabayar_model.dart';
import 'detail_cek_tagihan.dart';

class PbbPascabayar extends StatefulWidget {
  const PbbPascabayar({super.key});

  @override
  State<PbbPascabayar> createState() => _PbbPascabayarState();
}

class _PbbPascabayarState extends State<PbbPascabayar> {
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

  static const String _cacheKey = 'pbb_products_cache';

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
    print('🔄 [PBB] _loadProducts called (forceRefresh: $forceRefresh)');

    try {
      // Cek cache terlebih dahulu jika bukan force refresh
      if (!forceRefresh) {
        final cachedProducts = await _loadFromCache();
        if (cachedProducts.isNotEmpty) {
          print('📦 [PBB] Using cached products: ${cachedProducts.length}');
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
      print('🔑 [PBB] Token: ${token?.substring(0, 20)}...');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('🌐 [PBB] Fetching from API...');
      final response = await _apiService.getPascabayarProducts(token);

      print('📥 [PBB] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final productResponse = ProductPascabayarResponse.fromJson(
          response.data,
        );

        // Filter hanya produk PBB
        final pbbProducts = productResponse.products
            .where((p) => p.brand.toUpperCase().contains('PBB'))
            .toList();

        print('📦 [PBB] PBB products fetched: ${pbbProducts.length}');

        // Simpan ke cache
        await _saveToCache(pbbProducts);

        if (mounted) {
          setState(() {
            _allProducts = pbbProducts;
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

          print('✅ [PBB] Products loaded: ${_availableBrands.length} brands');
        }
      } else {
        print('❌ [PBB] Response status not 200: ${response.statusCode}');
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      print('❌ [PBB] Error loading products: $e');
      print('❌ [PBB] Error type: ${e.runtimeType}');
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
      print('⚠️ [PBB] Error loading from cache: $e');
    }
    return [];
  }

  // Save products to SharedPreferences cache
  Future<void> _saveToCache(List<ProductPascabayar> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      print('💾 [PBB] Saved ${products.length} products to cache');
    } catch (e) {
      print('⚠️ [PBB] Error saving to cache: $e');
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
        _showSnackbar('Data PBB berhasil diperbarui', Colors.green);
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
    String searchQuery = '';

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
                            Icons.location_city,
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
                                'Pilih Wilayah',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Pilih provider PBB',
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
                          tooltip: 'Refresh daftar provider',
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
                        hintText: 'Cari provider....',
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
                                    'Provider tidak ditemukan',
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
                                      setState(() {
                                        _selectedBrand = productName;
                                        _selectedProduct = _allProducts
                                            .firstWhere(
                                              (p) =>
                                                  p.productName == productName,
                                            );
                                      });
                                      _showSnackbar(
                                        'Provider dipilih: $productName',
                                        Colors.green,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.location_city,
                                              color: primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              productName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[400],
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Pick contact from phonebook
  Future<void> _pickContact() async {
    try {
      // Request permission
      final permissionStatus = await Permission.contacts.request();

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          _showSnackbar(
            'Izin kontak diperlukan untuk memilih nomor',
            Colors.orange,
          );

          // Show dialog to open settings if permanently denied
          if (permissionStatus.isPermanentlyDenied) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Izin Diperlukan'),
                content: const Text(
                  'Aplikasi memerlukan izin akses kontak. Silakan aktifkan di pengaturan.',
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
        }
        return;
      }

      // Open contact picker (native Android/iOS picker)
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null && contact.phones.isNotEmpty) {
        // Get first phone number
        String phoneNumber = contact.phones.first.number;

        // Clean phone number: remove spaces, dashes, parentheses, plus signs
        phoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

        // Convert 62 to 0 (Indonesian format)
        if (phoneNumber.startsWith('62')) {
          phoneNumber = '0${phoneNumber.substring(2)}';
        }

        // Ensure it starts with 0
        if (!phoneNumber.startsWith('0')) {
          phoneNumber = '0$phoneNumber';
        }

        if (mounted) {
          setState(() {
            _customerIdController.text = phoneNumber;
          });
          _showSnackbar('Nomor kontak dipilih', Colors.green);
        }
      }
    } catch (e) {
      print('❌ Error picking contact: $e');
      if (mounted) {
        _showSnackbar('Gagal memilih kontak', Colors.red);
      }
    }
  }

  // Scan barcode
  Future<void> _scanBarcode() async {
    try {
      // Request camera permission
      final permissionStatus = await Permission.camera.request();

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          _showSnackbar(
            'Izin kamera diperlukan untuk scan barcode',
            Colors.orange,
          );

          if (permissionStatus.isPermanentlyDenied) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Izin Diperlukan'),
                content: const Text(
                  'Aplikasi memerlukan izin kamera. Silakan aktifkan di pengaturan.',
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
        }
        return;
      }

      // Open barcode scanner
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => _BarcodeScannerScreen()),
      );

      if (result != null && result is String && mounted) {
        setState(() {
          _customerIdController.text = result;
        });
        _showSnackbar('Barcode berhasil dipindai', Colors.green);
      }
    } catch (e) {
      print('❌ Error scanning barcode: $e');
      if (mounted) {
        _showSnackbar('Gagal scan barcode', Colors.red);
      }
    }
  }

  // Cek tagihan
  Future<void> _cekTagihan() async {
    if (_selectedProduct == null) {
      _showSnackbar('Silakan pilih wilayah terlebih dahulu', Colors.orange);
      return;
    }

    final customerId = _customerIdController.text.trim();
    if (customerId.isEmpty) {
      _showSnackbar('NOP tidak boleh kosong', Colors.orange);
      return;
    }

    try {
      // Get admin user ID
      final adminUserId = int.parse(appConfig.adminId);

      print('📝 [PBB] Customer ID: $customerId');
      print('📝 [PBB] Admin User ID (from AppConfig): $adminUserId');
      print('📝 [PBB] Product Name: ${_selectedProduct!.productName}');
      print('📝 [PBB] Brand: ${_selectedProduct!.brand}');
      print('📝 [PBB] Buyer SKU Code: ${_selectedProduct!.buyerSkuCode}');

      // Show bottom sheet cek tagihan
      print('🚀 [PBB] Showing CekTagihan bottom sheet...');
      final billData = await CekTagihanPascabayar.showCekTagihan(
        context: context,
        productName: _selectedProduct!.productName,
        brand: _selectedProduct!.brand,
        buyerSkuCode: _selectedProduct!.buyerSkuCode,
        adminUserId: adminUserId,
        cachedCustomerNo: _customerIdController.text,
      );

      print('📥 [PBB] Bill Data Response: $billData');

      if (billData != null) {
        print('✅ [PBB] Bill data received from bottom sheet');
      } else {
        print('❌ [PBB] Bill data is null (user might have cancelled)');
      }
    } catch (e) {
      print('❌ [PBB] Error in _cekTagihan: $e');
      if (mounted) {
        _showSnackbar('Terjadi kesalahan: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PBB',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(primaryColor),
            const SizedBox(height: 16),

            // Provider selection card
            _buildProviderCard(primaryColor),
            const SizedBox(height: 16),

            // Customer ID input
            _buildCustomerIdInput(primaryColor),
            const SizedBox(height: 24),

            // Cek Tagihan button
            _buildCekTagihanButton(primaryColor),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pajak Bumi Bangunan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bayar pajak bumi dan bangunan',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (_availableBrands.isNotEmpty) {
            _showBrandSelectionDialog();
          } else {
            _showSnackbar('Memuat data wilayah...', Colors.orange);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_city, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wilayah PBB',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedBrand.isEmpty ? 'Pilih wilayah' : _selectedBrand,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
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
          const Text(
            'Nomor Objek Pajak (NOP)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerIdController,
            keyboardType: TextInputType.text,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(
              hintText: 'Masukkan NOP',
              prefixIcon: Icon(Icons.home_work, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickContact,
                  icon: const Icon(Icons.contacts, size: 18),
                  label: const Text('Kontak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan Barcode'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCekTagihanButton(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _cekTagihan,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Cek Tagihan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Barcode Scanner Screen
class _BarcodeScannerScreen extends StatefulWidget {
  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: appConfig.primaryColor,
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? value = barcodes.first.rawValue;
            if (value != null && value.isNotEmpty) {
              setState(() {
                isScanned = true;
              });
              Navigator.pop(context, value);
            }
          }
        },
      ),
    );
  }
}
