import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Implementation untuk Mobile/Desktop platform
/// Menggunakan dart:io untuk file operations
class MainIoHelper {
  /// Check if file exists
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Write notification icon to temp file
  static Future<String?> writeNotificationIcon(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/notification_icon_large.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
