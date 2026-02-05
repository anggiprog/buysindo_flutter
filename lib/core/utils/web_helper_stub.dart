/// Stub implementation untuk non-web platforms (mobile)
class WebHelperImpl {
  /// Tidak ada subdomain di mobile
  static String? getSubdomainFromJs() => null;

  /// Tidak ada host di mobile context
  static String? getHost() => null;

  /// Tidak ada path di mobile context
  static String? getPath() => null;

  /// Tidak ada hostname di mobile context
  static String? getHostname() => null;

  /// Mobile bukan production web
  static bool isProduction() => false;
}
