import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'session_manager.dart';

/// Comprehensive Authentication Service
/// Handles Firebase device tokens, login, OTP verification, and token management
class AuthService {
  final Dio _dio;

  AuthService(this._dio, {String baseUrl = 'http://buysindo.com/api/'}) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Get Firebase Device Token safely
  Future<String> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? 'unknown_device_token';
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return 'error_getting_token';
    }
  }

  /// Login user with email and password
  /// Returns response with user data or OTP requirement
  Future<LoginResponse> login(String email, String password) async {
    try {
      final deviceToken = await getDeviceToken();

      final response = await _dio.post(
        'login',
        data: {
          'email': email,
          'password': password,
          'device_token': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify OTP code
  Future<OtpResponse> verifyOtp(String email, String otpCode) async {
    try {
      final deviceToken = await getDeviceToken();

      final response = await _dio.post(
        'verify-otp',
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
      final response = await _dio.post('resend-otp', data: {'email': email});

      if (response.statusCode != 200) {
        throw Exception('Resend OTP failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get user profile
  Future<dynamic> getProfile(String token) async {
    try {
      final response = await _dio.get(
        'user/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Logout user
  Future<void> logout(String token) async {
    try {
      await _dio.post(
        'logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await SessionManager.clearSession();
    } on DioException catch (e) {
      // Clear token anyway even if logout fails
      await SessionManager.clearSession();
      throw _handleDioError(e);
    }
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
    // Debug: Print seluruh response untuk melihat struktur API
    debugPrint('📦 Login Response JSON: $json');

    // Coba ambil token dari berbagai field yang mungkin
    String? token =
        json['access_token'] as String? ??
        json['token'] as String? ??
        json['accessToken'] as String?;

    debugPrint(
      '🔍 Token field - access_token: ${json['access_token']}, token: ${json['token']}, accessToken: ${json['accessToken']}',
    );
    debugPrint('✨ Final token value: $token');

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
