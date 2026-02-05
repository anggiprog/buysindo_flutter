import 'package:flutter/foundation.dart';

// Conditional import - pilih implementasi berdasarkan platform
import 'web_helper_stub.dart' if (dart.library.html) 'web_helper_web.dart';

/// Helper class untuk menangani spesifik Web platform
class WebHelper {
  static String? _cachedSubdomain;

  /// Mendapatkan subdomain dari URL saat ini (hanya untuk Web)
  /// Return null jika bukan di web atau tidak ada subdomain
  static String? getSubdomain() {
    if (!kIsWeb) return null;

    // Return cached value jika sudah ada
    if (_cachedSubdomain != null) return _cachedSubdomain;

    try {
      _cachedSubdomain = WebHelperImpl.getSubdomainFromJs();
      return _cachedSubdomain;
    } catch (e) {
      debugPrint('[WebHelper] Error getting subdomain: $e');
      return null;
    }
  }

  /// Mendapatkan base URL berdasarkan platform
  /// - Web: menggunakan subdomain dari host
  /// - Mobile: menggunakan URL default
  static String getBaseUrl({String defaultUrl = 'https://buysindo.com/'}) {
    if (!kIsWeb) return defaultUrl;

    // Untuk web, gunakan host origin langsung
    final host = WebHelperImpl.getHost();
    if (host != null && host.isNotEmpty) {
      debugPrint('[WebHelper] Using host as baseUrl: $host/');
      return '$host/';
    }

    final subdomain = getSubdomain();
    if (subdomain != null && subdomain.isNotEmpty) {
      // Untuk development lokal
      return 'http://$subdomain.bukatoko.local/';
    }

    return defaultUrl;
  }

  /// Check apakah running di web
  static bool get isWeb => kIsWeb;

  /// Clear cached subdomain (useful untuk testing)
  static void clearCache() {
    _cachedSubdomain = null;
  }
}
