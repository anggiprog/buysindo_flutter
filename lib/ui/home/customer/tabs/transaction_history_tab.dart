import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as json_convert;
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../features/customer/data/models/transaction_detail_model.dart';
import '../../../../features/customer/data/models/transaction_pascabayar_model.dart';
import '../../../../features/customer/data/models/transaction_mutasi_model.dart';
import 'templates/transaction_detail_page.dart';
import 'templates/transaction_pascabayar_detail_page.dart';
import 'templates/transaction_mutasi_detail_page.dart';

class TransactionHistoryTab extends StatefulWidget {
  const TransactionHistoryTab({super.key});

  @override
  State<TransactionHistoryTab> createState() => _TransactionHistoryTabState();
}

class _TransactionHistoryTabState extends State<TransactionHistoryTab>
    with SingleTickerProviderStateMixin {
  String searchQuery = "";
  String selectedFilter = "Semua";
  final List<String> filters = ["Semua", "Sukses", "Pending", "Gagal"];

  late ApiService _apiService;
  late TabController _tabController;

  List<TransactionDetail> _allTransactions = [];
  List<TransactionDetail> _filteredTransactions = [];

  // Pascabayar transactions
  List<TransactionPascabayar> _allPascabayarTransactions = [];
  List<TransactionPascabayar> _filteredPascabayarTransactions = [];

  // Mutasi transactions
  List<TransactionMutasi> _allMutasiTransactions = [];
  List<TransactionMutasi> _filteredMutasiTransactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  // SharedPreferences cache keys
  static const String _cacheKey = 'transaction_history_cache';
  static const String _cacheTimestampKey = 'transaction_history_timestamp';
  static const String _cachePascabayarKey = 'transaction_pascabayar_cache';
  static const String _cachePascabayarTimestampKey =
      'transaction_pascabayar_timestamp';
  static const String _cacheMutasiKey = 'transaction_mutasi_cache';
  static const String _cacheMutasiTimestampKey = 'transaction_mutasi_timestamp';
  static const int _cacheValidityMinutes = 30;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          searchQuery = "";
          selectedFilter = "Semua";
        });
        // Load data for current tab
        if (_tabController.index == 0) {
          _loadTransactionHistory();
        } else if (_tabController.index == 1) {
          _loadPascabayarHistory();
        } else if (_tabController.index == 2) {
          _loadMutasiHistory();
        }
      }
    });
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Riwayat Transaksi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: appConfig.textColor,
          ),
        ),
        backgroundColor: appConfig.primaryColor,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: appConfig.textColor,
          indicatorWeight: 3,
          labelColor: appConfig.textColor,
          unselectedLabelColor: appConfig.textColor.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: "Prabayar"),
            Tab(text: "Pascabayar"),
            Tab(text: "Mutasi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrabayarTab(),
          _buildPascabayarTab(),
          _buildMutasiTab(),
        ],
      ),
    );
  }

  Widget _buildPrabayarTab() {
    return _isLoading && _filteredTransactions.isEmpty
        ? _buildLoadingState()
        : _errorMessage != null && _filteredTransactions.isEmpty
        ? _buildErrorState()
        : Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadTransactionHistory(forceRefresh: true);
                        },
                        color: appConfig.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final item = _filteredTransactions[index];
                            return _buildTransactionCard(item);
                          },
                        ),
                      ),
              ),
            ],
          );
  }

  Widget _buildPascabayarTab() {
    return _isLoading && _filteredPascabayarTransactions.isEmpty
        ? _buildLoadingState()
        : _errorMessage != null && _filteredPascabayarTransactions.isEmpty
        ? _buildErrorState()
        : Column(
            children: [
              _buildSearchAndFilterPascabayar(),
              Expanded(
                child: _filteredPascabayarTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadPascabayarHistory(forceRefresh: true);
                        },
                        color: appConfig.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _filteredPascabayarTransactions.length,
                          itemBuilder: (context, index) {
                            final item = _filteredPascabayarTransactions[index];
                            return _buildPascabayarCard(item);
                          },
                        ),
                      ),
              ),
            ],
          );
  }

  Widget _buildMutasiTab() {
    return _isLoading && _filteredMutasiTransactions.isEmpty
        ? _buildLoadingState()
        : _errorMessage != null && _filteredMutasiTransactions.isEmpty
        ? _buildErrorState()
        : Column(
            children: [
              _buildSearchAndFilterMutasi(),
              Expanded(
                child: _filteredMutasiTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadMutasiHistory(forceRefresh: true);
                        },
                        color: appConfig.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _filteredMutasiTransactions.length,
                          itemBuilder: (context, index) {
                            final item = _filteredMutasiTransactions[index];
                            return _buildMutasiCard(item);
                          },
                        ),
                      ),
              ),
            ],
          );
  }

  // ======================== LOADING & ERROR STATES ========================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(appConfig.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat riwayat transaksi...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat transaksi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_tabController.index == 0) {
                _loadTransactionHistory(forceRefresh: true);
              } else if (_tabController.index == 1) {
                _loadPascabayarHistory(forceRefresh: true);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'Semua'
                ? 'Belum ada riwayat transaksi'
                : 'Tidak ada transaksi dengan status "$selectedFilter"',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ======================== DATA LOADING & FILTERING ========================

  Future<void> _loadTransactionHistory({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = !forceRefresh;
        _errorMessage = null;
      });

      // 1. Try to load from cache first if not forcing refresh
      if (!forceRefresh && await _loadFromCache()) {
        _applyFilters();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Get token from session
      final String? token = await SessionManager.getToken();
      if (token == null) {
        _setError('Token tidak ditemukan');
        return;
      }

      debugPrint('🔐 Token: ${token.substring(0, 20)}...');

      // 3. Fetch from API
      final response = await _apiService.getTransactionDetailPrabayar(token);

      debugPrint('🔍 API Response Status Code: ${response.statusCode}');
      debugPrint('🔍 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check both 'success' string and true boolean (API can return either)
        final bool isSuccess =
            (data['status'] == 'success' ||
            data['status'] == 'Sukses' ||
            data['status'] == true);

        debugPrint(
          '🔍 Status Check: ${data['status']} -> isSuccess: $isSuccess',
        );

        if (isSuccess) {
          // Parse response
          final transactionData = data['data'] as List?;

          debugPrint(
            '🔍 Transaction Data Length: ${transactionData?.length ?? 0}',
          );

          if (transactionData != null) {
            if (transactionData.isNotEmpty) {
              _allTransactions = transactionData
                  .map(
                    (item) => TransactionDetail.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();

              debugPrint(
                '✅ Loaded ${_allTransactions.length} transactions from API',
              );

              // Sort by date (newest first)
              _allTransactions.sort(
                (a, b) => b.tanggalTransaksi.compareTo(a.tanggalTransaksi),
              );

              // 4. Fetch store name and attach to transactions
              try {
                final storeResponse = await _apiService.getUserStore(token);
                debugPrint(
                  '🏪 Store Response Status: ${storeResponse.statusCode}',
                );
                debugPrint('🏪 Store Response Data: ${storeResponse.data}');

                if (storeResponse.statusCode == 200) {
                  final storeData = storeResponse.data;

                  // Extract nama_toko from response
                  String storeName = '';
                  if (storeData is Map) {
                    storeName = storeData['nama_toko']?.toString() ?? '';
                  }

                  debugPrint(
                    '🏪 Extracted store name: "$storeName" (type: ${storeName.runtimeType})',
                  );

                  if (storeName.isNotEmpty) {
                    // Attach store name to all transactions
                    for (var i = 0; i < _allTransactions.length; i++) {
                      final transaction = _allTransactions[i];
                      _allTransactions[i] = TransactionDetail(
                        id: transaction.id,
                        userId: transaction.userId,
                        refId: transaction.refId,
                        buyerSkuCode: transaction.buyerSkuCode,
                        productName: transaction.productName,
                        nomorHp: transaction.nomorHp,
                        sn: transaction.sn,
                        totalPrice: transaction.totalPrice,
                        diskon: transaction.diskon,
                        paymentType: transaction.paymentType,
                        status: transaction.status,
                        tanggalTransaksi: transaction.tanggalTransaksi,
                        namaToko: storeName,
                      );
                    }
                    debugPrint(
                      '✅ Attached store name to ${_allTransactions.length} transactions',
                    );
                  } else {
                    debugPrint('⚠️ Store name is empty!');
                  }
                } else {
                  debugPrint(
                    '⚠️ Store API returned status: ${storeResponse.statusCode}',
                  );
                }
              } catch (e) {
                debugPrint('⚠️ Error fetching store name: $e');
                debugPrint('⚠️ Stack trace: ${StackTrace.current}');
              }

              // Save to cache
              await _saveToCache();
            } else {
              debugPrint('⚠️ Empty transaction list');
              _allTransactions = [];
            }

            // Apply filters
            _applyFilters();
          } else {
            debugPrint('⚠️ Transaction data is null');
            _allTransactions = [];
            _applyFilters();
          }
        } else {
          _setError('Status response bukan success: ${data['status']}');
        }
      } else {
        _setError('Gagal mengambil data (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
      _setError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;

      if (cachedJson == null) return false;

      // Check if cache is still valid
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > (_cacheValidityMinutes * 60 * 1000)) {
        return false;
      }

      // Parse cached data
      final List<dynamic> decodedList = json_convert.json.decode(cachedJson);
      _allTransactions = decodedList
          .map(
            (item) => TransactionDetail.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      debugPrint('✅ Loaded transaction history from cache');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error loading from cache: $e');
      return false;
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _allTransactions
          .map(
            (t) => {
              'id': t.id,
              'user_id': t.userId,
              'ref_id': t.refId,
              'buyer_sku_code': t.buyerSkuCode,
              'product_name': t.productName,
              'nomor_hp': t.nomorHp,
              'sn': t.sn,
              'total_price': t.totalPrice,
              'diskon': t.diskon,
              'payment_type': t.paymentType,
              'status': t.status,
              'tanggal_transaksi': t.tanggalTransaksi,
              'nama_toko': t.namaToko,
            },
          )
          .toList();

      await prefs.setString(_cacheKey, json_convert.json.encode(jsonList));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('💾 Transaction history saved to cache');
    } catch (e) {
      debugPrint('⚠️ Error saving to cache: $e');
    }
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((transaction) {
      // Filter by status
      bool statusMatch =
          selectedFilter == 'Semua' ||
          transaction.status.toUpperCase() == selectedFilter.toUpperCase();

      // Filter by search query
      bool searchMatch =
          searchQuery.isEmpty ||
          transaction.refId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          transaction.nomorHp.contains(searchQuery) ||
          transaction.productName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      return statusMatch && searchMatch;
    }).toList();
  }

  void _applyPascabayarFilters() {
    _filteredPascabayarTransactions = _allPascabayarTransactions.where((
      transaction,
    ) {
      // Filter by status
      bool statusMatch =
          selectedFilter == 'Semua' ||
          transaction.status.toUpperCase() == selectedFilter.toUpperCase();

      // Filter by search query
      bool searchMatch =
          searchQuery.isEmpty ||
          transaction.refId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          transaction.customerNo.contains(searchQuery) ||
          transaction.customerName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          transaction.productName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      return statusMatch && searchMatch;
    }).toList();
  }

  // ======================== PASCABAYAR DATA LOADING ========================

  Future<void> _loadPascabayarHistory({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = !forceRefresh;
        _errorMessage = null;
      });

      // 1. Try to load from cache first if not forcing refresh
      if (!forceRefresh && await _loadPascabayarFromCache()) {
        _applyPascabayarFilters();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Get token from session
      final String? token = await SessionManager.getToken();
      if (token == null) {
        _setError('Token tidak ditemukan');
        return;
      }

      debugPrint('🔐 Token Pascabayar: ${token.substring(0, 20)}...');

      // 3. Fetch from API
      final response = await _apiService.getTransactionDetailPascabayar(token);

      debugPrint(
        '🔍 Pascabayar API Response Status Code: ${response.statusCode}',
      );
      debugPrint('🔍 Pascabayar API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check both 'success' string and true boolean (API can return either)
        final bool isSuccess =
            (data['status'] == 'success' ||
            data['status'] == 'Sukses' ||
            data['status'] == true);

        debugPrint(
          '🔍 Status Check: ${data['status']} -> isSuccess: $isSuccess',
        );

        if (isSuccess) {
          // Parse response
          final transactionData = data['data'] as List?;

          debugPrint(
            '🔍 Pascabayar Transaction Data Length: ${transactionData?.length ?? 0}',
          );

          if (transactionData != null) {
            if (transactionData.isNotEmpty) {
              _allPascabayarTransactions = transactionData
                  .map(
                    (item) => TransactionPascabayar.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();

              debugPrint(
                '✅ Loaded ${_allPascabayarTransactions.length} Pascabayar transactions from API',
              );

              // Sort by date (newest first)
              _allPascabayarTransactions.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );

              // 4. Fetch store name and attach to transactions
              try {
                final storeResponse = await _apiService.getUserStore(token);
                debugPrint(
                  '🏪 Store Response Status (Pascabayar): ${storeResponse.statusCode}',
                );
                debugPrint(
                  '🏪 Store Response Data (Pascabayar): ${storeResponse.data}',
                );

                if (storeResponse.statusCode == 200) {
                  final storeData = storeResponse.data;

                  // Extract nama_toko from response
                  String storeName = '';
                  if (storeData is Map) {
                    storeName = storeData['nama_toko']?.toString() ?? '';
                  }

                  debugPrint(
                    '🏪 Extracted store name (Pascabayar): "$storeName" (type: ${storeName.runtimeType})',
                  );

                  if (storeName.isNotEmpty) {
                    // Attach store name to all transactions
                    for (
                      var i = 0;
                      i < _allPascabayarTransactions.length;
                      i++
                    ) {
                      final transaction = _allPascabayarTransactions[i];
                      _allPascabayarTransactions[i] = TransactionPascabayar(
                        id: transaction.id,
                        userId: transaction.userId,
                        refId: transaction.refId,
                        brand: transaction.brand,
                        buyerSkuCode: transaction.buyerSkuCode,
                        customerNo: transaction.customerNo,
                        customerName: transaction.customerName,
                        nilaiTagihan: transaction.nilaiTagihan,
                        admin: transaction.admin,
                        totalPembayaranUser: transaction.totalPembayaranUser,
                        periode: transaction.periode,
                        denda: transaction.denda,
                        status: transaction.status,
                        daya: transaction.daya,
                        lembarTagihan: transaction.lembarTagihan,
                        meterAwal: transaction.meterAwal,
                        meterAkhir: transaction.meterAkhir,
                        createdAt: transaction.createdAt,
                        sn: transaction.sn,
                        productName: transaction.productName,
                        namaToko: storeName,
                      );
                    }
                    debugPrint(
                      '✅ Attached store name to ${_allPascabayarTransactions.length} Pascabayar transactions',
                    );
                  } else {
                    debugPrint('⚠️ Store name is empty for Pascabayar!');
                  }
                } else {
                  debugPrint(
                    '⚠️ Store API (Pascabayar) returned status: ${storeResponse.statusCode}',
                  );
                }
              } catch (e) {
                debugPrint('⚠️ Error fetching store name for Pascabayar: $e');
                debugPrint('⚠️ Stack trace: ${StackTrace.current}');
              }

              // Save to cache
              await _savePascabayarToCache();
            } else {
              debugPrint('⚠️ Empty Pascabayar transaction list');
              _allPascabayarTransactions = [];
            }

            // Apply filters
            _applyPascabayarFilters();
          } else {
            debugPrint('⚠️ Pascabayar transaction data is null');
            _allPascabayarTransactions = [];
            _applyPascabayarFilters();
          }
        } else {
          _setError('Status response bukan success: ${data['status']}');
        }
      } else {
        _setError('Gagal mengambil data (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error loading Pascabayar transaction history: $e');
      _setError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _loadPascabayarFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachePascabayarKey);
      final timestamp = prefs.getInt(_cachePascabayarTimestampKey) ?? 0;

      if (cachedJson == null) return false;

      // Check if cache is still valid
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > (_cacheValidityMinutes * 60 * 1000)) {
        return false;
      }

      // Parse cached data
      final List<dynamic> decodedList = json_convert.json.decode(cachedJson);
      _allPascabayarTransactions = decodedList
          .map(
            (item) =>
                TransactionPascabayar.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      debugPrint('✅ Loaded Pascabayar transaction history from cache');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error loading Pascabayar from cache: $e');
      return false;
    }
  }

  Future<void> _savePascabayarToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _allPascabayarTransactions
          .map(
            (t) => {
              'id': t.id,
              'user_id': t.userId,
              'ref_id': t.refId,
              'brand': t.brand,
              'buyer_sku_code': t.buyerSkuCode,
              'customer_no': t.customerNo,
              'customer_name': t.customerName,
              'nilai_tagihan': t.nilaiTagihan,
              'admin': t.admin,
              'total_pembayaran_user': t.totalPembayaranUser,
              'periode': t.periode,
              'denda': t.denda,
              'status': t.status,
              'daya': t.daya,
              'lembar_tagihan': t.lembarTagihan,
              'meter_awal': t.meterAwal,
              'meter_akhir': t.meterAkhir,
              'created_at': t.createdAt,
              'sn': t.sn,
              'product_name': t.productName,
              'nama_toko': t.namaToko,
            },
          )
          .toList();

      await prefs.setString(
        _cachePascabayarKey,
        json_convert.json.encode(jsonList),
      );
      await prefs.setInt(
        _cachePascabayarTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('💾 Pascabayar transaction history saved to cache');
    } catch (e) {
      debugPrint('⚠️ Error saving Pascabayar to cache: $e');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: "Cari ID Ref atau Nomor HP...",
              prefixIcon: Icon(Icons.search, color: appConfig.primaryColor),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchQuery = "";
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filters.map((filter) {
                bool isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: appConfig.primaryColor.withOpacity(0.2),
                    checkmarkColor: appConfig.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? appConfig.primaryColor
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool value) {
                      setState(() {
                        selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionDetail item) {
    Color statusColor = item.isSuccess
        ? Colors.green
        : (item.status.toUpperCase() == 'PENDING' ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailPage(
              refId: item.refId,
              transactionId: item.id.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.tanggalTransaksi,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: appConfig.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: appConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.nomorHp,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: appConfig.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Ref ID: ${item.refId}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyToClipboard(item.refId),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: appConfig.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Ref ID tersalin ke clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ======================== PASCABAYAR UI WIDGETS ========================

  Widget _buildSearchAndFilterPascabayar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                _applyPascabayarFilters();
              });
            },
            decoration: InputDecoration(
              hintText: "Cari ID Ref, No. Pelanggan, atau Nama...",
              prefixIcon: Icon(Icons.search, color: appConfig.primaryColor),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchQuery = "";
                          _applyPascabayarFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filters.map((filter) {
                bool isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: appConfig.primaryColor.withOpacity(0.2),
                    checkmarkColor: appConfig.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? appConfig.primaryColor
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool value) {
                      setState(() {
                        selectedFilter = filter;
                        _applyPascabayarFilters();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPascabayarCard(TransactionPascabayar item) {
    Color statusColor = item.isSuccess
        ? Colors.green
        : (item.isPending ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionPascabayarDetailPage(transaction: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.createdAt,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: appConfig.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.receipt_long,
                      color: appConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.customerName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.customerNo,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.formattedTotal,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: appConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.formattedPeriode,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Ref ID: ${item.refId}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyToClipboard(item.refId),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: appConfig.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== MUTASI DATA LOADING ========================

  Future<void> _loadMutasiHistory({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = !forceRefresh;
        _errorMessage = null;
      });

      // 1. Try to load from cache first if not forcing refresh
      if (!forceRefresh && await _loadMutasiFromCache()) {
        _applyMutasiFilters();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Get token from session
      final String? token = await SessionManager.getToken();
      if (token == null) {
        _setError('Token tidak ditemukan');
        return;
      }

      debugPrint('🔐 Token Mutasi: ${token.substring(0, 20)}...');

      // 3. Fetch from API
      final response = await _apiService.getLogTransaksiMutasi(token);

      debugPrint('🔍 Mutasi API Response Status Code: ${response.statusCode}');
      debugPrint('🔍 Mutasi API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check status
        final bool isSuccess =
            (data['status'] == true || data['status'] == 'success');

        debugPrint(
          '🔍 Status Check: ${data['status']} -> isSuccess: $isSuccess',
        );

        if (isSuccess) {
          // Parse response
          final transactionData = data['data'] as List?;

          debugPrint(
            '🔍 Mutasi Transaction Data Length: ${transactionData?.length ?? 0}',
          );

          if (transactionData != null && transactionData.isNotEmpty) {
            _allMutasiTransactions = transactionData
                .map(
                  (item) =>
                      TransactionMutasi.fromJson(item as Map<String, dynamic>),
                )
                .toList();

            debugPrint(
              '✅ Loaded ${_allMutasiTransactions.length} Mutasi transactions from API',
            );

            // Sort by date (newest first)
            _allMutasiTransactions.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );

            // Fetch store name and attach to transactions
            try {
              final storeResponse = await _apiService.getUserStore(token);
              debugPrint(
                '🏪 Store Response Status (Mutasi): ${storeResponse.statusCode}',
              );

              if (storeResponse.statusCode == 200) {
                final storeData = storeResponse.data;
                String storeName = '';
                if (storeData is Map) {
                  storeName = storeData['nama_toko']?.toString() ?? '';
                }

                debugPrint('🏪 Extracted store name (Mutasi): "$storeName"');

                if (storeName.isNotEmpty) {
                  for (var i = 0; i < _allMutasiTransactions.length; i++) {
                    final transaction = _allMutasiTransactions[i];
                    _allMutasiTransactions[i] = TransactionMutasi(
                      id: transaction.id,
                      trxId: transaction.trxId,
                      userId: transaction.userId,
                      username: transaction.username,
                      saldoAwal: transaction.saldoAwal,
                      saldoAkhir: transaction.saldoAkhir,
                      jumlah: transaction.jumlah,
                      markupAdmin: transaction.markupAdmin,
                      adminFee: transaction.adminFee,
                      keterangan: transaction.keterangan,
                      createdAt: transaction.createdAt,
                      namaToko: storeName,
                    );
                  }
                  debugPrint(
                    '✅ Attached store name to ${_allMutasiTransactions.length} Mutasi transactions',
                  );
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error fetching store name for Mutasi: $e');
            }

            // Save to cache
            await _saveMutasiToCache();
            _applyMutasiFilters();
          } else {
            debugPrint('⚠️ Empty Mutasi transaction list');
            _allMutasiTransactions = [];
            _applyMutasiFilters();
          }
        } else {
          _setError('Status response tidak valid: ${data['status']}');
        }
      } else {
        _setError('Gagal mengambil data (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error loading Mutasi transaction history: $e');
      _setError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _loadMutasiFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheMutasiKey);
      final timestamp = prefs.getInt(_cacheMutasiTimestampKey) ?? 0;

      if (cachedJson == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > (_cacheValidityMinutes * 60 * 1000)) {
        return false;
      }

      final List<dynamic> decodedList = json_convert.json.decode(cachedJson);
      _allMutasiTransactions = decodedList
          .map(
            (item) => TransactionMutasi.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      debugPrint('✅ Loaded Mutasi transaction history from cache');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error loading Mutasi from cache: $e');
      return false;
    }
  }

  Future<void> _saveMutasiToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _allMutasiTransactions.map((t) => t.toJson()).toList();

      await prefs.setString(
        _cacheMutasiKey,
        json_convert.json.encode(jsonList),
      );
      await prefs.setInt(
        _cacheMutasiTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('💾 Mutasi transaction history saved to cache');
    } catch (e) {
      debugPrint('⚠️ Error saving Mutasi to cache: $e');
    }
  }

  void _applyMutasiFilters() {
    _filteredMutasiTransactions = _allMutasiTransactions.where((transaction) {
      // Filter by search query
      bool searchMatch =
          searchQuery.isEmpty ||
          transaction.trxId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          transaction.username.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          transaction.keterangan.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      return searchMatch;
    }).toList();
  }

  Widget _buildSearchAndFilterMutasi() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _applyMutasiFilters();
          });
        },
        decoration: InputDecoration(
          hintText: "Cari ID Transaksi atau Username...",
          prefixIcon: Icon(Icons.search, color: appConfig.primaryColor),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = "";
                      _applyMutasiFilters();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildMutasiCard(TransactionMutasi item) {
    final isDebit = item.isDebit;
    final statusColor = isDebit ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionMutasiDetailPage(transaction: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.createdAt,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDebit ? 'Pengeluaran' : 'Pemasukan',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.keterangan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.username,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedJumlah,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "TRX ID: ${item.trxId}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyToClipboard(item.trxId),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: appConfig.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
