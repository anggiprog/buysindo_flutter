import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/customer/data/models/product_prabayar_model.dart'; // Pastikan path benar

class ApiService {
  final Dio _dio;
  final String baseUrl;
  static const String _prefKey = "cached_products";

  ApiService(this._dio, {this.baseUrl = 'https://buysindo.com/'}) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    _dio.options.validateStatus = (status) => status! < 500;
  }

  /// Getter untuk URL dasar Gambar
  String get imageBaseUrl => '${baseUrl}storage/images/logo/';
  String get imageBannerBaseUrl => '${baseUrl}storage/images/prabayar/';
  // Di dalam class ApiService
  String get imagePascabayarUrl => '${baseUrl}storage/images/pascabayar/';

  // ===========================================================================
  // ENDPOINTS CONFIG & BANNER
  // ===========================================================================

  /// Mengambil konfigurasi publik aplikasi
  Future<Response> getPublicConfig(String adminId, String appType) {
    return _dio.get('api/app/config/$adminId/$appType');
  }

  /// Mengambil data banner berdasarkan admin ID
  Future<Response> getBanners(String adminId) {
    return _dio.get('api/banner', queryParameters: {'admin_user_id': adminId});
  }

  // ===========================================================================
  // ENDPOINTS AUTH & USER
  // ===========================================================================

  /// Fungsi Login dengan pengiriman Device Token untuk Notifikasi (FCM)
  Future<Response> login(String email, String password, String deviceToken) {
    return _dio.post(
      'api/login',
      data: {'email': email, 'password': password, 'device_token': deviceToken},
    );
  }

  /// Mengambil profil user menggunakan Bearer Token
  Future<Response> getProfile(String token) {
    return _dio.get(
      'api/user/getProfile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Update profil user lengkap
  Future<Response> updateProfile({
    required String token,
    required String fullName,
    required String phone,
    required String gender,
    required String birthdate,
    required String address,
  }) {
    return _dio.post(
      'api/user/updateProfile',
      data: {
        'full_name': fullName,
        'phone': phone,
        'gender': gender,
        'birthdate': birthdate,
        'address': address,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  //saldo
  /// Mengambil saldo user

  Future<Response> getSaldo(String token) {
    return _dio.get(
      'api/saldo',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token', // Sertakan token di sini
        },
      ),
    );
  }

  // --- Endpoints Dasar ---
  Future<Response> getMenuPrabayar(String token) => _dio.get(
    'api/menu-prabayar',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  Future<Response> getMenuPascabayar(String token) => _dio.get(
    'api/menu-pascabayar',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  // --- Ambil Produk dengan Logika Cache ---
  // Ambil produk dari cache terlebih dahulu, jika tidak ada ambil dari API
  Future<List<ProductPrabayar>> getProducts(
    String? token, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_prefKey);

    // 1. Jika forceRefresh = true, langsung ambil dari API dan bypass cache
    if (forceRefresh) {
      return await _fetchProductsFromApi(token, prefs);
    }

    // 2. Cek Cache terlebih dahulu
    if (cachedData != null) {
      debugPrint(
        '📦 Menggunakan cache produk (${_parseProducts(cachedData).length} produk)',
      );
      return _parseProducts(cachedData);
    }

    // 3. Jika cache kosong, ambil dari API
    debugPrint('🔄 Cache kosong, fetch dari API...');
    return await _fetchProductsFromApi(token, prefs);
  }

  // Helper method untuk fetch dari API dan simpan ke cache
  Future<List<ProductPrabayar>> _fetchProductsFromApi(
    String? token,
    SharedPreferences prefs,
  ) async {
    try {
      final response = await _dio.get(
        'api/produk-prabayar',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['products'] != null) {
          final String productsJson = json.encode(data['products']);
          await prefs.setString(_prefKey, productsJson);
          final products = _parseProducts(productsJson);
          debugPrint(
            '✅ Produk berhasil di-fetch dari API (${products.length} produk)',
          );
          return products;
        }
      }
    } catch (e) {
      debugPrint("❌ Error Fetching Products: $e");
      // Fallback ke cache jika API gagal
      final String? cachedData = prefs.getString(_prefKey);
      if (cachedData != null) {
        debugPrint('⚠️ API gagal, fallback ke cache');
        return _parseProducts(cachedData);
      }
    }
    return [];
  }

  List<ProductPrabayar> _parseProducts(String jsonString) {
    final List decoded = json.decode(jsonString);
    return decoded.map((item) => ProductPrabayar.fromJson(item)).toList();
  }

  Future<void> clearProductCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    debugPrint('🗑️ Cache produk telah dihapus');
  }

  //detect brand
  // api_service.dart

  // api_service.dart

  Future<String?> detectBrand(String phone, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = phone.substring(0, 4);
    String cacheKey = "brand_$prefix";

    // 1. Cek apakah brand untuk prefix ini sudah pernah disimpan?
    if (prefs.containsKey(cacheKey)) {
      return prefs.getString(cacheKey);
    }

    try {
      final response = await _dio.get(
        'api/detect-brand',
        queryParameters: {'phone': phone},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['brand'] != null) {
        String detectedBrand = response.data['brand'].toString();

        // 2. Simpan ke Cache SharedPreferences agar kedepannya tidak perlu API lagi
        await prefs.setString(cacheKey, detectedBrand);

        return detectedBrand;
      }
    } catch (e) {
      debugPrint("❌ Gagal deteksi brand: $e");
    }
    return null;
  }

  // ===========================================================================
  // PIN ENDPOINTS
  // ===========================================================================

  /// Cek status PIN user (active/inactive)
  Future<Response> checkPinStatus(String token) {
    return _dio.get(
      'api/pin/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Validasi PIN yang dimasukkan user
  Future<Response> validatePin(String pin, String token) {
    return _dio.get(
      'api/pin/validate',
      queryParameters: {'pin': pin},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Simpan/Update PIN baru
  Future<Response> savePinData(String pin, String token) {
    return _dio.post(
      'api/pin',
      data: {'pin': pin},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ===========================================================================
  // TRANSACTION ENDPOINTS
  // ===========================================================================

  /// Proses transaksi prabayar
  Future<Response> processPrabayarTransaction({
    required String pin,
    required String category,
    required String sku,
    required String productName,
    required String phoneNumber,
    required int discount,
    required int total,
    required String token,
  }) {
    return _dio.post(
      'api/proses-trx-prabayar',
      data: {
        'pin': pin,
        'category': category,
        'sku': sku,
        'nama_produk': productName,
        'no_handphone': phoneNumber,
        'diskon': discount,
        'total': total,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil detail transaksi prabayar (untuk history)
  Future<Response> getTransactionDetailPrabayar(String token) {
    return _dio.get(
      'api/user/transaksi/prabayar',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
