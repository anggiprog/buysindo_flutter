import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SessionManager {
  static const String _tokenKey = 'access_token';

  // Menyimpan token setelah login berhasil
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // 🔴 LOG: Tampilkan token yang disimpan
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('✅ TOKEN DISIMPAN');
    debugPrint('Token: $token');
    debugPrint('Panjang Token: ${token.length}');
    debugPrint('Waktu: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════════════════');
  }

  // Mengambil token saat aplikasi dibuka
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // 🔴 LOG: Tampilkan token saat diambil
    if (token != null && token.isNotEmpty) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('🔑 TOKEN DIAMBIL');
      debugPrint('Token: $token');
      debugPrint('Panjang Token: ${token.length}');
      debugPrint('Status: ✅ Ada');
      debugPrint('═══════════════════════════════════════════════════');
    } else {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ TOKEN TIDAK DITEMUKAN');
      debugPrint('Status: Token kosong atau tidak tersimpan');
      debugPrint('═══════════════════════════════════════════════════');
    }

    return token;
  }

  // Menghapus token (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenBefore = prefs.getString(_tokenKey);

    await prefs.remove(_tokenKey);

    // 🔴 LOG: Konfirmasi token dihapus
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔴 TOKEN DIHAPUS (LOGOUT)');
    if (tokenBefore != null) {
      debugPrint('Token sebelumnya: $tokenBefore');
    }
    debugPrint('Status: ✅ Cleared');
    debugPrint('Waktu: ${DateTime.now()}');
    debugPrint('═══════════════════════════════════════════════════');
  }

  // 🆕 Bonus: Cek status token tanpa mengambilnya
  static Future<bool> isTokenExist() async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.containsKey(_tokenKey);
    debugPrint('🔍 CEK TOKEN: ${exists ? "✅ Ada" : "❌ Tidak ada"}');
    return exists;
  }

  /// Hapus semua data SharedPreferences kecuali token login.
  /// Digunakan untuk fitur 'Hapus Data Cache' agar tidak memaksa logout.
  static Future<void> clearCacheExceptToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil token (jika ada) supaya bisa dipertahankan
      final token = prefs.getString(_tokenKey);

      // Remove well-known cache keys used across app
      final knownKeys = <String>[
        'cached_products',
        'cached_splash_file',
        'cached_splash_url',
        'cached_splash_tagline',
        'cached_splash_updated_at',
        // Add other known keys here if needed
      ];

      for (final k in knownKeys) {
        if (prefs.containsKey(k)) await prefs.remove(k);
      }

      // Remove any keys that match `brand_*`
      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        if (k == _tokenKey) continue;
        if (k.startsWith('brand_')) {
          await prefs.remove(k);
        }
      }

      // Also remove any other keys except token (fallback behavior)
      final remainingKeys = prefs.getKeys().where((k) => k != _tokenKey).toList(growable: false);
      for (final k in remainingKeys) {
        // skip if already removed
        if (!prefs.containsKey(k)) continue;
        await prefs.remove(k);
      }

      debugPrint('🧹 SharedPreferences cleared except token');
      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 Token tetap disimpan (panjang ${token.length})');
      }

      // Delete cached files (splash) if exist in application documents
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/cached_splash.png');
        if (await f.exists()) await f.delete();
        debugPrint('🗑️ Cached splash file removed from filesystem if it existed');
      } catch (e) {
        debugPrint('⚠️ Failed to remove cached splash file: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache except token: $e');
    }
  }
}
