import 'dart:io' show Platform;

/// Implementation for Mobile/Desktop platform
/// Menggunakan dart:io untuk platform detection
class PlatformHelper {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isWindows => Platform.isWindows;
}
