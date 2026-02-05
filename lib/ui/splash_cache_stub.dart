import 'dart:typed_data';

/// Stub implementation untuk Web platform
/// File caching tidak tersedia di web
class SplashCacheHelper {
  /// Web tidak mendukung file caching
  static Future<Uint8List?> readCachedFile(String filePath) async {
    return null;
  }

  /// Web tidak mendukung file caching
  static Future<String?> saveCachedFile(List<int> bytes) async {
    return null;
  }
}
