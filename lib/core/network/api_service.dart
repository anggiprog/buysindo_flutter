import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/customer/data/models/product_prabayar_model.dart'; // Pastikan path benar
import '../../features/customer/data/models/notification_count_model.dart';
import 'session_manager.dart';

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

  /// High-level Login: sends device token and returns LoginResponse
  Future<LoginResponse> login(String email, String password) async {
    try {
      debugPrint('🔐 [ApiService] Starting login with email: $email');
      final deviceToken = await getDeviceToken();
      debugPrint('📤 [ApiService] Sending login request with device_token: $deviceToken');

      final response = await _dio.post(
        'api/login',
        data: {'email': email, 'password': password, 'device_token': deviceToken},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [ApiService] Login successful, status code: ${response.statusCode}');
        return LoginResponse.fromJson(response.data);
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
      debugPrint('📱 [ApiService] Fetching Firebase device token...');
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        debugPrint('✅ [ApiService] Device token fetched: $token');
        return token;
      } else {
        debugPrint('⚠️ [ApiService] Firebase device token is empty/null');
        return 'unknown_device_token';
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Error getting device token: $e');
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
      final response = await _dio.post('api/resend-otp', data: {'email': email});

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

  /// Ambil informasi toko user
  Future<Response> getUserStore(String token) {
    return _dio.get(
      'api/user/buat-toko',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
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
      final response = await _dio.post('api/lupa-pwd-user', data: {'email': email});
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Permintaan lupa password dikirim';
      } else {
        throw Exception(response.data['message'] ?? 'Gagal meminta lupa password');
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
      final response = await _dio.post('api/reset-pwd-user', data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

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
      debugPrint('📝 [ApiService] updateDeviceToken() called');
      debugPrint('🔑 [ApiService] Using auth token: ${token.substring(0, 20)}...');

      final deviceToken = await getDeviceToken();
      debugPrint('📱 [ApiService] Device token to update: $deviceToken');

      final response = await _dio.post(
        'api/device-token/update',
        data: {'device_token': deviceToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [ApiService] Device token updated successfully!');
        debugPrint('📌 [ApiService] Device Token: $deviceToken');
        debugPrint('📌 [ApiService] Response: ${response.data}');
      } else {
        debugPrint('⚠️ [ApiService] Device token update returned status ${response.statusCode}');
        throw Exception('Update device token failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [ApiService] Device token update error: ${_handleDioError(e)}');
      // Don't throw, just log warning - not critical
    } catch (e) {
      debugPrint('❌ [ApiService] Unexpected error in updateDeviceToken: $e');
    }
  }

  /// Logout user
  Future<void> logout(String token) async {
    try {
      await _dio.post('api/logout', options: Options(headers: {'Authorization': 'Bearer $token'}));
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
      debugPrint('🔔 [ApiService] getAdminNotificationCount() called (token present: ${token != null && token.isNotEmpty})');

      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get(
        'api/jumlah-notif-admin',
        options: options,
      );

      debugPrint('🔔 [ApiService] Response status: ${response.statusCode}');
      debugPrint('🔔 [ApiService] Response data: ${response.data}');

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
            debugPrint('🔔 [ApiService] jumlah_belum_dibaca: ${parsed.jumlahBelumDibaca}');
            return parsed.jumlahBelumDibaca;
          } catch (e) {
            debugPrint('⚠️ [ApiService] Failed to parse NotificationCountResponse: $e');
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
      debugPrint('⚠️ [ApiService] getAdminNotificationCount unexpected status: ${response.statusCode}');
      return 0;
    } on DioException catch (e) {
      debugPrint('❌ [ApiService] getAdminNotificationCount error: $e');
      return 0;
    } catch (e) {
      debugPrint('❌ [ApiService] getAdminNotificationCount unknown error: $e');
      return 0;
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
  Future<Response> markNotificationAsRead({required int id, required String token}) {
    return _dio.post(
      'api/user/notification/read',
      data: {'id': id},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Delete all notifications for user
  Future<Response> deleteAllUserNotifications(String token) {
    return _dio.post(
      'api/user/notification/delete-all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
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

      debugPrint('🌊 [ApiService] getSplashScreen status=${response.statusCode} data=${response.data}');

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
      debugPrint('❌ [ApiService] getSplashScreen DioException: $e');
      return null;
    } catch (e) {
      debugPrint('❌ [ApiService] getSplashScreen Error: $e');
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
            backendToken = (user['device_token'] ?? user['deviceToken'])?.toString();
          }

          if (backendToken == null || backendToken.isEmpty) {
            // backend has no token recorded - not considered a mismatch
            return false;
          }

          final currentDeviceToken = await getDeviceToken();
          // If currentDeviceToken is 'unknown_device_token' or 'error_getting_token', avoid false positives
          if (currentDeviceToken == null || currentDeviceToken.isEmpty) return false;
          if (currentDeviceToken.startsWith('unknown') || currentDeviceToken.startsWith('error')) return false;

          return backendToken != currentDeviceToken;
        }
      }
    } catch (e) {
      debugPrint('❌ [ApiService] isDeviceTokenMismatch error: $e');
    }
    return false;
  }

  /// Check whether the provided auth token is still valid on backend.
  /// Returns true when a protected endpoint (getProfile) returns 200.
  Future<bool> isAuthTokenValid(String authToken) async {
    try {
      final response = await getProfile(authToken);
      debugPrint('🔐 [ApiService] isAuthTokenValid status=${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [ApiService] isAuthTokenValid error: $e');
      return false;
    }
  }

  /// Handle Dio errors uniformly
  String _handleDioError(DioException e) {
    if (e.response != null) {
      return e.response?.data['message'] ?? e.response?.statusMessage ?? 'Unknown error';
    }
    return e.message ?? 'Network error';
  }

  // =============================================
  // High-level models: LoginResponse & OtpResponse
  // =============================================

}

/// Model for Login Response
class LoginResponse {
  final bool? status;
  final String? message;
  final bool? requireOtp;
  final String? accessToken;
  final Map<String, dynamic>? user;

  LoginResponse({this.status, this.message, this.requireOtp, this.accessToken, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('📦 Login Response JSON: $json');

    String? token = json['access_token'] as String? ?? json['token'] as String? ?? json['accessToken'] as String?;

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
