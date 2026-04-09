import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../../../../../core/app_config.dart';

/// Model untuk item harga produk (Digiflazz)
/// total_harga sudah termasuk (price + admin_fee + markup_admin - produk_diskon)
/// Untuk member: harga_jual_member = total_harga + markup_member
class HargaProduk {
  final String kode; // buyer_sku_code
  final String nama; // product_name
  final String kategori; // category
  final String brand;
  final String iconUrl;
  final int hargaModal; // price (harga dasar dari Digiflazz)
  final int adminFee; // admin_fee
  final int markupAdmin; // markup_admin (markup dari admin)
  final int produkDiskon; // produk_diskon
  final int totalHarga; // total_harga (harga jadi dari admin)
  final int markupMember; // markup member yang disimpan di tabel markup_member
  final int hargaJualMember; // total_harga + markup_member
  final int buyerProductStatus;
  final int sellerProductStatus;
  final String description;
  final String tipeProduk; // 'prabayar' atau 'pascabayar'

  HargaProduk({
    required this.kode,
    required this.nama,
    required this.kategori,
    required this.brand,
    required this.iconUrl,
    required this.hargaModal,
    required this.adminFee,
    required this.markupAdmin,
    required this.produkDiskon,
    required this.totalHarga,
    required this.markupMember,
    required this.hargaJualMember,
    required this.buyerProductStatus,
    required this.sellerProductStatus,
    required this.description,
    required this.tipeProduk,
  });

  factory HargaProduk.fromJson(
    Map<String, dynamic> json, {
    String tipeProduk = 'prabayar',
  }) {
    final totalHarga = _parseInt(json['total_harga']);
    final markupMember = _parseInt(json['markup_member']);
    final hargaJualMember = _parseInt(
      json['harga_jual_member'],
      defaultVal: totalHarga + markupMember,
    );

    return HargaProduk(
      kode: json['buyer_sku_code'] ?? '',
      nama: json['product_name'] ?? '',
      kategori: json['category'] ?? '',
      brand: json['brand'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      hargaModal: _parseInt(json['price']),
      adminFee: _parseInt(json['admin_fee']),
      markupAdmin: _parseInt(json['markup_admin']),
      produkDiskon: _parseInt(json['produk_diskon']),
      totalHarga: totalHarga,
      markupMember: markupMember,
      hargaJualMember: hargaJualMember,
      buyerProductStatus: _parseInt(
        json['buyer_product_status'],
        defaultVal: 1,
      ),
      sellerProductStatus: _parseInt(
        json['seller_product_status'],
        defaultVal: 1,
      ),
      description: json['description'] ?? json['desc'] ?? '',
      tipeProduk: tipeProduk,
    );
  }

  static int _parseInt(dynamic value, {int defaultVal = 0}) {
    if (value == null) return defaultVal;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    return int.tryParse(value.toString()) ?? defaultVal;
  }

  /// Cek apakah produk aktif (buyer & seller status = 1)
  bool get isActive => buyerProductStatus == 1 && sellerProductStatus == 1;
}

class DaftarHargaPage extends StatefulWidget {
  const DaftarHargaPage({Key? key}) : super(key: key);

  @override
  State<DaftarHargaPage> createState() => _DaftarHargaPageState();
}

class _DaftarHargaPageState extends State<DaftarHargaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Prabayar
  List<HargaProduk> _allPrabayar = [];
  List<HargaProduk> _filteredPrabayar = [];
  bool _isLoadingPrabayar = true;
  String? _errorPrabayar;

  // Pascabayar
  List<HargaProduk> _allPascabayar = [];
  List<HargaProduk> _filteredPascabayar = [];
  bool _isLoadingPascabayar = true;
  String? _errorPascabayar;

  // Ubah Harga - gabungan prabayar & pascabayar
  String _ubahHargaTipe = 'prabayar'; // toggle prabayar/pascabayar

