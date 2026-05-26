import 'package:flutter/services.dart';
import '../logger.dart';

/// Helper class untuk load API credentials dengan multiple fallback strategies
class CredentialLoader {
  // Hardcoded credentials as ultimate fallback
  static const String _fallbackApiKey = 'p66uUssUy6jagkT78UsiZcWMxLWR5D70';
  static const String _fallbackApiSecret =
      'VnYFeBtB409q8AQqjIiQqKsemMnOVN11OiBiUFnxWlZJC7c37emAY3obfaN2mdtW';

  // Store external credentials (loaded from config endpoint)
  static String? _externalApiKey;
  static String? _externalApiSecret;

  /// Set credentials from external source (config endpoint)
  static void setExternalCredentials(String? apiKey, String? apiSecret) {
    _externalApiKey = apiKey;
    _externalApiSecret = apiSecret;
    if (apiKey != null && apiSecret != null) {
      AppLogger.logInfo(
        '[CredentialLoader] External credentials set from config | Key: ${apiKey.substring(0, 20)}... | Secret: ${apiSecret.substring(0, 20)}...',
      );
    }
  }

  /// Fetch credentials for a specific admin/subdomain from backend
  /// This should be called before registration to get the correct admin's credentials
  ///
  /// Parameters:
  /// - apiService: The API service instance to make HTTP requests
  /// - subdomain: The subdomain to get credentials for (optional)
  /// - adminUserId: The admin user ID to get credentials for (optional)
  static Future<bool> fetchAndSetAdminCredentials(
    dynamic apiService, {
    String? subdomain,
    String? adminUserId,
  }) async {
    try {
      AppLogger.logInfo(
        '[CredentialLoader.fetchAndSetAdminCredentials] Fetching admin credentials | subdomain: $subdomain, adminUserId: $adminUserId',
      );

      // Make API call to get admin credentials
      final response = await apiService.getAdminCredentials(
        subdomain: subdomain,
        adminUserId: adminUserId,
      );

      if (response.statusCode == 200 &&
          response.data['error'] == false &&
          response.data['data'] != null) {
        final data = response.data['data'];
        final apiKey = data['api_key'] as String?;
        final apiSecret = data['api_secret'] as String?;

        if (apiKey != null &&
            apiKey.isNotEmpty &&
            apiSecret != null &&
            apiSecret.isNotEmpty) {
          setExternalCredentials(apiKey, apiSecret);
          AppLogger.logInfo(
            '[CredentialLoader.fetchAndSetAdminCredentials] SUCCESS | Admin ID: ${data['admin_user_id']}, Username: ${data['username']}',
          );
          return true;
        }
      }

      AppLogger.logError(
        '[CredentialLoader.fetchAndSetAdminCredentials] FAILED | Response: ${response.data}',
      );
      return false;
    } catch (e) {
      AppLogger.logError(
        '[CredentialLoader.fetchAndSetAdminCredentials] Exception: $e',
      );
      return false;
    }
  }

  /// Load API credentials with multiple fallback strategies
  /// Priority:
  /// 1. External credentials (from config endpoint - for dynamic admin support)
  /// 2. Asset file (assets/env_config.txt)
  /// 3. Environment variables (from --dart-define)
  /// 4. Hardcoded fallback
  static Future<Map<String, String>> loadCredentials() async {
    AppLogger.logInfo('[CredentialLoader] Starting credential loading...');

    // PRIORITY 1: External credentials (set from config endpoint)
    if (_externalApiKey != null &&
        _externalApiKey!.isNotEmpty &&
        _externalApiSecret != null &&
        _externalApiSecret!.isNotEmpty) {
      AppLogger.logInfo(
        '[CredentialLoader] Loaded from external config | Key: ${_externalApiKey!.substring(0, 20)}... | Secret: ${_externalApiSecret!.substring(0, 20)}...',
      );
      return {
        'apiKey': _externalApiKey!,
        'apiSecret': _externalApiSecret!,
        'source': 'external_config',
      };
    }

    // PRIORITY 2: Prefer bundled asset config so app and generated build stay in sync.
    try {
      final envContent = await rootBundle.loadString('assets/env_config.txt');
      final credentials = _parseEnvFile(envContent);

      if (credentials.isNotEmpty &&
          credentials['API_KEY']!.isNotEmpty &&
          credentials['API_SECRET']!.isNotEmpty) {
        AppLogger.logInfo(
          '[CredentialLoader] Loaded from assets/env_config.txt | Key: ${credentials['API_KEY']!.substring(0, 20)}... | Secret: ${credentials['API_SECRET']!.substring(0, 20)}...',
        );
        return {
          'apiKey': credentials['API_KEY']!,
          'apiSecret': credentials['API_SECRET']!,
          'source': 'assets',
        };
      }
    } catch (e) {
      AppLogger.logError('[CredentialLoader] Could not load from assets: $e');
    }

    // PRIORITY 3: Environment variables
    final envApiKey = const String.fromEnvironment('API_KEY', defaultValue: '');
    final envApiSecret = const String.fromEnvironment(
      'API_SECRET',
      defaultValue: '',
    );

    if (envApiKey.isNotEmpty && envApiSecret.isNotEmpty) {
      AppLogger.logInfo(
        '[CredentialLoader] Loaded from environment variables | Key: ${envApiKey.substring(0, 20)}... | Secret: ${envApiSecret.substring(0, 20)}...',
      );
      return {
        'apiKey': envApiKey,
        'apiSecret': envApiSecret,
        'source': 'environment',
      };
    }

    // PRIORITY 4: Hardcoded fallback
    AppLogger.logError(
      '[CredentialLoader] Using hardcoded fallback credentials | Key: ${_fallbackApiKey.substring(0, 20)}... | Secret: ${_fallbackApiSecret.substring(0, 20)}...',
    );
    return {
      'apiKey': _fallbackApiKey,
      'apiSecret': _fallbackApiSecret,
      'source': 'hardcoded',
    };
  }

  /// Parse env_config.txt format
  static Map<String, String> _parseEnvFile(String content) {
    final result = <String, String>{};
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final parts = trimmed.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        result[key] = value;
      }
    }

    return result;
  }

  /// Debug function to verify loaded credentials
  static Future<void> verifyCredentials({
    required String apiKey,
    required String apiSecret,
  }) async {
    AppLogger.logInfo('[CredentialLoader.verify] Credential Verification:');
    AppLogger.logInfo('  API Key:    ${apiKey.substring(0, 20)}...');
    AppLogger.logInfo('  API Secret: ${apiSecret.substring(0, 20)}...');
    AppLogger.logInfo('  Key length: ${apiKey.length}');
    AppLogger.logInfo('  Secret length: ${apiSecret.length}');

    if (!_isValidApiKey(apiKey)) {
      AppLogger.logError('  API Key format looks invalid!');
    }
    if (!_isValidApiSecret(apiSecret)) {
      AppLogger.logError('  API Secret format looks invalid!');
    }
  }

  static bool _isValidApiKey(String key) {
    return key.length == 32 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(key);
  }

  static bool _isValidApiSecret(String secret) {
    return secret.length == 64 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(secret);
  }
}
