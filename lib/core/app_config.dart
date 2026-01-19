import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../features/customer/data/models/customer_config_model.dart';
import 'network/api_service.dart';

class AppConfig with ChangeNotifier {
  // --- KONSTANTA KEYS ---
  static const String _keyAppName = 'cfg_app_name';
  static const String _keyPrimaryColor = 'cfg_primary_color';
  static const String _keyTextColor = 'cfg_text_color';
  static const String _keyTemplate = 'cfg_template';
  static const String _keyTampilan = 'cfg_tampilan';
  static const String _keyLogoUrl = 'cfg_logo_url';

  static const String _adminId = String.fromEnvironment(
    'ADMIN_ID',
    defaultValue: '1050',
  );
  static const String _initialAppType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'app',
  );

  // --- STATE VARIABLES ---
  String _appName = "Apk Customer";
  String _appType = _initialAppType;
  String _tampilan = "";
  String _status = "active";
  String? _logoUrl;

  Color _primaryColor = const Color(0xFF0D6EFD);
  Color _textColor = Colors.white;

  // --- GETTERS ---
  String get adminId => _adminId;
  String get appName => _appName;
  String get appType => _appType;
  String get tampilan => _tampilan;
  String get status => _status;
  Color get primaryColor => _primaryColor;
  Color get textColor => _textColor;
  String? get logoUrl => _logoUrl;

  // --- LOAD DARI SHARED PREFERENCES ---
  Future<void> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();

    _appName = prefs.getString(_keyAppName) ?? _appName;
    _tampilan = prefs.getString(_keyTampilan) ?? _tampilan;
    _logoUrl = prefs.getString(_keyLogoUrl);

    final hexPrimary = prefs.getString(_keyPrimaryColor);
    if (hexPrimary != null) _primaryColor = _parseColor(hexPrimary);

    final hexText = prefs.getString(_keyTextColor);
    if (hexText != null) _textColor = _parseColor(hexText);

    notifyListeners();
  }

  // --- SIMPAN KE SHARED PREFERENCES ---
  Future<void> _saveToLocal(AppConfigModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppName, model.appName);
    await prefs.setString(_keyPrimaryColor, model.primaryColor);
    await prefs.setString(_keyTextColor, model.textColor);
    await prefs.setString(_keyTemplate, model.template);
    await prefs.setString(_keyTampilan, model.tampilan);
    if (model.logoUrl != null) {
      await prefs.setString(_keyLogoUrl, model.logoUrl!);
    }
  }

  // --- API INITIALIZATION ---
  Future<void> initializeApp(ApiService apiService) async {
    try {
      debugPrint('🔵 AppConfig.initializeApp START');
      debugPrint('  Admin ID: $_adminId');
      debugPrint('  App Type: $_appType');

      // 1. Ambil data dari API dengan timeout
      debugPrint('🌐 Calling API: getPublicConfig($_adminId, $_appType)');
      final response = await apiService
          .getPublicConfig(_adminId, _appType)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('API call timeout setelah 15 detik');
            },
          );

      debugPrint('📨 API Response Status: ${response.statusCode}');
      debugPrint('📨 API Response Body: ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        debugPrint('✅ API response valid, parsing data...');
        final model = AppConfigModel.fromApi(response.data['data']);

        // 2. Update State & Notify UI
        debugPrint('🔄 Updating AppConfig from model...');
        updateFromModel(model);

        // 3. Simpan ke Local untuk penggunaan berikutnya (Offline/Fast Load)
        debugPrint('💾 Saving config to SharedPreferences...');
        await _saveToLocal(model);
        debugPrint('✅ AppConfig.initializeApp COMPLETE');
      } else {
        debugPrint(
          '❌ API response invalid: statusCode=${response.statusCode}, data=${response.data}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ AppConfig Initialize Timeout: $e');
    } catch (e) {
      debugPrint('❌ AppConfig Initialize Error: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
    }
  }

  void updateFromModel(AppConfigModel model) {
    try {
      _appName = model.appName;
      _primaryColor = _parseColor(model.primaryColor);
      _textColor = _parseColor(model.textColor);
      _logoUrl = model.logoUrl;
      _appType = model.appType.toLowerCase();
      _tampilan = model.tampilan.trim();
      _status = model.status;

      // DEBUG: Log tampilan value
      debugPrint('✅ AppConfig Updated:');
      debugPrint('  - App Name: $_appName');
      debugPrint('  - Tampilan: $_tampilan (raw: "${model.tampilan}")');
      debugPrint('  - Template: ${model.template}');

      notifyListeners();
    } catch (e) {
      debugPrint('Update Model Failed: $e');
    }
  }

  // --- HELPER PARSE COLOR ---
  static Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '').padLeft(8, 'FF');
      String formatHex = cleanHex.length > 8
          ? cleanHex.substring(cleanHex.length - 8)
          : cleanHex;
      return Color(int.parse(formatHex, radix: 16));
    } catch (e) {
      return const Color(0xFF0D6EFD); // Default Blue
    }
  }
}

// Singleton instance
final appConfig = AppConfig();
