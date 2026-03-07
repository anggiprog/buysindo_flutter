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
    debugPrint('🔍 [WebHelper.getBaseUrl] Host detected: $host');

    if (host != null && host.isNotEmpty) {
      debugPrint('✅ [WebHelper.getBaseUrl] Using host as baseUrl: $host/');
      return '$host/';
    }

    debugPrint(
      '⚠️ [WebHelper.getBaseUrl] No host detected, trying subdomain...',
    );

    final subdomain = getSubdomain();
    debugPrint('🔍 [WebHelper.getBaseUrl] Subdomain detected: $subdomain');

    if (subdomain != null && subdomain.isNotEmpty) {
      // Detect production vs local berdasarkan hostname
      final isProduction = WebHelperImpl.isProduction();
      if (isProduction) {
        final url = 'https://$subdomain.bukatoko.online/';
        debugPrint('✅ [WebHelper.getBaseUrl] Production mode: $url');
        return url;
      }
      // Development lokal
      final url = 'http://$subdomain.bukatoko.local/';
      debugPrint('✅ [WebHelper.getBaseUrl] Local mode: $url');
      return url;
    }

    debugPrint('❌ [WebHelper.getBaseUrl] Fallback to default: $defaultUrl');
    return defaultUrl;
  }

  /// Check apakah running di web
  static bool get isWeb => kIsWeb;

  /// Clear cached subdomain (useful untuk testing)
  static void clearCache() {
    _cachedSubdomain = null;
  }
}
