// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// Helper class untuk Web platform
class WebHelperImpl {
  /// Mendapatkan subdomain dari JavaScript window.APP_SUBDOMAIN
  /// yang di-inject oleh Laravel
  static String? getSubdomainFromJs() {
    try {
      // Coba ambil dari window.APP_SUBDOMAIN yang di-inject Laravel
      final appSubdomain = js.context['APP_SUBDOMAIN'];
      if (appSubdomain != null) {
        final subdomain = appSubdomain.toString();

        return subdomain;
      }

      // Fallback: parse dari hostname
      final hostname = html.window.location.hostname ?? '';

      // Parse subdomain dari hostname (misal: toko1.bukatoko.local)
      if (hostname.contains('.bukatoko.')) {
        final parts = hostname.split('.');
        if (parts.isNotEmpty) {
          return parts.first;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get full host dengan protocol
  static String? getHost() {
    try {
      return html.window.location.origin;
    } catch (e) {
      return null;
    }
  }

  /// Get current URL path
  static String? getPath() {
    try {
      return html.window.location.pathname;
    } catch (e) {
      return null;
    }
  }

  /// Get hostname only (tanpa protocol)
  static String? getHostname() {
    try {
      return html.window.location.hostname;
    } catch (e) {
      return null;
    }
  }

  /// Check apakah production (bukatoko.online)
  static bool isProduction() {
    try {
      final hostname = html.window.location.hostname ?? '';

      final isProd = hostname.contains('bukatoko.online');

      return isProd;
    } catch (e) {
      return false;
    }
  }

  /// Detailed logging untuk debugging
  static void logDebugInfo() {
    try {
      final origin = html.window.location.origin;
      final hostname = html.window.location.hostname;
      final protocol = html.window.location.protocol;
      final href = html.window.location.href;
    } catch (e) {}
  }
}
