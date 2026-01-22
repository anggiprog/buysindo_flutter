import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../../../../core/app_config.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class EMoneyPage extends StatefulWidget {
  const EMoneyPage({super.key});

  @override
  State<EMoneyPage> createState() => _EMoneyPageState();
}

class _EMoneyPageState extends State<EMoneyPage> with TickerProviderStateMixin {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedBrand = ""; // Selected E-Money Brand
  TabController? _tabController;
  int _filterStatus = 0; // 0: Normal, 1: Termurah, 2: Termahal

  List<ProductPrabayar> _allProducts = [];
  List<String> _dynamicTypes = [];
  List<String> _availableBrands = []; // List of available E-Money brands

  bool _isLoading = false;

  late ApiService _apiService;

  Future<void> _pickContact() async {
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        String phone = contact.phones.first.number.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        if (phone.startsWith('62')) {
          phone = '0${phone.substring(2)}';
        } else if (phone.startsWith('8')) {
          phone = '0$phone';
        }
        setState(() => _accountController.text = phone);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? token = await SessionManager.getToken();
      final products = await _apiService.getProducts(
        token,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          // Filter: Hanya ambil kategori E-MONEY
          _allProducts = products
              .where((p) => p.category.toUpperCase().contains("E-MONEY"))
              .toList();

          // Extract unique brands untuk E-Money
          _availableBrands = _allProducts.map((p) => p.brand).toSet().toList()
            ..sort();

          _isLoading = false;
        });

        // Tampilkan notifikasi jika refresh
        if (forceRefresh && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Produk diperbarui (${_allProducts.length} produk)',
              ),
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

  void _selectBrand(String brand) {
    setState(() {
      _selectedBrand = brand;
      _accountController.clear();
      _updateDynamicTabs();
    });
  }

  void _updateDynamicTabs() {
    if (_selectedBrand.isEmpty) return;

    // Filter berdasarkan Brand dan Kategori E-MONEY
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
    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nomor akun terlebih dahulu'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPulsaPage(product: product, phone: _accountController.text),
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _accountController.dispose();
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
          "Isi Ulang E-Money",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        color: primaryColor,
        child: Column(
          children: [
            _buildBrandSelector(primaryColor),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_selectedBrand.isEmpty) ...[
              Expanded(child: _buildEmptyStateBrand(primaryColor)),
            ] else if (_dynamicTypes.isNotEmpty) ...[
              _buildAccountNumberInput(primaryColor),
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
                    tabs: _dynamicTypes
                        .map((t) => Tab(text: t.toUpperCase()))
                        .toList(),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _dynamicTypes
                      .map((type) => _buildProductList(type, primaryColor))
                      .toList(),
                ),
              ),
            ] else
              Expanded(child: _buildEmptyState(primaryColor)),
          ],
        ),
      ),
    );
  }

  // BRAND SELECTOR - Horizontal Scroll atau Grid
  Widget _buildBrandSelector(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Provider E-Money",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
              height: 70,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_availableBrands.isEmpty)
            SizedBox(
              height: 70,
              child: Center(
                child: Text(
                  "Tidak ada produk E-Money tersedia",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableBrands.length,
                itemBuilder: (context, index) {
                  final brand = _availableBrands[index];
                  final isSelected = _selectedBrand == brand;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _selectBrand(brand),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getBrandIcon(brand),
                              color: isSelected ? primaryColor : Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              brand,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? primaryColor : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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

  // Account Number Input
  Widget _buildAccountNumberInput(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nomor Akun E-Money",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _accountController,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Contoh: 6281234567890",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.account_balance_wallet,
                  color: primaryColor,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_accountController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _accountController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.contact_phone,
                        color: primaryColor,
                        size: 22,
                      ),
                      onPressed: _pickContact,
                      tooltip: 'Pilih dari Kontak',
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 2,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Cari nominal...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _filterStatus != 0 ? primaryColor : Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _filterStatus = (_filterStatus + 1) % 3),
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

  Widget _buildProductList(String type, Color primaryColor) {
    // FILTER AKHIR: Berdasarkan Brand, Category (E-MONEY), dan Type (Tab)
    List<ProductPrabayar> filtered = _allProducts.where((p) {
      return p.brand.toUpperCase() == _selectedBrand.toUpperCase() &&
          p.type == type &&
          p.productName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
    }).toList();

    if (_filterStatus == 1)
      filtered.sort((a, b) => a.totalHarga.compareTo(b.totalHarga));
    if (_filterStatus == 2)
      filtered.sort((a, b) => b.totalHarga.compareTo(a.totalHarga));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              "Produk tidak ditemukan",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _buildProductCard(filtered[index], primaryColor),
    );
  }

  Widget _buildProductCard(ProductPrabayar product, Color primaryColor) {
    final bool isAvailable = product.status != 0;

    final int discountAmount = product.produkDiskon;
    final int originalPrice = product.totalHarga + discountAmount;
    final String strikePrice =
        "Rp ${originalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}";
    final String salePrice =
        "Rp ${product.totalHarga.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}";

    return GestureDetector(
      onTap: () => _handleProductTap(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: !isAvailable ? null : () => _handleProductTap(product),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: primaryColor,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description.length > 20
                            ? "${product.description.substring(0, 17)}..."
                            : product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price
                    if (discountAmount > 0)
                      Text(
                        strikePrice,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      salePrice,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateBrand(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 70,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Pilih provider E-Money untuk memulai",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 70,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Produk E-Money tidak tersedia",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData _getBrandIcon(String brand) {
    switch (brand.toUpperCase()) {
      case "OVO":
        return Icons.account_balance_wallet;
      case "GOPAY":
        return Icons.account_balance_wallet;
      case "DANA":
        return Icons.account_balance_wallet;
      case "LINKAJA":
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
