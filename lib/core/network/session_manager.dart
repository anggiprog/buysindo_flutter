import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter/material.dart';

// Conditional import for file operations (dart:io not available on web)
import 'session_file_stub.dart' if (dart.library.io) 'session_file_io.dart';

class SessionManager {
  static const String _tokenKey = 'access_token';
  static const String _adminUserIdKey = 'admin_user_id';
  static const String _pendingOtpEmailKey = 'pending_otp_email';

  // Menyimpan token setelah login berhasil
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // 🔴 DEBUG ONLY: Jangan aktifkan di produksi agar token tidak bocor di log
    /*
    
    
    
    
    print('Waktu: ${DateTime.now()}');
    
    */
  }

  // Menyimpan admin_user_id setelah login berhasil
  static Future<void> saveAdminUserId(int adminUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adminUserIdKey, adminUserId);

    // 
    //  
    // 
    //  print('Waktu: ${DateTime.now()}');
    // 
  }

  // Mengambil admin_user_id
  static Future<int?> getAdminUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final adminUserId = prefs.getInt(_adminUserIdKey);

    if (adminUserId != null) {
      // 
      // 
      // 
      // 
      // 
    } else {
      // 
      // 
      // 
      // 
    }

    return adminUserId;
  }

  // Mengambil token saat aplikasi dibuka
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    //// 🔴 DEBUG ONLY: Sembunyikan token di log untuk alasan keamanan

    if (token != null && token.isNotEmpty) {
      ////  
      // 
      //  
      // 
      // 
      //  
    } else {
      // 
      // 
      // 
      // 
    }

    return token;
  }

  // Simpan email yang pending OTP (untuk kasus user keluar app sebelum verifikasi)
  static Future<void> savePendingOtpEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOtpEmailKey, email);
  }

  // Ambil email yang pending OTP
  static Future<String?> getPendingOtpEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingOtpEmailKey);
  }

  // Hapus pending OTP email (setelah berhasil verifikasi)
  static Future<void> clearPendingOtpEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOtpEmailKey);
  }

  // Menghapus token (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_adminUserIdKey);
    await prefs.remove(_pendingOtpEmailKey);

    // 🔴 DEBUG ONLY: Sembunyikan konfirmasi token dihapus jika mengandung data sensitif
    /*
    
    print('🔴 TOKEN DIHAPUS (LOGOUT)');
    if (tokenBefore != null) {
      
    }
    
    print('Waktu: ${DateTime.now()}');
    
    */
  }

  // 🆕 Bonus: Cek status token tanpa mengambilnya
  static Future<bool> isTokenExist() async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.containsKey(_tokenKey);
    // 
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
      final remainingKeys = prefs
          .getKeys()
          .where((k) => k != _tokenKey)
          .toList(growable: false);
      for (final k in remainingKeys) {
        // skip if already removed
        if (!prefs.containsKey(k)) continue;
        await prefs.remove(k);
      }

      // 
      if (token != null && token.isNotEmpty) {
        // print('🔑 Token tetap disimpan (panjang ${token.length})');
      }

      // Delete cached files (splash) if exist in application documents
      await SessionFileHelper.deleteCachedSplash();
    } catch (e) {
      // 
    }
  }
}

