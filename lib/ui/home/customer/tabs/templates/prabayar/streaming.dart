import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../../../core/app_config.dart';
import '../../../../../../features/customer/data/models/product_prabayar_model.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/network/session_manager.dart';
import '../detail_pulsa_page.dart';

class StreamingPage extends StatefulWidget {
  const StreamingPage({super.key});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage>
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
              .where((p) => p.category.toUpperCase() == "STREAMING")
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
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allProducts = [];
          _availableBrands = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat produk: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _loadData(forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearProductsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');
    } catch (e) {
      // Handle error
    }
  }

  void _showBrandSelectionDialog() {
    final primaryColor = appConfig.primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        Icons.play_circle_outline,
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
                            'Pilih Layanan Streaming',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Pilih Layanan Streaming platform streaming',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableBrands.length,
                  itemBuilder: (context, index) {
                    final brand = _availableBrands[index];

                    // Get icon_url from first product of this brand
                    String? iconUrl;
                    try {
                      if (_allProducts.isNotEmpty) {
                        final brandProduct = _allProducts.firstWhere(
                          (p) => p.brand == brand,
                          orElse: () => _allProducts.first,
                        );
                        iconUrl = brandProduct.iconUrl;
                      }
                    } catch (e) {
                      iconUrl = null;
                    }

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
                            _selectBrand(brand);
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
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: iconUrl != null && iconUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            iconUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons
                                                        .play_circle_outline_rounded,
                                                    color: primaryColor,
                                                    size: 32,
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(
                                          Icons.play_circle_outline_rounded,
                                          color: primaryColor,
                                          size: 32,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    brand,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 18,
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
      ),
    );
  }

  void _selectBrand(String brand) {
    setState(() {
      _selectedBrand = brand;
      _phoneController.clear();
      _updateDynamicTabs();
    });
  }

  void _updateDynamicTabs() {
    if (_selectedBrand.isEmpty) return;

    try {
      final filteredByBrand = _allProducts.where((p) {
        return p.brand.toUpperCase() == _selectedBrand.toUpperCase();
      }).toList();

      final types = filteredByBrand.map((p) => p.type).toSet().toList();

      if (mounted) {
        setState(() {
          _dynamicTypes = types;
          _tabController?.dispose();
          _tabController = null;
          if (_dynamicTypes.isNotEmpty) {
            _tabController = TabController(
              length: _dynamicTypes.length,
              vsync: this,
            );
          }
        });
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        setState(() {
          _dynamicTypes = [];
          _tabController?.dispose();
          _tabController = null;
        });
      }
    }
  }

  Future<void> _pickContact() async {
    try {
      // Request contacts permission
      final status = await Permission.contacts.request();

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin akses kontak diperlukan'),
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
              title: const Text('Izin Kontak Diperlukan'),
              content: const Text(
                'Aplikasi memerlukan akses kontak untuk memilih nomor HP. '
                'Silakan aktifkan izin kontak di pengaturan aplikasi.',
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

      // Pick contact
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // Fetch full contact details including phone numbers
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null && fullContact.phones.isNotEmpty) {
          // Get first phone number and clean it
          String phoneNumber = fullContact.phones.first.number;

          // Remove all non-digit characters
          phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

          // Handle Indonesian phone number format
          if (phoneNumber.startsWith('62')) {
            phoneNumber = '0${phoneNumber.substring(2)}';
          } else if (phoneNumber.startsWith('+62')) {
            phoneNumber = '0${phoneNumber.substring(3)}';
          }

          if (mounted) {
            setState(() {
              _phoneController.text = phoneNumber;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Kontak dipilih: ${fullContact.displayName}\nNomor: $phoneNumber',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kontak tidak memiliki nomor telepon'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mengambil kontak: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kontak: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
            content: Text('Nomor HP: $result'),
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
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Nomor HP terlebih dahulu'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPulsaPage(product: product, phone: _phoneController.text),
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

  List<ProductPrabayar> _getFilteredProducts(String type) {
    var filtered = _allProducts.where((p) {
      return p.brand.toUpperCase() == _selectedBrand.toUpperCase() &&
          p.type == type;
    }).toList();

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.productName.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            p.description.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
      }).toList();
    }

    if (_filterStatus == 1) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_filterStatus == 2) {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          "Streaming",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: () => _loadData(forceRefresh: true),
          ),
        ],
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
              _buildPhoneNumberInput(primaryColor),
              _buildSearchAndFilterBar(primaryColor),
              if (_tabController != null && _dynamicTypes.isNotEmpty)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    key: ValueKey(_dynamicTypes.length),
                    isScrollable: true,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: _dynamicTypes
                        .map((t) => Tab(text: t.toUpperCase()))
                        .toList(),
                  ),
                ),
              if (_tabController != null && _dynamicTypes.isNotEmpty)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    key: ValueKey(_dynamicTypes.length),
                    children: _dynamicTypes
                        .map((type) => _buildProductList(type, primaryColor))
                        .toList(),
                  ),
                )
              else
                Expanded(child: _buildEmptyState(primaryColor)),
            ] else
              Expanded(child: _buildEmptyState(primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSelector(Color primaryColor) {
    if (_selectedBrand.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get icon_url from first product of selected brand
    String? iconUrl;
    try {
      if (_allProducts.isNotEmpty) {
        final brandProduct = _allProducts.firstWhere(
          (p) => p.brand == _selectedBrand,
          orElse: () => _allProducts.first,
        );
        iconUrl = brandProduct.iconUrl;
      }
    } catch (e) {
      iconUrl = null;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: iconUrl != null && iconUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      iconUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.play_circle_outline_rounded,
                          color: primaryColor,
                          size: 28,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.play_circle_outline_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Layanan Dipilih',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showBrandSelectionDialog,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Ganti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberInput(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor HP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Masukkan nomor tujuan',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 13,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: 08123456789',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              counterText: '',
              prefixIcon: InkWell(
                onTap: _pickContact,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.contacts, color: primaryColor, size: 20),
                ),
              ),
              suffixIcon: InkWell(
                onTap: _scanBarcode,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(12),
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
                  hintText: 'Cari paket streaming...',
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

  Widget _buildProductList(String type, Color primaryColor) {
    final products = _getFilteredProducts(type);

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada produk tersedia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kategori lain atau gunakan pencarian',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index], primaryColor);
      },
    );
  }

  Widget _buildProductCard(ProductPrabayar product, Color primaryColor) {
    final hasDiscount = product.produkDiskon > 0;
    final int originalPrice = product.totalHarga + product.produkDiskon;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleProductTap(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: product.iconUrl != null && product.iconUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            product.iconUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.play_circle_outline,
                                color: primaryColor,
                                size: 32,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.play_circle_outline,
                          color: primaryColor,
                          size: 32,
                        ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        'Rp ${originalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[600]!, Colors.green[500]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Rp ${product.totalHarga.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[700]!, Colors.orange[600]!],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.discount,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hemat ${_formatDiscount(product.produkDiskon)}',
                              style: const TextStyle(
                                fontSize: 10,
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
      ),
    );
  }

  Widget _buildEmptyStateBrand(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_circle_outline_outlined,
              size: 80,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pilih layanan streaming terlebih dahulu',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan Pilih Layanan Streaming platform streaming di atas',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada produk tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
