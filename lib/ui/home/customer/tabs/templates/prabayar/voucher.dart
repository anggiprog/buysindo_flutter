import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedBrand = "";
  TabController? _tabController;
  int _filterStatus = 0;

  List<ProductPrabayar> _allProducts = [];
  List<String> _dynamicTypes = [];
  List<String> _availableBrands = [];

  bool _isLoading = false;
  bool _hasShownBrandDialog = false;
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
    _phoneController.dispose();
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
          _allProducts = products
              .where((p) => p.category.toUpperCase() == "VOUCHER")
              .toList();

          _availableBrands = _allProducts.map((p) => p.brand).toSet().toList()
            ..sort();

          _isLoading = false;
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

        if (forceRefresh && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Produk diperbarui (${_allProducts.length} produk)',
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearProductsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('products_cache');
      await prefs.remove('products_cache_timestamp');
    } catch (e) {
      // Silent fail
    }
  }

  void _showBrandSelectionDialog() {
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_giftcard, size: 48, color: primaryColor),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Brand Voucher',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih provider untuk melihat voucher',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableBrands.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final brand = _availableBrands[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedBrand = brand;
                            _setupTabController();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brand,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Voucher $brand',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setupTabController() {
    final brandProducts = _allProducts
        .where((p) => p.brand == _selectedBrand)
        .toList();

    final types = brandProducts.map((p) => p.type).toSet().toList()..sort();

    _tabController?.dispose();
    _tabController = TabController(length: types.length, vsync: this);

    setState(() {
      _dynamicTypes = types;
    });
  }

  Future<void> _scanBarcode() async {
    try {
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

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _phoneController.text = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode terdeteksi: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? e.code}'),
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

  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();

        if (contact != null) {
          final phones = contact.phones;
          if (phones.isNotEmpty) {
            String phoneNumber = phones.first.number.replaceAll(
              RegExp(r'\D'),
              '',
            );

            if (phoneNumber.startsWith('62')) {
              phoneNumber = '0${phoneNumber.substring(2)}';
            } else if (phoneNumber.startsWith('+62')) {
              phoneNumber = '0${phoneNumber.substring(3)}';
            }

            if (mounted) {
              setState(() {
                _phoneController.text = phoneNumber;
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voucher',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            tooltip: 'Refresh',
            onPressed: () => _loadData(forceRefresh: true),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: primaryColor),
            tooltip: 'Info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informasi Voucher'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cara Beli Voucher:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Masukkan Nomor HP'),
                        Text('2. Pilih Brand Voucher'),
                        Text('3. Pilih Nominal Voucher'),
                        Text('4. Klik Beli untuk melakukan transaksi'),
                        Text('5. Kode voucher akan dikirim via SMS/Email'),
                        SizedBox(height: 12),
                        Text(
                          'Voucher dapat digunakan untuk isi ulang pulsa atau paket data.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat voucher...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : _allProducts.isEmpty
          ? _buildEmptyState(primaryColor)
          : RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              color: primaryColor,
              child: Column(
                children: [
                  _buildPhoneInput(primaryColor),
                  if (_selectedBrand.isNotEmpty)
                    _buildBrandSelector(primaryColor),
                  if (_selectedBrand.isNotEmpty &&
                      _dynamicTypes.isNotEmpty) ...[
                    _buildTabBar(primaryColor),
                    Expanded(child: _buildTabBarView(primaryColor)),
                  ] else if (_selectedBrand.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('Pilih Brand Voucher terlebih dahulu'),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(child: Text('Tidak ada produk tersedia')),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Voucher',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voucher belum tersedia saat ini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadData(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nomor HP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nomor HP',
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _pickContact,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.contacts,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _scanBarcode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSelector(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.card_giftcard, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand Terpilih',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedBrand,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showBrandSelectionDialog,
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    if (_tabController == null || _dynamicTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: _dynamicTypes.length > 3,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: _dynamicTypes
            .map(
              (type) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer, size: 16),
                    const SizedBox(width: 6),
                    Text(type),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabBarView(Color primaryColor) {
    if (_tabController == null || _dynamicTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: _dynamicTypes.map((type) {
        final typeProducts = _allProducts
            .where((p) => p.brand == _selectedBrand && p.type == type)
            .toList();
        return Column(
          children: [
            _buildSearchAndFilterBar(primaryColor),
            Expanded(child: _buildProductGrid(typeProducts, primaryColor)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchAndFilterBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari voucher...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<int>(
              icon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.tune, color: primaryColor, size: 22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => setState(() => _filterStatus = value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 12),
                      Text('Normal'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 20),
                      SizedBox(width: 12),
                      Text('Termurah'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 20),
                      SizedBox(width: 12),
                      Text('Termahal'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductPrabayar> products, Color primaryColor) {
    var filteredProducts = products;
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredProducts = products
          .where(
            (p) =>
                p.productName.toLowerCase().contains(searchQuery) ||
                p.description.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    if (_filterStatus == 1) {
      filteredProducts.sort((a, b) => a.totalHarga.compareTo(b.totalHarga));
    } else if (_filterStatus == 2) {
      filteredProducts.sort((a, b) => b.totalHarga.compareTo(a.totalHarga));
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Voucher Tidak Ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product, primaryColor);
      },
    );
  }

  Widget _buildProductCard(ProductPrabayar product, Color primaryColor) {
    final hasDiscount = product.produkDiskon > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPulsaPage(
                  product: product,
                  phone: _phoneController.text,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        product.iconUrl != null && product.iconUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              product.iconUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.card_giftcard,
                                color: primaryColor,
                                size: 36,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.card_giftcard,
                            color: primaryColor,
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.type,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${product.produkDiskon.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (hasDiscount) const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rp ${product.totalHarga.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
          MobileScanner(controller: cameraController, onDetect: _handleBarcode),
          CustomPaint(painter: _ScannerOverlayPainter(), child: Container()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    children: [
                      ..._buildCornerBrackets(primaryColor),
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
