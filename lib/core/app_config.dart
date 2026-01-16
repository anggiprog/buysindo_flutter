import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/customer/data/models/customer_config_model.dart';
import 'network/api_service.dart';

class AppConfig with ChangeNotifier {
  // --- KONSTANTA KEYS ---
  static const String _keyAppName = 'cfg_app_name';
  static const String _keyPrimaryColor = 'cfg_primary_color';
  static const String _keyTextColor = 'cfg_text_color';
  static const String _keyTemplate = 'cfg_template';
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
  String _template = "";
  String _status = "active";
  String? _logoUrl;

  Color _primaryColor = const Color(0xFF0D6EFD);
  Color _textColor = Colors.white;

  // --- GETTERS ---
  String get adminId => _adminId;
  String get appName => _appName;
  String get appType => _appType;
  String get template => _template;
  String get status => _status;
  Color get primaryColor => _primaryColor;
  Color get textColor => _textColor;
  String? get logoUrl => _logoUrl;

  // --- LOAD DARI SHARED PREFERENCES ---
  Future<void> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();

    _appName = prefs.getString(_keyAppName) ?? _appName;
    _template = prefs.getString(_keyTemplate) ?? _template;
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
    if (model.logoUrl != null) {
      await prefs.setString(_keyLogoUrl, model.logoUrl!);
    }
  }

  // --- API INITIALIZATION ---
  Future<void> initializeApp(ApiService apiService) async {
    try {
      // 1. Ambil data dari API
      final response = await apiService.getPublicConfig(_adminId, _appType);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final model = AppConfigModel.fromApi(response.data['data']);

        // 2. Update State & Notify UI
        updateFromModel(model);

        // 3. Simpan ke Local untuk penggunaan berikutnya (Offline/Fast Load)
        await _saveToLocal(model);
      }
    } catch (e) {
      debugPrint('AppConfig Initialize Error: $e');
    }
  }

  void updateFromModel(AppConfigModel model) {
    try {
      _appName = model.appName;
      _primaryColor = _parseColor(model.primaryColor);
      _textColor = _parseColor(model.textColor);
      _logoUrl = model.logoUrl;
      _appType = model.appType.toLowerCase();
      _template = model.template.trim();
      _status = model.status;

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
