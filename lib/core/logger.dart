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
    if (_isLoggingEnabled) {}
  }

  /// Log message penting (error, warning) - SELALU tampilkan di console saat development
  static void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_isLoggingEnabled) {
      if (error != null && stackTrace != null) {
        // Log with error and stacktrace
      } else if (error != null) {
        // Log with error only
      }
    }
  }

  /// Log untuk debugging performa dan flow
  static void logDebug(String message) {
    if (_isLoggingEnabled) {}
  }

  /// Log untuk informasi penting
  static void logInfo(String message) {
    if (_isLoggingEnabled) {}
  }

  /// Check apakah logging enabled (untuk conditional logging)
  static bool get isEnabled => _isLoggingEnabled;
}
