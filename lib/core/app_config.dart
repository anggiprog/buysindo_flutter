import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../features/customer/data/models/customer_config_model.dart';
import 'network/api_service.dart';

class AppConfig with ChangeNotifier {
  int _showAppbar = 1;
  int _showNavbar = 1;
  int get showAppbar => _showAppbar;
  int get showNavbar => _showNavbar;
  // --- KONSTANTA KEYS ---
  static const String _keyAppName = 'cfg_app_name';
  static const String _keyPrimaryColor = 'cfg_primary_color';
  static const String _keyTextColor = 'cfg_text_color';
  static const String _keyTemplate = 'cfg_template';
  static const String _keyTampilan = 'cfg_tampilan';
  static const String _keyLogoUrl = 'cfg_logo_url';
  static const String _keySubdomain = 'cfg_subdomain';
  static const String _keyAdminUserId = 'cfg_admin_user_id';

  static const String _adminId = String.fromEnvironment(
    'ADMIN_ID',
    defaultValue: '1050',
  );
  static const String _initialAppType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'app',
  );

  /// Admin token untuk registrasi - HARUS dikonfigurasi dari backend atau --dart-define
  /// JANGAN menulis token asli di sini jika ingin commit ke GitHub publik
  static const String adminToken = String.fromEnvironment(
    'ADMIN_TOKEN',
    defaultValue:
        'your-admin-token-here', // Ganti dengan token asli saat build/release
  );

  // --- STATE VARIABLES ---
  String _appName = "Apk Customer";
  String _appType = _initialAppType;
  String _tampilan = "";
  String _status = "active";
  String? _logoUrl;
  String _subdomain = "";
  String _adminUserId = "1050"; // Default fallback

  Color _primaryColor = const Color(0xFF0D6EFD);
  Color _textColor = Colors.white;

  // --- GETTERS ---
  String get adminId => _adminId;
  String get adminUserId =>
      _adminUserId; // ID dari API response (per subdomain)
  String get appName => _appName;
  String get appType => _appType;
  String get tampilan => _tampilan;
  String get status => _status;
  Color get primaryColor => _primaryColor;
  Color get textColor => _textColor;
  String? get logoUrl => _logoUrl;
  String get subdomain => _subdomain;
  String? get customHtmlUrl => null;

  // --- LOAD DARI SHARED PREFERENCES ---
  Future<void> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();

    _appName = prefs.getString(_keyAppName) ?? _appName;
    _tampilan = prefs.getString(_keyTampilan) ?? _tampilan;
    _logoUrl = prefs.getString(_keyLogoUrl);
    _subdomain = prefs.getString(_keySubdomain) ?? "";
    _adminUserId = prefs.getString(_keyAdminUserId) ?? _adminUserId;

    final hexPrimary = prefs.getString(_keyPrimaryColor);
    if (hexPrimary != null) _primaryColor = _parseColor(hexPrimary);

    final hexText = prefs.getString(_keyTextColor);
    if (hexText != null) _textColor = _parseColor(hexText);

    notifyListeners();
  }

  // --- SIMPAN KE SHARED PREFERENCES ---
  Future<void> _saveToLocal(AppConfigModel model, {String? adminUserId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppName, model.appName);
    await prefs.setString(_keyPrimaryColor, model.primaryColor);
    await prefs.setString(_keyTextColor, model.textColor);
    await prefs.setString(_keyTemplate, model.template);
    await prefs.setString(_keyTampilan, model.tampilan);
    await prefs.setString(_keySubdomain, model.subdomain);
    if (adminUserId != null) {
      await prefs.setString(_keyAdminUserId, adminUserId);
    }
    if (model.logoUrl != null) {
      await prefs.setString(_keyLogoUrl, model.logoUrl!);
    }
  }

  // --- API INITIALIZATION ---
  Future<void> initializeApp(ApiService apiService) async {
    try {
      // debugPrint('🔵 AppConfig.initializeApp START');

      // 1. Cek subdomain dari window (Web)
      String subdomainFromWindow = '';
      if (kIsWeb) {
        subdomainFromWindow = _getSubdomainFromWindow();
        if (subdomainFromWindow.isNotEmpty) {
          // debugPrint('📍 SUBDOMAIN FROM WINDOW: $subdomainFromWindow');
        }
      }

      // 2. Prioritas: Use subdomain endpoint jika ada subdomain
      dynamic responseData;
      String? apiAdminUserId;

      if (subdomainFromWindow.isNotEmpty) {
        // Use subdomain-based endpoint
        // debugPrint(
        //   '🌐 Calling API: getConfigBySubdomain($subdomainFromWindow)',
        // );
        try {
          final response = await apiService
              .getConfigBySubdomain(subdomainFromWindow)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('API call timeout setelah 15 detik');
                },
              );

          // debugPrint('📨 API Response Status: ${response.statusCode}');

          if (response.statusCode == 200 && response.data['data'] != null) {
            responseData = response.data['data'];
            // Extract admin_user_id dari response
            if (responseData is Map) {
              if (responseData.containsKey('admin_user_id')) {
                apiAdminUserId = responseData['admin_user_id'].toString();
                // debugPrint(
                //   '✅ Admin User ID from subdomain endpoint: $apiAdminUserId',
                // );
              }
            }
          }
        } catch (e) {
          // debugPrint('⚠️ Subdomain endpoint failed: $e, trying fallback...');
          responseData = null;
        }
      }

      // 3. Fallback: Gunakan admin ID dari environment atau default
      if (responseData == null) {
        // debugPrint('🔄 Using fallback getPublicConfig endpoint');
        // debugPrint('  Admin ID (Default): $_adminId');
        // debugPrint('  App Type: $_appType');

        final response = await apiService
            .getPublicConfig(_adminId, _appType)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('API call timeout setelah 15 detik');
              },
            );

        // debugPrint('📨 API Response Status: ${response.statusCode}');

        if (response.statusCode == 200 && response.data['data'] != null) {
          responseData = response.data['data'];
        }
      }

      // 4. Parse response dan update config
      if (responseData != null) {
        // debugPrint('✅ API response valid, parsing data...');
        final model = AppConfigModel.fromApi(responseData);

        // Update admin_user_id jika didapat dari API
        if (apiAdminUserId != null) {
          _adminUserId = apiAdminUserId;
        } else {
          // Fallback ke ID dari model jika ada
          _adminUserId = model.id.toString();
        }

        // debugPrint('🔄 Updating AppConfig from model...');
        updateFromModel(model);

        // 5. Simpan ke Local
        // debugPrint('📋 Saving config to SharedPreferences...');
        await _saveToLocal(model, adminUserId: _adminUserId);
        // debugPrint(
        //   '✅ AppConfig.initializeApp COMPLETE (adminUserId: $_adminUserId)',
        // );
      } else {
        // debugPrint('❌ Failed to fetch config from all endpoints');
      }
    } on TimeoutException catch (_) {
      // debugPrint('⏱️ AppConfig Initialize Timeout: $_');
    } catch (_) {
      // debugPrint('❌ AppConfig Initialize Error: $_');
      // debugPrint('📋 Stack trace: ${StackTrace.current}');
    }
  }

  void updateFromModel(AppConfigModel model) {
    try {
      _appName = model.appName;
      _primaryColor = _parseColor(model.primaryColor);
      _textColor = _parseColor(model.textColor);
      _logoUrl = model.logoUrl;
      _subdomain = model.subdomain;
      _appType = model.appType.toLowerCase();
      _tampilan = model.tampilan.trim();
      _status = model.status;

      // Tambahan: showAppbar dan showNavbar
      _showAppbar = model.showAppbar;
      _showNavbar = model.showNavbar;

      // DEBUG: Log tampilan value
      // debugPrint('✅ AppConfig Updated:');
      // debugPrint('  - App Name: $_appName');
      // debugPrint('  - Tampilan: $_tampilan (raw: "${model.tampilan}")');
      // debugPrint('  - Template: ${model.template}');
      // debugPrint('  - showAppbar: $_showAppbar');
      // debugPrint('  - showNavbar: $_showNavbar');

      notifyListeners();
    } catch (e) {
      // debugPrint('Update Model Failed: $e');
    }
  }

  // --- HELPER PARSE COLOR ---
  static Color _parseColor(String hex) {
    try {
      // Handle empty or null hex
      if (hex.isEmpty) {
        // debugPrint('⚠️ Empty hex color, using default blue');
        return const Color(0xFF0D6EFD);
      }

      final cleanHex = hex.replaceAll('#', '').padLeft(8, 'FF');
      String formatHex = cleanHex.length > 8
          ? cleanHex.substring(cleanHex.length - 8)
          : cleanHex;

      final parsedColor = Color(int.parse(formatHex, radix: 16));

      // Check if color is completely transparent or black
      if (parsedColor.value == 0 || parsedColor.alpha == 0) {
        // debugPrint('⚠️ Invalid color (transparent/black), using default blue');
        return const Color(0xFF0D6EFD);
      }

      return parsedColor;
    } catch (e) {
      // debugPrint('⚠️ Failed to parse color "$hex": $e, using default blue');
      return const Color(0xFF0D6EFD); // Default Blue
    }
  }

  /// Membaca subdomain dari hostname
  /// Contoh: demo.bukatoko.local --> "demo"
  /// Contoh: jastipku.bukatoko.local --> "jastipku"
  /// Hanya bekerja di web platform
  String _getSubdomainFromWindow() {
    try {
      if (!kIsWeb) {
        return '';
      }

      // Extract subdomain dari URL hostname
      final Uri currentUri = Uri.base; // Gets current page URL
      final hostname = currentUri.host;
      // debugPrint('📍 Current hostname (from Uri.base): $hostname');

      if (hostname.isNotEmpty && !hostname.startsWith('localhost')) {
        // Split by dots
        final parts = hostname.split('.');
        if (parts.length >= 2 && parts[0].isNotEmpty) {
          final subdomain = parts.first;
          // Validasi: subdomain harus alphanumeric dan tidak "www"
          if (subdomain != 'www' &&
              RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(subdomain)) {
            // debugPrint('✅ Subdomain extracted from hostname: $subdomain');
            return subdomain;
          }
        }
      }

      // debugPrint('⚠️ No subdomain found - using default adminId');
      return '';
    } catch (e) {
      // debugPrint('❌ Error in _getSubdomainFromWindow: $e');
      return '';
    }
  }
}

// Singleton instance
final appConfig = AppConfig();
