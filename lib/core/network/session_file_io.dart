import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Implementation untuk Mobile/Desktop platform
/// Menggunakan dart:io untuk file operations
class SessionFileHelper {
  /// Delete cached splash file from filesystem
  static Future<void> deleteCachedSplash() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/cached_splash.png');
      if (await f.exists()) await f.delete();
      print('🗑️ Cached splash file removed from filesystem if it existed');
    } catch (e) {
      print('⚠️ Failed to remove cached splash file: $e');
    }
  }
}
