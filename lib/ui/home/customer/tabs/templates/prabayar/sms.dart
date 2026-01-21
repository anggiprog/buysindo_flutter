import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../../core/app_config.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class SmsPage extends StatefulWidget {
  const SmsPage({super.key});

  @override
  State<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _operatorName = "";
  TabController? _tabController;
  int _filterStatus = 0; // 0: Normal, 1: Termurah, 2: Termahal

  List<ProductPrabayar> _allProducts = [];
  List<String> _dynamicTypes = [];
  bool _isLoading = false;

  String _lastPrefix = "";
  bool _isDetecting = false;

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _pickContact() async {
    try {
      var status = await Permission.contacts.request();
      if (status.isGranted) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null && contact.phones.isNotEmpty) {
          String phone = contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
          if (phone.startsWith('62')) {
            phone = '0${phone.substring(2)}';
          } else if (phone.startsWith('8')) {
            phone = '0$phone';
          }
          setState(() => _phoneController.text = phone);
          _checkOperator(phone);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? token = await SessionManager.getToken();
      final products = await _apiService.getProducts(token, forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          // Filter: Hanya ambil kategori SMS & TELPON
          _allProducts = products
              .where((p) => p.category.toUpperCase().contains("SMS"))
              .toList();
          _isLoading = false;
        });
        if (_operatorName.isNotEmpty) _updateDynamicTabs();

        // Tampilkan notifikasi jika refresh
        if (forceRefresh && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produk diperbarui (${_allProducts.length} produk)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memperbarui produk'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _checkOperator(String value) async {
    if (value.length < 4) {
      setState(() {
        _operatorName = "";
        _lastPrefix = "";
        _dynamicTypes = [];
      });
      return;
    }

    String currentPrefix = value.substring(0, 4);
    if (currentPrefix != _lastPrefix) {
      _lastPrefix = currentPrefix;
      setState(() => _isDetecting = true);

      try {
        final String? token = await SessionManager.getToken();
        final brand = await _apiService.detectBrand(value, token!);

        if (brand != null && mounted) {
          setState(() => _operatorName = brand.toUpperCase());
          _updateDynamicTabs();
        }
      } catch (e) {
        // Handle error silently
      } finally {
        if (mounted) setState(() => _isDetecting = false);
      }
    }
  }

  void _updateDynamicTabs() {
    if (_operatorName.isEmpty) return;

    // Filter berdasarkan Brand dan Kategori SMS
    final filteredByBrand = _allProducts.where((p) {
      return p.brand.toUpperCase() == _operatorName;
    }).toList();

    final types = filteredByBrand.map((p) => p.type).toSet().toList();

    if (mounted) {
      setState(() {
        _dynamicTypes = types;
        _tabController?.dispose();
        if (_dynamicTypes.isNotEmpty) {
          _tabController = TabController(length: _dynamicTypes.length, vsync: this);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          "Paket SMS & Telpon",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        color: primaryColor,
        child: Column(
          children: [
            _buildHeaderInput(primaryColor),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_operatorName.isNotEmpty && _dynamicTypes.isNotEmpty) ...[
              _buildSearchAndFilterBar(primaryColor),
              if (_tabController != null)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                    tabs: _dynamicTypes.map((t) => Tab(text: t.toUpperCase())).toList(),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _dynamicTypes.map((type) => _buildProductList(type)).toList(),
                ),
              ),
            ] else
              Expanded(child: _buildEmptyState(primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInput(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nomor Handphone",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: _checkOperator,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Contoh: 08123456789",
                prefixIcon: Icon(Icons.phone_android, color: primaryColor),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_phoneController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                        onPressed: () {
                          _phoneController.clear();
                          setState(() {
                            _operatorName = "";
                            _dynamicTypes = [];
                          });
                        },
                      ),
                    _buildPhoneSuffix(primaryColor),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSuffix(Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isDetecting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (_operatorName.isNotEmpty && !_isDetecting)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              _operatorName,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        IconButton(
          icon: Icon(Icons.contact_page_rounded, color: primaryColor, size: 26),
          onPressed: _pickContact,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Cari paket SMS...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // REFRESH BUTTON
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: primaryColor, size: 22),
              onPressed: () async {
                await _loadData(forceRefresh: true);
              },
              tooltip: 'Refresh Produk',
            ),
          ),
          const SizedBox(width: 8),
          // FILTER BUTTON
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _filterStatus != 0 ? primaryColor : Colors.grey,
              ),
              onPressed: () => setState(() => _filterStatus = (_filterStatus + 1) % 3),
              tooltip: _filterStatus == 0
                  ? 'Urutkan: Normal'
                  : _filterStatus == 1
                  ? 'Urutkan: Termurah'
                  : 'Urutkan: Termahal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(String type) {
    // FILTER AKHIR: Berdasarkan Brand, Category (SMS), dan Type (Tab)
    List<ProductPrabayar> filtered = _allProducts.where((p) {
      return p.brand.toUpperCase() == _operatorName &&
          p.type == type &&
          p.productName.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    if (_filterStatus == 1) filtered.sort((a, b) => a.totalHarga.compareTo(b.totalHarga));
    if (_filterStatus == 2) filtered.sort((a, b) => b.totalHarga.compareTo(a.totalHarga));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildProductCard(filtered[index]),
    );
  }

  Widget _buildProductCard(ProductPrabayar product) {
    final bool isAvailable = product.status != 0;

    // Hitung harga asli dari totalHarga dikurangi diskon
    final int discountAmount = product.produkDiskon;
    final int originalPrice = product.totalHarga + discountAmount;
    final String strikePrice =
        "Rp ${originalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}";
    final String salePrice =
        "Rp ${product.totalHarga.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: !isAvailable
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailPulsaPage(product: product, phone: _phoneController.text),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ICON PRODUK
              if (product.iconUrl != null && product.iconUrl!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.iconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: Icon(Icons.textsms, color: appConfig.primaryColor),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // STATUS BADGE (Tetap di kanan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.error,
                      size: 10,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isAvailable ? "Tersedia" : "Gangguan",
                      style: TextStyle(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LimitedBox(
                maxWidth: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // HARGA ASLI CORET (jika ada diskon)
                    if (discountAmount > 0)
                      Text(
                        strikePrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (discountAmount > 0) const SizedBox(height: 2),
                    // HARGA DISKON (HARGA JUAL)
                    Text(
                      salePrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: appConfig.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        "Hemat Rp ${discountAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.textsms, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _operatorName.isEmpty
                ? "Masukkan nomor untuk cek produk"
                : "Produk SMS tidak ditemukan",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
