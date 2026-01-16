import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  /// Constructor dengan inisialisasi baseUrl langsung ke property class
  ApiService(this._dio, {this.baseUrl = 'http://buysindo.com/'}) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    // Di dalam constructor ApiService
    _dio.options.validateStatus = (status) {
      return status! <
          500; // Dio tidak akan "throw error" jika status di bawah 500
    };
  }

  /// Getter untuk URL dasar Gambar
  String get imageBaseUrl => '${baseUrl}storage/images/logo/';

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
}
