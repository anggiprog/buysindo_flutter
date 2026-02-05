import 'dart:typed_data';

/// Stub implementation untuk Web platform
/// File operations tidak tersedia di web
class MainIoHelper {
  /// Check if file exists - always false on web
  static Future<bool> fileExists(String path) async {
    return false;
  }

  /// Write notification icon to temp file - not supported on web
  static Future<String?> writeNotificationIcon(Uint8List bytes) async {
    return null;
  }
}
