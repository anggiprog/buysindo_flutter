// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

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
        debugPrint('[WebHelper] Got subdomain from JS: $subdomain');
        return subdomain;
      }

      // Fallback: parse dari hostname
      final hostname = html.window.location.hostname ?? '';
      debugPrint('[WebHelper] Hostname: $hostname');

      // Parse subdomain dari hostname (misal: toko1.bukatoko.local)
      if (hostname.contains('.bukatoko.')) {
        final parts = hostname.split('.');
        if (parts.isNotEmpty) {
          debugPrint('[WebHelper] Parsed subdomain: ${parts.first}');
          return parts.first;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[WebHelper] Error: $e');
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
      return hostname.contains('bukatoko.online');
    } catch (e) {
      return false;
    }
  }
}
