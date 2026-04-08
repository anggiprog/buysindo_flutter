import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Custom logger untuk mengelola debug output
/// Di web dan production, semua log akan dinonaktifkan untuk security
class AppLogger {
  static bool _isLoggingEnabled = false;

  static void initialize() {
    // Hanya enable logging di development mode (bukan web dan bukan production)
    _isLoggingEnabled = kDebugMode && !kIsWeb;
  }

  /// Log message normal
  static void log(String message) {
    if (_isLoggingEnabled) {
      print(message);
    }
  }

  /// Log message penting (error, warning) - SELALU tampilkan di console saat development
  static void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_isLoggingEnabled) {
      print('❌ ERROR: $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }

  /// Log untuk debugging performa dan flow
  static void logDebug(String message) {
    if (_isLoggingEnabled) {
      print('🔧 DEBUG: $message');
    }
  }

  /// Log untuk informasi penting
  static void logInfo(String message) {
    if (_isLoggingEnabled) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Check apakah logging enabled (untuk conditional logging)
  static bool get isEnabled => _isLoggingEnabled;
}
