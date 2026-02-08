import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/customer/data/models/product_prabayar_model.dart'; // Pastikan path benar
import '../../features/customer/data/models/notification_count_model.dart';
import '../../features/topup/models/topup_response_models.dart';
import '../../models/topup_history_models.dart';
import 'session_manager.dart';
import '../utils/web_helper.dart';
import '../utils/file_reader.dart';

// Silence all debug logging in this service
void _noopLog(Object? _) {}

// Temporary helper to surface tokens in console for debugging/Postman
void _debugTokenLog(String? token, {String source = ''}) {
  if (token == null || token.isEmpty) return;
  // ...existing code...
  // Using print (not debugPrint) to avoid log throttling
}

class ApiService {
  /// Ambil custom template preview (URL)
  Future<Map<String, dynamic>?> getCustomTemplatePreview(String? token) async {
    try {
      final response = await _dio.get(
        'api/custom-template-preview',
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      // Pastikan response data berbentuk Map
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          // Jika API kadang return string JSON
          return jsonDecode(response.data) as Map<String, dynamic>;
        }
      } else {
        debugPrint(
          '[ApiService] getCustomTemplatePreview: status ${response.statusCode}, data: ${response.data}',
        );
      }
    } catch (e) {
      debugPrint('[ApiService] getCustomTemplatePreview ERROR: $e');
    }
    return null;
  }

  /// Hapus semua chat antara user dan admin
  Future<bool> deleteAllChat(String token) async {
    try {
      print('[ApiService] deleteAllChat: Mengirim request hapus semua chat');
      final response = await _dio.delete(
        'api/user/chat',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print(
        '[ApiService] deleteAllChat: Status code: [32m${response.statusCode}[0m',
      );
      // print('[ApiService] deleteAllChat: Response: ${response.data}'); // Sembunyikan untuk keamanan
      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] deleteAllChat: ERROR: $e');
    }
    return false;
  }

  /// Ambil pesan chat user-admin
  Future<List<dynamic>?> getChatMessages(String token) async {
    try {
      print('[ApiService] getChatMessages: Mengirim request ambil chat');
      final response = await _dio.get(
        'api/user/chat',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print(
        '[ApiService] getChatMessages: Status code: [32m${response.statusCode}[0m',
      );
      // print('[ApiService] getChatMessages: Response: ${response.data}'); // Sembunyikan untuk keamanan
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('messages')) {
          print('[ApiService] getChatMessages: Format Map, return messages');
          return response.data['messages'] as List<dynamic>;
        } else if (response.data is List) {
          print('[ApiService] getChatMessages: Format List, return data');
          return response.data as List<dynamic>;
        }
      }
    } catch (e) {
      print('[ApiService] getChatMessages: ERROR: $e');
    }
    return null;
  }

  /// Kirim pesan chat user-admin
  Future<bool> sendChatMessage(String token, String message) async {
    try {
      print('[ApiService] sendChatMessage: Mengirim pesan: $message');
      final response = await _dio.post(
        'api/user/chat-send',
        data: {'message': message},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print(
        '[ApiService] sendChatMessage: Status code: [32m${response.statusCode}[0m',
      );
      // print('[ApiService] sendChatMessage: Response: ${response.data}'); // Sembunyikan untuk keamanan
      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] sendChatMessage: ERROR: $e');
    }
    return false;
  }

  /// Ambil kontak admin
  Future<Map<String, dynamic>?> getKontakAdmin(String token) async {
    try {
      final response = await _dio.get(
        'api/user/kontak-admin',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Ambil status paket
  Future<Map<String, dynamic>?> getPaket(String token) async {
    try {
      final response = await _dio.get(
        'api/user/getPaket',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      print('[ApiService] getPaket: ERROR: $e');
    }
    return null;
  }

  /// Ambil info update aplikasi
  Future<Map<String, dynamic>?> getAppUpdate(String token) async {
    try {
      final response = await _dio.get(
        'api/admin/app-update',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      print('[ApiService] getAppUpdate: ERROR: $e');
    }
    return null;
  }

  static final ApiService instance = ApiService(Dio());

  /// Check Telkomsel Omni Pascabayar bill
  Future<Response> checkTelkomselOmniBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/telkomsel/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check Indosat Only4u Pascabayar bill
  Future<Response> checkIndosatOnly4uBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/indosat/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check XL Axis Cuanku Pascabayar bill
  Future<Response> checkXlAxisCuankuBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/xl/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check Tri CuanMax Pascabayar bill
  Future<Response> checkTriCuanMaxBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/tri/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check by.U Pascabayar bill
  Future<Response> checkByuBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/byu/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check Gas Pascabayar bill
  Future<Response> checkGasPascabayarBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/gas/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check TV Pascabayar bill
  Future<Response> checkTvPascabayarBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/tv/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check Multifinance bill (body sama seperti PLN, response mirip)
  Future<Response> checkMultifinanceBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/multifinance/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check HP Pascabayar bill (body sama seperti PLN, response mirip)
  Future<Response> checkHpPascabayarBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/hp/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check BPJS Kesehatan bill (body sama seperti PLN, response berbeda)
  Future<Response> checkBpjsBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/bpjs-kesehatan/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ganti password user sesuai endpoint user/change-password
  Future<bool> changeUserPassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        'api/user/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 &&
          (response.data['status'] == true ||
              response.data['status'] == 'success' ||
              response.data['success'] == true)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  final Dio _dio;
  late final String baseUrl;
  static const String _prefKey = "cached_products";

  /// Factory constructor yang otomatis mendeteksi baseUrl untuk web
  factory ApiService.auto(Dio dio) {
    final url = WebHelper.getBaseUrl(defaultUrl: 'http://buysindo.com/');
    debugPrint('[ApiService] Auto baseUrl: $url');
    return ApiService(dio, baseUrl: url);
  }

  ApiService(this._dio, {String? baseUrl}) {
    this.baseUrl =
        baseUrl ?? WebHelper.getBaseUrl(defaultUrl: 'http://buysindo.com/');
    _dio.options.baseUrl = this.baseUrl;
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

  /// Mengambil data popup untuk ditampilkan di home
  Future<Response> getPopup(String token) {
    return _dio.get(
      'api/user/popup',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ===========================================================================
  // ENDPOINTS AUTH & USER
  // ===========================================================================

  /// High-level Login: sends device token and returns LoginResponse
  Future<LoginResponse> login(String email, String password) async {
    try {
      _noopLog('🔐 [ApiService] Starting login with email: $email');
      final deviceToken = await getDeviceToken();
      _noopLog(
        '📤 [ApiService] Sending login request with device_token: $deviceToken',
      );

      final response = await _dio.post(
        'api/login',
        data: {
          'email': email,
          'password': password,
          'device_token': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        _noopLog(
          '✅ [ApiService] Login successful, status code: ${response.statusCode}',
        );
        final loginResponse = LoginResponse.fromJson(response.data);
        _debugTokenLog(loginResponse.accessToken, source: 'login');
        return loginResponse;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get Firebase Device Token safely
  Future<String> getDeviceToken() async {
    try {
      _noopLog('📱 [ApiService] Fetching Firebase device token...');
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        _noopLog('✅ [ApiService] Device token fetched: $token');
        return token;
      } else {
        _noopLog('⚠️ [ApiService] Firebase device token is empty/null');
        return 'unknown_device_token';
      }
    } catch (e) {
      _noopLog('❌ [ApiService] Error getting device token: $e');
      return 'error_getting_token';
    }
  }

  /// Verify OTP code
  Future<OtpResponse> verifyOtp(String email, String otpCode) async {
    try {
      final deviceToken = await getDeviceToken();

      final response = await _dio.post(
        'api/verify-otp',
        data: {
          'email': email,
          'otp_code': otpCode,
          'device_token': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        final otpResponse = OtpResponse.fromJson(response.data);
        if (otpResponse.status == true && otpResponse.token != null) {
          await SessionManager.saveToken(otpResponse.token!);
          _debugTokenLog(otpResponse.token, source: 'verify-otp');
        }
        return otpResponse;
      } else {
        throw Exception('OTP verification failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Resend OTP to email
  Future<void> resendOtp(String email) async {
    try {
      final response = await _dio.post(
        'api/resend-otp',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Resend OTP failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mengambil profil user menggunakan Bearer Token
  Future<Response> getProfile(String token) {
    return _dio.get(
      'api/user/getProfile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil data "Tentang Kami" dari admin
  Future<Response> getTentangKami(String token) {
    return _dio.get(
      'api/admin/tentang-kami',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil Kode Referral User
  Future<Response> getReferralCode(String token) {
    return _dio.get(
      'api/user/get-referral-code',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Simpan/Buat Kode Referral User
  Future<Response> saveReferralCode(String token, String code) {
    return _dio.post(
      'api/user/save-referral-code',
      data: {'referral_code': code},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil Daftar User yang diajak (Referral List)
  Future<Response> getReferralList(String token) {
    return _dio.get(
      'api/user/referrals',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil Summary Referral (poin, komisi, downline)
  Future<Response> getReferralSummary(String token) {
    return _dio.get(
      'api/user/referral-summary',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Claim Poin Referral
  Future<Response> claimReferralPoin(String token, int poinRef) {
    return _dio.post(
      'api/user/referrals/claim-poin',
      data: {'poin_ref': poinRef},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Claim Saldo/Komisi Referral
  Future<Response> claimReferralSaldo(String token) {
    return _dio.post(
      'api/user/referrals/claim-saldo',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // =============== POIN USER ===============

  /// Get Poin Summary (total_poin, jumlah_poin, jumlah_saldo, percent)
  Future<Response> getPoinSummary(String token) {
    return _dio.get(
      'api/user/poin',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Get Riwayat Tukar Poin
  Future<Response> getRiwayatPoin(String token) {
    return _dio.get(
      'api/user/riwayat-tukar-poin',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Tukar Poin dengan Saldo
  Future<Response> claimPoinToSaldo(
    String token,
    int poin,
    int saldoPoin,
    int adminUserId,
  ) {
    return _dio.post(
      'api/user/tukar-poin',
      data: {
        'poin': poin,
        'saldo_poin': saldoPoin,
        'admin_user_id': adminUserId,
      },
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
      _noopLog(
        '📦 Menggunakan cache produk (${_parseProducts(cachedData).length} produk)',
      );
      return _parseProducts(cachedData);
    }

    // 3. Jika cache kosong, ambil dari API
    _noopLog('🔄 Cache kosong, fetch dari API...');
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
          _noopLog(
            '✅ Produk berhasil di-fetch dari API (${products.length} produk)',
          );
          return products;
        }
      }
    } catch (e) {
      _noopLog("❌ Error Fetching Products: $e");
      // Fallback ke cache jika API gagal
      final String? cachedData = prefs.getString(_prefKey);
      if (cachedData != null) {
        _noopLog('⚠️ API gagal, fallback ke cache');
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
    _noopLog('🗑️ Cache produk telah dihapus');
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
      _noopLog("❌ Gagal deteksi brand: $e");
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

  /// Ambil detail transaksi pascabayar (untuk history)
  Future<Response> getTransactionDetailPascabayar(String token) {
    return _dio.get(
      'api/user/transaksi/pascabayar',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil log mutasi saldo (untuk history mutasi)
  Future<Response> getLogTransaksiMutasi(String token) {
    return _dio.get(
      'api/admin/log-transaksi',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static const String _prefNamaToko = 'user_nama_toko';

  /// Ambil informasi toko user dan simpan ke SharedPreferences
  Future<Response> getUserStore(String token) async {
    final response = await _dio.get(
      'api/user/buat-toko',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    try {
      if (response.data != null && response.data['data'] != null) {
        final namaToko = response.data['data']['nama_toko'] ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefNamaToko, namaToko);
      }
    } catch (_) {}
    return response;
  }

  /// Simpan atau update toko user (POST) dan update SharedPreferences
  Future<Response> simpanToko(String token, String namaToko) async {
    final response = await _dio.post(
      'api/user/buat-toko',
      data: {'nama_toko': namaToko},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    try {
      if (response.data != null &&
          (response.data['status'] == 'success' ||
              response.data['status'] == true)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefNamaToko, namaToko);
      }
    } catch (_) {}
    return response;
  }

  /// Ambil nama_toko dari SharedPreferences
  Future<String?> getNamaTokoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefNamaToko);
  }

  // ===========================================================================
  // REGISTRATION ENDPOINTS
  // ===========================================================================

  /// Ambil admin token publik untuk registrasi (tanpa auth)
  Future<Response> getAdminToken(String adminUserId) {
    return _dio.get(
      'api/admin-tokens/$adminUserId',
      options: Options(validateStatus: (status) => status! < 500),
    );
  }

  /// Registrasi user baru dengan verifikasi email
  /// Memerlukan X-Admin-Token di header
  Future<Response> registerV2({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? referralCode,
    String? deviceToken,
  }) {
    return _dio.post(
      'api/registerV2',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'device_token': deviceToken,
      },
      options: Options(
        headers: {
          'X-Admin-Token': adminToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  /// Verifikasi email user
  Future<Response> verifyEmail(String token) {
    return _dio.get('api/verify-email', queryParameters: {'token': token});
  }

  // ===========================================================================
  // PASSWORD RESET ENDPOINTS
  // ===========================================================================

  /// Request to send OTP / reset link to user's email
  /// Endpoint: POST api/lupa-password-user
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        'api/lupa-pwd-user',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Permintaan lupa password dikirim';
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal meminta lupa password',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Reset password using OTP/code sent to email
  /// Endpoint: POST api/reset-password-user
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        'api/reset-pwd-user',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Password berhasil direset';
      } else {
        throw Exception(response.data['message'] ?? 'Gagal reset password');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update or register device token
  Future<void> updateDeviceToken(String token) async {
    try {
      _noopLog('📝 [ApiService] updateDeviceToken() called');
      _noopLog(
        '🔑 [ApiService] Using auth token: ${token.substring(0, 20)}...',
      );

      final deviceToken = await getDeviceToken();
      _noopLog('📱 [ApiService] Device token to update: $deviceToken');

      final response = await _dio.post(
        'api/device-token/update',
        data: {'device_token': deviceToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        _noopLog('✅ [ApiService] Device token updated successfully!');
        _noopLog('📌 [ApiService] Device Token: $deviceToken');
        _noopLog('📌 [ApiService] Response: ${response.data}');
      } else {
        _noopLog(
          '⚠️ [ApiService] Device token update returned status ${response.statusCode}',
        );
        throw Exception(
          'Update device token failed: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      _noopLog(
        '❌ [ApiService] Device token update error: ${_handleDioError(e)}',
      );
      // Don't throw, just log warning - not critical
    } catch (e) {
      _noopLog('❌ [ApiService] Unexpected error in updateDeviceToken: $e');
    }
  }

  /// Logout user
  Future<void> logout(String token) async {
    try {
      await _dio.post(
        'api/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await SessionManager.clearSession();
    } on DioException catch (e) {
      await SessionManager.clearSession();
      throw _handleDioError(e);
    }
  }

  /// Mengambil jumlah notifikasi untuk admin
  /// Endpoint: GET api/jumlah-notif-admin
  /// Jika token == null maka akan memanggil tanpa header Authorization
  Future<int> getAdminNotificationCount([String? token]) async {
    try {
      _noopLog(
        '🔔 [ApiService] getAdminNotificationCount() called (token present: ${token != null && token.isNotEmpty})',
      );

      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get(
        'api/jumlah-notif-admin',
        options: options,
      );

      _noopLog('🔔 [ApiService] Response status: ${response.statusCode}');
      _noopLog('🔔 [ApiService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          try {
            // Normalize keys to String
            final Map<String, dynamic> mapData = {};
            data.forEach((k, v) {
              mapData[k.toString()] = v;
            });
            final parsed = NotificationCountResponse.fromJson(mapData);
            _noopLog(
              '🔔 [ApiService] jumlah_belum_dibaca: ${parsed.jumlahBelumDibaca}',
            );
            return parsed.jumlahBelumDibaca;
          } catch (e) {
            _noopLog(
              '⚠️ [ApiService] Failed to parse NotificationCountResponse: $e',
            );
          }
        }

        // fallback: previous heuristics
        if (data is Map) {
          final possible = data['data'] ?? data['count'] ?? data['jumlah'] ?? 0;
          return int.tryParse(possible.toString()) ?? 0;
        }
        if (data is int) return data;
        if (data is String) return int.tryParse(data) ?? 0;
      }
      _noopLog(
        '⚠️ [ApiService] getAdminNotificationCount unexpected status: ${response.statusCode}',
      );
      return 0;
    } on DioException catch (e) {
      _noopLog('❌ [ApiService] getAdminNotificationCount error: $e');
      return 0;
    } catch (e) {
      _noopLog('❌ [ApiService] getAdminNotificationCount unknown error: $e');
      return 0;
    }
  }

  // ===========================================================================
  // ENDPOINTS TOPUP HISTORY
  // ===========================================================================

  /// Mengambil histori topup manual
  Future<TopupManualHistoryResponse> getTopupManualHistory(String token) async {
    try {
      final response = await _dio.get(
        'api/user/history-topup-manual',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return TopupManualHistoryResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load manual topup history');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mengambil histori topup otomatis
  Future<TopupOtomatisHistoryResponse> getTopupOtomatisHistory(
    String token,
  ) async {
    try {
      final response = await _dio.get(
        'api/topup-history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return TopupOtomatisHistoryResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load otomatis topup history');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Ambil daftar notifikasi user
  Future<Response> getUserNotifications(String token) {
    return _dio.get(
      'api/user/notifications',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Ambil jumlah notifikasi belum dibaca untuk user
  Future<Response> getUserUnreadCount(String token) {
    return _dio.get(
      'api/user/notification/unread-count',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Mark single notification as read (POST id)
  Future<Response> markNotificationAsRead({
    required int id,
    required String token,
  }) {
    return _dio.post(
      'api/user/notification/read',
      data: {'id': id},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Delete a single notification by ID
  Future<Response> deleteNotification({
    required int id,
    required String token,
  }) async {
    try {
      _noopLog('📤 [API] Sending delete request for notification ID: $id');
      _noopLog('📤 [API] Endpoint: api/user/notification/delete');
      _noopLog('📤 [API] Data: {"notification_id": $id}');
      _noopLog('📤 [API] Token present: ${token.isNotEmpty}');

      final response = await _dio.post(
        'api/user/notification/delete',
        data: {'notification_id': id},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _noopLog('📥 [API] Raw status code: ${response.statusCode}');
      _noopLog('📥 [API] Raw response body: ${response.data}');

      return response;
    } on DioException catch (e) {
      _noopLog('❌ [API] DioException during delete: ${e.message}');
      _noopLog('❌ [API] Exception type: ${e.type}');
      _noopLog('❌ [API] Response status: ${e.response?.statusCode}');
      _noopLog('❌ [API] Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      _noopLog('❌ [API] Unexpected error during delete: $e');
      rethrow;
    }
  }

  /// Delete all notifications for user
  Future<Response> deleteAllUserNotifications(String token) {
    return _dio.post(
      'api/user/notification/delete-all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ===========================================================================
  // TOPUP ENDPOINTS
  // ===========================================================================

  /// Ambil minimal topup berdasarkan amount
  Future<MinimalTopupResponse> getMinimalTopup(
    int? amount,
    String token,
  ) async {
    try {
      final queryParams = amount != null
          ? {'amount': amount}
          : <String, dynamic>{};
      final response = await _dio.get(
        'api/minimal-topup',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return MinimalTopupResponse.fromJson(response.data);
    } catch (e) {
      _noopLog('❌ Error get minimal topup: $e');
      rethrow;
    }
  }

  /// Ambil biaya admin untuk topup manual
  Future<AdminFeeResponse> getAdminFee(String token) async {
    try {
      final response = await _dio.get(
        'api/admin-fee',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return AdminFeeResponse.fromJson(response.data);
    } catch (e) {
      _noopLog('❌ Error get admin fee: $e');
      rethrow;
    }
  }

  /// Ambil status rekening untuk topup manual
  Future<RekeningStatusResponse> getRekeningStatus(String token) async {
    try {
      final response = await _dio.get(
        'api/rekening/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return RekeningStatusResponse.fromJson(response.data);
    } catch (e) {
      _noopLog('❌ Error get rekening status: $e');
      rethrow;
    }
  }

  /// Ambil status pembayaran otomatis
  Future<StatusPaymentResponse> getStatusPayment(String token) async {
    try {
      final response = await _dio.get(
        'api/status-payment',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return StatusPaymentResponse.fromJson(response.data);
    } catch (e) {
      _noopLog('❌ Error get status payment: $e');
      rethrow;
    }
  }

  /// Ambil daftar rekening bank untuk pembayaran manual
  Future<BankAccountResponse> getBankAccounts(String token) async {
    try {
      print('🔍 [API] ===== FETCHING BANK ACCOUNTS START =====');
      print('🔍 [API] Endpoint: api/rekening-bank');
      // print('🔍 [API] Token: ${token.substring(0, 20)}...'); // Sembunyikan untuk keamanan

      final response = await _dio.get(
        'api/rekening-bank',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('🔍 [API] Status Code: ${response.statusCode}');
      // print('🔍 [API] Response Data: ${response.data}'); // Sembunyikan untuk keamanan

      final bankResponse = BankAccountResponse.fromJson(response.data);
      print(
        '🔍 [API] Parsed Bank Accounts Count: ${bankResponse.data?.length}',
      );
      if (bankResponse.data != null) {
        for (var i = 0; i < bankResponse.data!.length; i++) {
          final bank = bankResponse.data![i];
          print('🔍 [API]   [$i] ${bank.namaBank} - ${bank.nomorRekening}');
        }
      }
      print('🔍 [API] ===== FETCHING BANK ACCOUNTS END =====');

      return bankResponse;
    } catch (e) {
      print('❌ [API] Error get bank accounts: $e');
      print('❌ [API] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Mengambil splash screen publik berdasarkan admin_user_id
  /// Endpoint: GET api/splash-screens?admin_user_id=...
  /// Mengembalikan Map<String, dynamic> dari objek `data` jika sukses, atau null jika gagal
  Future<Map<String, dynamic>?> getSplashScreen(String adminUserId) async {
    try {
      final response = await _dio.get(
        'api/splash-screens',
        queryParameters: {'admin_user_id': adminUserId},
        options: Options(validateStatus: (status) => status! < 500),
      );

      debugPrint(
        '🌊 [ApiService] getSplashScreen status=${response.statusCode} data=${response.data}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        // response structure expected: { success: true, message: '', data: { ... } }
        if (body is Map && body['data'] != null) {
          final data = body['data'];
          if (data is Map) {
            // Normalize keys to String
            final Map<String, dynamic> normalized = {};
            data.forEach((k, v) => normalized[k.toString()] = v);
            return normalized;
          }
        }
      }

      return null;
    } on DioException catch (e) {
      _noopLog('❌ [ApiService] getSplashScreen DioException: $e');
      return null;
    } catch (e) {
      _noopLog('❌ [ApiService] getSplashScreen Error: $e');
      return null;
    }
  }

  /// Check whether the device token stored on backend differs from the current device token
  /// Returns true when backend has a non-empty device_token and it is different from the device's token.
  Future<bool> isDeviceTokenMismatch(String authToken) async {
    try {
      final response = await getProfile(authToken);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        // Expect body['user']['device_token'] or user.device_token
        if (body is Map && body['user'] != null) {
          final user = body['user'];
          String? backendToken;
          if (user is Map) {
            backendToken = (user['device_token'] ?? user['deviceToken'])
                ?.toString();
          }

          if (backendToken == null || backendToken.isEmpty) {
            // backend has no token recorded - not considered a mismatch
            return false;
          }

          final currentDeviceToken = await getDeviceToken();
          // If currentDeviceToken is 'unknown_device_token' or 'error_getting_token', avoid false positives
          if (currentDeviceToken.isEmpty) {
            return false;
          }
          if (currentDeviceToken.startsWith('unknown') ||
              currentDeviceToken.startsWith('error')) {
            return false;
          }

          return backendToken != currentDeviceToken;
        }
      }
    } catch (e) {
      _noopLog('❌ [ApiService] isDeviceTokenMismatch error: $e');
    }
    return false;
  }

  /// Check whether the provided auth token is still valid on backend.
  /// Returns true when a protected endpoint (getProfile) returns 200.
  Future<bool> isAuthTokenValid(String authToken) async {
    try {
      final response = await getProfile(authToken);
      _noopLog(
        '🔐 [ApiService] isAuthTokenValid status=${response.statusCode}',
      );
      return response.statusCode == 200;
    } catch (e) {
      _noopLog('❌ [ApiService] isAuthTokenValid error: $e');
      return false;
    }
  }

  /// Proses topup saldo ke rekening bank
  /// Endpoint: POST api/topup
  /// Requires: Authorization (user token) dan X-Admin-Token
  /// batasWaktu otomatis diset ke 3 hari dari sekarang
  /// nomorTransaksi otomatis generate: {adminId}_Trxtopup_{randomString}
  /// Returns both the response and the generated transaction number
  Future<TopupResponseWithTrxId> topUpSaldo({
    required String amount,
    required String bankName,
    required String nomorRekening,
    required String namaRekening,
    required String userToken,
    required String adminUserId,
  }) async {
    try {
      // Generate nomorTransaksi: TRX{adminId}{randomString} - only letters and numbers
      final random = Random().nextInt(999999);
      final nomorTransaksi =
          'TRX${adminUserId}${random.toString().padLeft(6, '0')}';

      // Ambil admin token
      final adminTokenResponse = await getAdminToken(adminUserId);
      if (adminTokenResponse.statusCode != 200) {
        throw Exception('Gagal mengambil admin token');
      }

      // Parse admin token dari struktur response: {status: "success", data: [{token: "..."}]}
      String? adminToken;
      try {
        final responseData = adminTokenResponse.data;
        // print('🔍 [API] Admin Token Response: $responseData'); // Sembunyikan untuk keamanan

        if (responseData is Map) {
          // Cek struktur: data['data'] adalah array
          final dataArray = responseData['data'];
          if (dataArray is List && dataArray.isNotEmpty) {
            final firstItem = dataArray[0];
            if (firstItem is Map) {
              adminToken = firstItem['token'] as String?;
            }
          }
          // Fallback: cek langsung di root level
          if (adminToken == null || adminToken.isEmpty) {
            adminToken = responseData['token'] as String?;
          }
        }
      } catch (e) {
        print('⚠️ [API] Error parsing admin token: $e');
      }

      if (adminToken == null || adminToken.isEmpty) {
        throw Exception('Admin token kosong - gagal parse dari response');
      }

      // print('🔍 [API] Admin Token: ${adminToken.substring(0, 20)}...'); // Sembunyikan untuk keamanan

      // Hitung batas waktu (3 hari dari sekarang) - format: Y-m-d H:i:s
      final batasWaktuDateTime = DateTime.now().add(const Duration(days: 3));
      final batasWaktu =
          '${batasWaktuDateTime.year}-${batasWaktuDateTime.month.toString().padLeft(2, '0')}-${batasWaktuDateTime.day.toString().padLeft(2, '0')} '
          '${batasWaktuDateTime.hour.toString().padLeft(2, '0')}:${batasWaktuDateTime.minute.toString().padLeft(2, '0')}:${batasWaktuDateTime.second.toString().padLeft(2, '0')}';
      print('🔍 [API] Batas Waktu: $batasWaktu');

      // Buat form data
      final formData = FormData.fromMap({
        'amount': amount,
        'bank_name': bankName,
        'nomor_rekening': nomorRekening,
        'nama_rekening': namaRekening,
        'nomor_transaksi': nomorTransaksi,
        'batas_waktu': batasWaktu,
      });

      // Kirim request dengan dua header authorization
      final response = await _dio.post(
        'api/topup',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'X-Admin-Token': adminToken,
          },
        ),
      );

      print('🔍 [API] Status Code: ${response.statusCode}');
      // print('🔍 [API] Response Data: ${response.data}'); // Sembunyikan untuk keamanan

      final topupResponse = TopupResponse.fromJson(response.data);
      print('🔍 [API] Transaction Number: $nomorTransaksi (for proof upload)');
      print('🔍 [API] ===== TOP UP SALDO END =====');

      // Return both response and the generated transaction number
      return TopupResponseWithTrxId(
        response: topupResponse,
        generatedTrxId: nomorTransaksi,
      );
    } on DioException catch (e) {
      print('❌ [API] DioException during topup: ${e.message}');
      print('❌ [API] Response status: ${e.response?.statusCode}');
      print('❌ [API] Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('❌ [API] Error top up saldo: $e');
      print('❌ [API] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Upload bukti transfer (foto)
  /// Endpoint: POST api/foto-bukti-transfer
  /// Requires: Authorization (user token), nomor_transaksi, dan photo as base64 string
  /// Backend expects photo field as base64 string, not file upload
  Future<Response> uploadPaymentProof({
    required String nomorTransaksi,
    String? photoPath, // For mobile
    List<int>? photoBytes, // For web
    String? photoFileName, // For web
    required String userToken,
  }) async {
    try {
      // Convert image to base64 string (backend expects base64)
      String base64Photo;

      if (photoBytes != null) {
        // Use provided bytes (web or already loaded)
        print('🔍 [API] Converting bytes to base64...');
        base64Photo = base64Encode(photoBytes);
      } else if (!kIsWeb && photoPath != null && photoPath.isNotEmpty) {
        // Read file from path (mobile only - using conditional import)
        print('🔍 [API] Reading file from path: $photoPath');
        final bytes = await readFileBytes(photoPath);
        base64Photo = base64Encode(bytes);
      } else {
        throw Exception('Foto tidak tersedia (tidak ada path atau bytes)');
      }

      // Send as JSON with base64 string
      final response = await _dio.post(
        'api/foto-bukti-transfer',
        data: {'nomor_transaksi': nomorTransaksi, 'photo': base64Photo},
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [API] Upload successful!');
      } else {
        print('⚠️ [API] Upload returned status ${response.statusCode}');
      }

      print('✅ [API] ===== UPLOAD PAYMENT PROOF END =====');

      return response;
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // ===========================================================================
  // ENDPOINTS PASCABAYAR
  // ===========================================================================

  /// Check E-MONEY Pascabayar bill
  Future<Response> checkEmoneyBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required int amount,
    required String token,
  }) {
    return _dio.post(
      'api/v2/emoney/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
        'amount': amount,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Get pascabayar products
  Future<Response> getPascabayarProducts(String token) {
    return _dio.get(
      'api/pascabayar',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check PLN Pascabayar bill
  Future<Response> checkPascabayarBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/pln-pascabayar/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check PBB bill (matches Postman)
  Future<Response> checkPbbBill({
    required int adminUserId,
    required String customerNo,
    required String productName,
    required String brand,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/v2/pbb/cek-tagihan',
      data: {
        'admin_user_id': adminUserId.toString(),
        'customer_no': customerNo,
        'product_name': productName,
        'brand': brand,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Check PDAM bill (struktur berbeda dengan PLN)
  Future<Response> checkPdamBill({
    required String productName,
    required String buyerSkuCode,
    required String refId,
    required String brand,
    required String customerName,
    required String customerNo,
    required String tarif,
    required String alamat,
    required String jatuhTempo,
    required int lembarTagihan,
    required List<RincianTagihan> rincianTagihan,
    required int tagihan,
    required int admin,
    required int denda,
    required int biayaLain,
    required int totalTagihan,
    required String token,
  }) {
    return _dio.post(
      'api/v2/pdam/cek-tagihan',
      data: {
        'product_name': productName,
        'buyer_sku_code': buyerSkuCode,
        'ref_id': refId,
        'brand': brand,
        'customer_name': customerName,
        'customer_no': customerNo,
        'tarif': tarif,
        'alamat': alamat,
        'jatuh_tempo': jatuhTempo,
        'lembar_tagihan': lembarTagihan,
        'rincian_tagihan': rincianTagihan.map((e) => e.toJson()).toList(),
        'tagihan': tagihan,
        'admin': admin,
        'denda': denda,
        'biaya_lain': biayaLain,
        'total_tagihan': totalTagihan,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Process pascabayar transaction
  Future<Response> processPascabayarTransaction({
    required int adminUserId,
    required String pin,
    required String refId,
    required String brand,
    required String customerNo,
    required String customerName,
    required num tagihan,
    required num admin,
    required num denda,
    required num totalTagihan,
    required String productName,
    required String buyerSkuCode,
    required String token,
  }) {
    return _dio.post(
      'api/proses-trx-pascabayar',
      data: {
        'admin_user_id': adminUserId,
        'pin': pin,
        'ref_id': refId,
        'brand': brand,
        'customer_no': customerNo,
        'customer_name': customerName,
        'tagihan': tagihan,
        'admin': admin,
        'denda': denda,
        'total_tagihan': totalTagihan,
        'product_name': productName,
        'buyer_sku_code': buyerSkuCode,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Process PDAM transaction (optional, jika dibutuhkan)
  Future<Response> processPdamTransaction({
    required int adminUserId,
    required String pin,
    required String refId,
    required String brand,
    required String customerNo,
    required String customerName,
    required num tagihan,
    required num admin,
    required num denda,
    required num biayaLain,
    required num totalTagihan,
    required String productName,
    required String buyerSkuCode,
    required String tarif,
    required String alamat,
    required String jatuhTempo,
    required int lembarTagihan,
    required List<RincianTagihan> rincianTagihan,
    required String token,
  }) {
    return _dio.post(
      'api/proses-trx-pdam',
      data: {
        'admin_user_id': adminUserId,
        'pin': pin,
        'ref_id': refId,
        'brand': brand,
        'customer_no': customerNo,
        'customer_name': customerName,
        'tagihan': tagihan,
        'admin': admin,
        'denda': denda,
        'biaya_lain': biayaLain,
        'total_tagihan': totalTagihan,
        'product_name': productName,
        'buyer_sku_code': buyerSkuCode,
        'tarif': tarif,
        'alamat': alamat,
        'jatuh_tempo': jatuhTempo,
        'lembar_tagihan': lembarTagihan,
        'rincian_tagihan': rincianTagihan.map((e) => e.toJson()).toList(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Handle Dio errors uniformly
  String _handleDioError(DioException e) {
    if (e.response != null) {
      return e.response?.data['message'] ??
          e.response?.statusMessage ??
          'Unknown error';
    }
    return e.message ?? 'Network error';
  }

  // =============================================
  // High-level models: LoginResponse & OtpResponse
  // =============================================
}

/// Model untuk rincian tagihan PDAM
class RincianTagihan {
  final String periode;
  final String nilaiTagihan;
  final String denda;
  final String meterAwal;
  final String meterAkhir;
  final String biayaLain;

  RincianTagihan({
    required this.periode,
    required this.nilaiTagihan,
    required this.denda,
    required this.meterAwal,
    required this.meterAkhir,
    required this.biayaLain,
  });

  factory RincianTagihan.fromJson(Map<String, dynamic> json) {
    return RincianTagihan(
      periode: json['periode'] ?? '',
      nilaiTagihan: json['nilai_tagihan'] ?? '',
      denda: json['denda'] ?? '',
      meterAwal: json['meter_awal'] ?? '',
      meterAkhir: json['meter_akhir'] ?? '',
      biayaLain: json['biaya_lain'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'periode': periode,
    'nilai_tagihan': nilaiTagihan,
    'denda': denda,
    'meter_awal': meterAwal,
    'meter_akhir': meterAkhir,
    'biaya_lain': biayaLain,
  };
}

/// Model gabungan response tagihan Pascabayar (PLN/PDAM)
class PascabayarTagihanResponse {
  final String? productName;
  final String? buyerSkuCode;
  final String? refId;
  final String? brand;
  final String? customerName;
  final String? customerNo;
  final String? tarif;
  final String? alamat;
  final String? jatuhTempo;
  final int? lembarTagihan;
  final List<RincianTagihan>? rincianTagihan;
  final num? tagihan;
  final num? admin;
  final num? denda;
  final num? biayaLain;
  final num? totalTagihan;
  final Map<String, dynamic>? otherFields;

  PascabayarTagihanResponse({
    this.productName,
    this.buyerSkuCode,
    this.refId,
    this.brand,
    this.customerName,
    this.customerNo,
    this.tarif,
    this.alamat,
    this.jatuhTempo,
    this.lembarTagihan,
    this.rincianTagihan,
    this.tagihan,
    this.admin,
    this.denda,
    this.biayaLain,
    this.totalTagihan,
    this.otherFields,
  });

  factory PascabayarTagihanResponse.fromJson(Map<String, dynamic> json) {
    List<RincianTagihan>? rincian;
    if (json['rincian_tagihan'] is List) {
      rincian = (json['rincian_tagihan'] as List)
          .map((e) => RincianTagihan.fromJson(e))
          .toList();
    }
    // Support for HP Pascabayar: allow periode as int or string, and allow missing fields
    return PascabayarTagihanResponse(
      productName: json['product_name'],
      buyerSkuCode: json['buyer_sku_code'],
      refId: json['ref_id'],
      brand: json['brand'],
      customerName: json['customer_name'],
      customerNo: json['customer_no'],
      tarif: json['tarif'],
      alamat: json['alamat'],
      jatuhTempo: json['jatuh_tempo'],
      lembarTagihan: json['lembar_tagihan'] is int
          ? json['lembar_tagihan']
          : int.tryParse(json['lembar_tagihan']?.toString() ?? ''),
      rincianTagihan: rincian,
      tagihan: json['tagihan'] is num
          ? json['tagihan']
          : num.tryParse(json['tagihan']?.toString() ?? '0'),
      admin: json['admin'] is num
          ? json['admin']
          : num.tryParse(json['admin']?.toString() ?? '0'),
      denda: json['denda'] is num
          ? json['denda']
          : num.tryParse(json['denda']?.toString() ?? '0'),
      biayaLain: json['biaya_lain'] is num
          ? json['biaya_lain']
          : num.tryParse(json['biaya_lain']?.toString() ?? '0'),
      totalTagihan: json['total_tagihan'] is num
          ? json['total_tagihan']
          : num.tryParse(json['total_tagihan']?.toString() ?? '0'),
      otherFields: json,
    );
  }
}

/// Model for Login Response
class LoginResponse {
  final bool? status;
  final String? message;
  final bool? requireOtp;
  final String? accessToken;
  final Map<String, dynamic>? user;

  LoginResponse({
    this.status,
    this.message,
    this.requireOtp,
    this.accessToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    _noopLog('📦 Login Response JSON: $json');

    String? token =
        json['access_token'] as String? ??
        json['token'] as String? ??
        json['accessToken'] as String?;

    return LoginResponse(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      requireOtp: json['require_otp'] as bool? ?? false,
      accessToken: token,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

/// Model for OTP Response
class OtpResponse {
  final bool? status;
  final String? message;
  final String? token;
  final Map<String, dynamic>? user;

  OtpResponse({this.status, this.message, this.token, this.user});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      token: json['token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

/// Helper class to wrap TopupResponse with the client-generated transaction ID
class TopupResponseWithTrxId {
  final TopupResponse response;
  final String generatedTrxId;

  TopupResponseWithTrxId({
    required this.response,
    required this.generatedTrxId,
  });
}