  final TextEditingController _searchController = TextEditingController();
  String _selectedKategori = 'Semua';
  List<String> _kategoriListPrabayar = ['Semua'];
  List<String> _kategoriListPascabayar = ['Semua'];

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchAllData();
  }

  void _onTabChanged() {
    // Reset search dan filter saat pindah tab
    _searchController.clear();
    _selectedKategori = 'Semua';
    _applyFilter();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchPrabayar(), _fetchPascabayar()]);
  }

  Future<void> _fetchPrabayar() async {
    setState(() {
      _isLoadingPrabayar = true;
      _errorPrabayar = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorPrabayar = 'Token tidak ditemukan';
          _isLoadingPrabayar = false;
        });
        return;
      }

      final response = await ApiService.instance.getDaftarHarga(token);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        List<dynamic> data = [];
        if (responseData is Map && responseData['products'] != null) {
          data = responseData['products'] as List<dynamic>;
        } else if (responseData is List) {
          data = responseData;
        }
        _allPrabayar = data
            .map((e) => HargaProduk.fromJson(e, tipeProduk: 'prabayar'))
            .toList();

        // Extract unique categories
        final categories = _allPrabayar.map((e) => e.kategori).toSet().toList();
        categories.sort();
        _kategoriListPrabayar = ['Semua', ...categories];

        _applyFilter();
      } else {
        setState(() {
          _errorPrabayar = 'Gagal memuat data prabayar';
        });
      }
    } catch (e) {
      setState(() {
        _errorPrabayar = 'Error: $e';
      });
    }

    setState(() {
      _isLoadingPrabayar = false;
    });
  }

  Future<void> _fetchPascabayar() async {
    setState(() {
      _isLoadingPascabayar = true;
      _errorPascabayar = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _errorPascabayar = 'Token tidak ditemukan';
          _isLoadingPascabayar = false;
        });
        return;
      }

      final response = await ApiService.instance.getDaftarHargaPascabayar(
        token,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        List<dynamic> data = [];
        if (responseData is Map && responseData['products'] != null) {
          data = responseData['products'] as List<dynamic>;
        } else if (responseData is List) {
          data = responseData;
        }
        _allPascabayar = data
            .map((e) => HargaProduk.fromJson(e, tipeProduk: 'pascabayar'))
            .toList();

        // Extract unique categories
        final categories = _allPascabayar
            .map((e) => e.kategori)
            .toSet()
            .toList();
        categories.sort();
        _kategoriListPascabayar = ['Semua', ...categories];

        _applyFilter();
      } else {
        setState(() {
          _errorPascabayar = 'Gagal memuat data pascabayar';
        });
      }
    } catch (e) {
      setState(() {
        _errorPascabayar = 'Error: $e';
      });
    }

    setState(() {
      _isLoadingPascabayar = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Filter Prabayar
      _filteredPrabayar = _allPrabayar.where((produk) {
        final matchSearch =
            query.isEmpty ||
            produk.nama.toLowerCase().contains(query) ||
            produk.kode.toLowerCase().contains(query) ||
            produk.brand.toLowerCase().contains(query);
        final matchKategori =
            _selectedKategori == 'Semua' ||
            produk.kategori == _selectedKategori;
        return matchSearch && matchKategori;
      }).toList();

      // Filter Pascabayar
      _filteredPascabayar = _allPascabayar.where((produk) {
        final matchSearch =
            query.isEmpty ||
            produk.nama.toLowerCase().contains(query) ||
            produk.kode.toLowerCase().contains(query) ||
            produk.brand.toLowerCase().contains(query);
        final matchKategori =
            _selectedKategori == 'Semua' ||
            produk.kategori == _selectedKategori;
        return matchSearch && matchKategori;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Harga'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Prabayar', icon: Icon(Icons.phone_android, size: 20)),
            Tab(text: 'Pascabayar', icon: Icon(Icons.receipt_long, size: 20)),
            Tab(text: 'Ubah Harga', icon: Icon(Icons.edit, size: 20)),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPrabayarTab(primaryColor),
            _buildPascabayarTab(primaryColor),
            _buildUbahHargaTab(primaryColor),
          ],
        ),
      ),
    );
  }

  // ============ TAB PRABAYAR ============
  Widget _buildPrabayarTab(Color primaryColor) {
    if (_isLoadingPrabayar) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPrabayar != null) {
      return _buildErrorState(_errorPrabayar!, _fetchPrabayar);
    }

    return Column(
      children: [
        _buildSearchAndFilter(primaryColor, _kategoriListPrabayar),
        Expanded(
          child: _filteredPrabayar.isEmpty
              ? const Center(child: Text('Tidak ada produk prabayar ditemukan'))
              : RefreshIndicator(
                  onRefresh: _fetchPrabayar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredPrabayar.length,
                    itemBuilder: (context, index) {
                      return _buildProdukCard(_filteredPrabayar[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ============ TAB PASCABAYAR ============
  Widget _buildPascabayarTab(Color primaryColor) {
    if (_isLoadingPascabayar) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPascabayar != null) {
      return _buildErrorState(_errorPascabayar!, _fetchPascabayar);
    }

    return Column(
      children: [
        _buildSearchAndFilter(primaryColor, _kategoriListPascabayar),
        Expanded(
          child: _filteredPascabayar.isEmpty
              ? const Center(
                  child: Text('Tidak ada produk pascabayar ditemukan'),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPascabayar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredPascabayar.length,
                    itemBuilder: (context, index) {
                      return _buildProdukCard(_filteredPascabayar[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ============ TAB UBAH HARGA ============
  Widget _buildUbahHargaTab(Color primaryColor) {
    final isLoadingUbah = _ubahHargaTipe == 'prabayar'
        ? _isLoadingPrabayar
        : _isLoadingPascabayar;
    final errorUbah = _ubahHargaTipe == 'prabayar'
        ? _errorPrabayar
        : _errorPascabayar;
    final filteredList = _ubahHargaTipe == 'prabayar'
        ? _filteredPrabayar
        : _filteredPascabayar;
    final kategoriList = _ubahHargaTipe == 'prabayar'
        ? _kategoriListPrabayar
        : _kategoriListPascabayar;

    return Column(
      children: [
        // Toggle Prabayar / Pascabayar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _ubahHargaTipe = 'prabayar';
                      _selectedKategori = 'Semua';
                    });
                    _applyFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _ubahHargaTipe == 'prabayar'
                          ? primaryColor
                          : Colors.white,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      border: Border.all(color: primaryColor),
                    ),
                    child: Center(
                      child: Text(
                        'Prabayar',
                        style: TextStyle(
                          color: _ubahHargaTipe == 'prabayar'
                              ? Colors.white
                              : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _ubahHargaTipe = 'pascabayar';
                      _selectedKategori = 'Semua';
                    });
                    _applyFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _ubahHargaTipe == 'pascabayar'
                          ? primaryColor
                          : Colors.white,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                      border: Border.all(color: primaryColor),
                    ),
                    child: Center(
                      child: Text(
                        'Pascabayar',
                        style: TextStyle(
                          color: _ubahHargaTipe == 'pascabayar'
                              ? Colors.white
                              : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Button Markup Per Kategori
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showBulkMarkupDialog(primaryColor),
              icon: const Icon(Icons.category, size: 18),
              label: const Text('Markup Semua Produk Per Kategori'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Search & Filter
        _buildSearchAndFilter(primaryColor, kategoriList),
        // Content
        Expanded(
          child: isLoadingUbah
              ? const Center(child: CircularProgressIndicator())
              : errorUbah != null
              ? _buildErrorState(
                  errorUbah,
                  _ubahHargaTipe == 'prabayar'
                      ? _fetchPrabayar
                      : _fetchPascabayar,
                )
              : filteredList.isEmpty
              ? Center(
                  child: Text('Tidak ada produk $_ubahHargaTipe ditemukan'),
                )
              : RefreshIndicator(
                  onRefresh: _ubahHargaTipe == 'prabayar'
                      ? _fetchPrabayar
                      : _fetchPascabayar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildEditableCard(
                        filteredList[index],
                        primaryColor,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color primaryColor, List<String> kategoriList) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // Search box
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (_) => _applyFilter(),
          ),
          const SizedBox(height: 8),
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kategoriList.length,
              itemBuilder: (context, index) {
                final kategori = kategoriList[index];
                final isSelected = _selectedKategori == kategori;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedKategori = kategori;
                      });
                      _applyFilter();
                    },
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    backgroundColor: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukCard(HargaProduk produk) {
    final isActive = produk.isActive;
    final isPascabayar = produk.tipeProduk == 'pascabayar';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? (isPascabayar ? Colors.blue[50] : Colors.green[50])
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: produk.iconUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    produk.iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      isPascabayar ? Icons.receipt_long : Icons.phone_android,
                      color: isActive
                          ? (isPascabayar ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                  ),
                )
              : Icon(
                  isPascabayar ? Icons.receipt_long : Icons.phone_android,
                  color: isActive
                      ? (isPascabayar ? Colors.blue : Colors.green)
                      : Colors.grey,
                ),
        ),
        title: Text(
          produk.nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${produk.brand} - ${produk.kategori}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (produk.description.isNotEmpty)
              Text(
                produk.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            // Harga Jual Member (hidden for pascabayar)
            if (!isPascabayar)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Harga Jual: ',
                      style: TextStyle(fontSize: 11, color: Colors.green[700]),
                    ),
                    Text(
                      currencyFormat.format(produk.hargaJualMember),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            if (isPascabayar)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Cek tagihan untuk lihat harga',
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            if (!isPascabayar && produk.markupMember > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Markup: ${currencyFormat.format(produk.markupMember)}',
                    style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCard(HargaProduk produk, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: produk.isActive
                        ? Colors.green[50]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: produk.iconUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            produk.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              produk.tipeProduk == 'pascabayar'
                                  ? Icons.receipt_long
                                  : Icons.phone_android,
                              color: produk.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          produk.tipeProduk == 'pascabayar'
                              ? Icons.receipt_long
                              : Icons.phone_android,
                          color: produk.isActive ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produk.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${produk.brand} - ${produk.kategori}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditDialog(produk, primaryColor),
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: 'Ubah Markup',
                ),
              ],
            ),
            const Divider(height: 24),
            // Harga dari Admin (hidden for pascabayar)
            if (produk.tipeProduk != 'pascabayar')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Harga dari Admin',
                      style: TextStyle(color: Colors.blue),
                    ),
                    Text(
                      currencyFormat.format(produk.totalHarga),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            if (produk.tipeProduk == 'pascabayar')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Harga akan diketahui setelah cek tagihan',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Harga Jual Member (hidden for pascabayar)
            if (produk.tipeProduk != 'pascabayar')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga Jual Anda',
                          style: TextStyle(color: Colors.green),
                        ),
                        Text(
                          currencyFormat.format(produk.hargaJualMember),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (produk.markupMember > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Markup: ${currencyFormat.format(produk.markupMember)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            // Markup info for pascabayar
            if (produk.tipeProduk == 'pascabayar' && produk.markupMember > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Markup Anda',
                      style: TextStyle(color: Colors.orange),
                    ),
                    Text(
                      currencyFormat.format(produk.markupMember),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              produk.tipeProduk == 'pascabayar'
                  ? 'Tambahkan markup untuk keuntungan Anda'
                  : 'Tambahkan markup untuk menentukan harga jual Anda',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(HargaProduk produk, Color primaryColor) {
    final markupController = TextEditingController(
      text: produk.markupMember.toString(),
    );
    int previewHargaJual = produk.hargaJualMember;

    void updatePreview() {
      final markup = int.tryParse(markupController.text) ?? 0;
      previewHargaJual = produk.totalHarga + markup;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                produk.tipeProduk == 'pascabayar'
                    ? 'Ubah Markup'
                    : 'Ubah Harga Jual',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info
                    Text(
                      produk.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${produk.brand} - ${produk.kategori}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: produk.tipeProduk == 'pascabayar'
                            ? Colors.blue[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        produk.tipeProduk.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: produk.tipeProduk == 'pascabayar'
                              ? Colors.blue[800]
                              : Colors.green[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Harga dari admin (hidden for pascabayar)
                    if (produk.tipeProduk != 'pascabayar')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Harga dari Admin:'),
                            Text(
                              currencyFormat.format(produk.totalHarga),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (produk.tipeProduk == 'pascabayar')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Harga akan diketahui setelah cek tagihan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Markup field
                    TextField(
                      controller: markupController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Tambah Markup',
                        hintText: 'Contoh: 1000',
                        prefixIcon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.orange,
                        ),
                        border: const OutlineInputBorder(),
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) {
                        updatePreview();
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      produk.tipeProduk == 'pascabayar'
                          ? 'Markup akan ditambahkan ke tagihan'
                          : 'Markup akan ditambahkan ke harga dari admin',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    // Preview harga jual (different for pascabayar)
                    if (produk.tipeProduk != 'pascabayar')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Harga Jual Anda',
                              style: TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(previewHargaJual),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Keuntungan: ${currencyFormat.format(int.tryParse(markupController.text) ?? 0)}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (produk.tipeProduk == 'pascabayar')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Markup Anda',
                              style: TextStyle(color: Colors.orange),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(
                                int.tryParse(markupController.text) ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Akan ditambahkan ke tagihan',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveMarkup(
                      produk.kode,
                      int.tryParse(markupController.text) ?? 0,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMarkup(String buyerSkuCode, int markup) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        _showSnackBar('Token tidak ditemukan', isError: true);
        return;
      }

      final response = await ApiService.instance.simpanMarkupMember(
        token: token,
        buyerSkuCode: buyerSkuCode,
        markup: markup,
      );

      if (response.statusCode == 200) {
        _showSnackBar('Markup berhasil disimpan!');
        await _fetchAllData(); // Refresh both prabayar & pascabayar
      } else {
        _showSnackBar(
          response.data?['message'] ?? 'Gagal menyimpan markup',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  /// Get unique category list based on current ubah harga tipe
  List<String> _getUniqueCategories() {
    final products = _ubahHargaTipe == 'prabayar'
        ? _allPrabayar
        : _allPascabayar;
    final categories = products
        .map((p) => p.kategori)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Show dialog to bulk set markup for all products in a category
  void _showBulkMarkupDialog(Color primaryColor) {
    final categories = _getUniqueCategories();
    if (categories.isEmpty) {
      _showSnackBar('Tidak ada kategori tersedia', isError: true);
      return;
    }

    String? selectedCategory = categories.first;
    final markupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.category, color: primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Markup Per Kategori',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipe: ${_ubahHargaTipe == 'prabayar' ? 'Prabayar' : 'Pascabayar'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category dropdown
                    const Text(
                      'Pilih Kategori:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: categories.map((category) {
                            // Count products in this category
                            final products = _ubahHargaTipe == 'prabayar'
                                ? _allPrabayar
                                : _allPascabayar;
                            final count = products
                                .where((p) => p.kategori == category)
                                .length;
                            return DropdownMenuItem(
                              value: category,
                              child: Text('$category ($count produk)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Markup input
                    const Text(
                      'Markup (Rp):',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: markupController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Masukkan nilai markup',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Semua produk dalam kategori "$selectedCategory" akan diupdate dengan markup yang sama.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCategory == null) {
                      _showSnackBar(
                        'Pilih kategori terlebih dahulu',
                        isError: true,
                      );
                      return;
                    }
                    final markup = int.tryParse(markupController.text) ?? 0;
                    Navigator.pop(context);
                    await _saveBulkMarkupByCategory(selectedCategory!, markup);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Save bulk markup for all products in a category
  Future<void> _saveBulkMarkupByCategory(String category, int markup) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        _showSnackBar('Token tidak ditemukan', isError: true);
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService.instance.simpanMarkupMemberByCategory(
        token: token,
        category: category,
        markup: markup,
        tipe: _ubahHargaTipe,
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = response.data;
        final count = data?['data']?['products_count'] ?? 0;
        _showSnackBar('Markup berhasil diterapkan ke $count produk!');
        await _fetchAllData(); // Refresh both prabayar & pascabayar
      } else {
        _showSnackBar(
          response.data?['message'] ?? 'Gagal menyimpan markup',
          isError: true,
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

