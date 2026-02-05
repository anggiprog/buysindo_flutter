import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// IO implementation untuk Mobile platform (Android/iOS)
/// File caching tersedia di mobile
class SplashCacheHelper {
  /// Read cached file dari filesystem
  static Future<Uint8List?> readCachedFile(String filePath) async {
    try {
      final f = File(filePath);
      if (await f.exists()) {
        return await f.readAsBytes();
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Save file ke filesystem, return path
  static Future<String?> saveCachedFile(List<int> bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cached_splash.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
