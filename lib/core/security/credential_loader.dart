import 'package:flutter/services.dart';
import '../logger.dart';

/// Helper class untuk load API credentials dengan multiple fallback strategies
class CredentialLoader {
  // Hardcoded credentials as ultimate fallback
  static const String _fallbackApiKey = 'p66uUssUy6jagkT78UsiZcWMxLWR5D70';
  static const String _fallbackApiSecret =
      'VnYFeBtB409q8AQqjIiQqKsemMnOVN11OiBiUFnxWlZJC7c37emAY3obfaN2mdtW';

  /// Load API credentials with multiple fallback strategies
  /// Priority:
  /// 1. Asset file (assets/env_config.txt)
  /// 2. Environment variables (from --dart-define)
  /// 3. Hardcoded fallback
  static Future<Map<String, String>> loadCredentials() async {
    AppLogger.logInfo('[CredentialLoader] Starting credential loading...');

    // Prefer bundled asset config so app and generated build stay in sync.
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
