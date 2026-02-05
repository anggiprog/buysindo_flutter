/// Stub implementation untuk Web platform
/// File operations tidak tersedia di web
class SessionFileHelper {
  /// Delete cached splash file - not supported on web
  static Future<void> deleteCachedSplash() async {
    // No-op on web
  }
}
