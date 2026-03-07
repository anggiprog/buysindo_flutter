import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for Toko Online menus and products
/// Stores data in SharedPreferences for fast access
class TokoOnlineCacheService {
  static const String _keyMenus = 'toko_online_menus';
  static const String _keyProducts = 'toko_online_products';
  static const String _keyMenusTimestamp = 'toko_online_menus_timestamp';
  static const String _keyProductsTimestamp = 'toko_online_products_timestamp';

  // Cache duration in minutes (5 minutes default)
  static const int _cacheDurationMinutes = 5;

  // Singleton
  static final TokoOnlineCacheService _instance =
      TokoOnlineCacheService._internal();
  factory TokoOnlineCacheService() => _instance;
  TokoOnlineCacheService._internal();

  // In-memory cache for faster access
  List<Map<String, dynamic>>? _cachedMenus;
  List<Map<String, dynamic>>? _cachedProducts;
  Map<int, Map<String, dynamic>>? _productById;

  /// Save menus to cache
  Future<void> saveMenus(List<Map<String, dynamic>> menus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(menus);
      await prefs.setString(_keyMenus, jsonString);
      await prefs.setInt(
        _keyMenusTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      _cachedMenus = menus;
      debugPrint('TokoOnlineCache: Saved ${menus.length} menus');
    } catch (e) {
      debugPrint('TokoOnlineCache: Error saving menus: $e');
    }
  }

  /// Get menus from cache
  Future<List<Map<String, dynamic>>?> getMenus() async {
    // Return in-memory cache if available
    if (_cachedMenus != null) {
      return _cachedMenus;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyMenus);

      if (jsonString == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonString);
      _cachedMenus = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      return _cachedMenus;
    } catch (e) {
      debugPrint('TokoOnlineCache: Error getting menus: $e');
      return null;
    }
  }

  /// Save products to cache
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(products);
      await prefs.setString(_keyProducts, jsonString);
      await prefs.setInt(
        _keyProductsTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      _cachedProducts = products;
      _buildProductIndex(products);
      debugPrint('TokoOnlineCache: Saved ${products.length} products');
    } catch (e) {
      debugPrint('TokoOnlineCache: Error saving products: $e');
    }
  }

  /// Get products from cache
  Future<List<Map<String, dynamic>>?> getProducts() async {
    // Return in-memory cache if available
    if (_cachedProducts != null) {
      return _cachedProducts;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyProducts);

      if (jsonString == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonString);
      _cachedProducts = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _buildProductIndex(_cachedProducts!);
      return _cachedProducts;
    } catch (e) {
      debugPrint('TokoOnlineCache: Error getting products: $e');
      return null;
    }
  }

  /// Build product index for fast lookup by ID
  void _buildProductIndex(List<Map<String, dynamic>> products) {
    _productById = {};
    for (final product in products) {
      final id = product['id'] as int?;
      if (id != null) {
        _productById![id] = product;
      }
    }
  }

  /// Get a single product by ID from cache
  Map<String, dynamic>? getProductById(int productId) {
    return _productById?[productId];
  }

  /// Get products filtered by menu ID
  List<Map<String, dynamic>> getProductsByMenuId(int menuId) {
    if (_cachedProducts == null) return [];
    return _cachedProducts!
        .where((p) => p['menu_id'] == menuId || p['parent_id'] == menuId)
        .toList();
  }

  /// Update or add a product in cache
  Future<void> updateProduct(Map<String, dynamic> product) async {
    if (_cachedProducts == null) {
      await getProducts();
    }

    if (_cachedProducts != null) {
      final productId = product['id'] as int?;
      if (productId != null) {
        final index = _cachedProducts!.indexWhere((p) => p['id'] == productId);
        if (index >= 0) {
          _cachedProducts![index] = product;
        } else {
          _cachedProducts!.add(product);
        }
        _productById?[productId] = product;
        await saveProducts(_cachedProducts!);
      }
    }
  }

  /// Add multiple products to cache (merge with existing)
  Future<void> addProducts(List<Map<String, dynamic>> newProducts) async {
    if (_cachedProducts == null) {
      await getProducts();
    }

    _cachedProducts ??= [];

    for (final product in newProducts) {
      final productId = product['id'] as int?;
      if (productId != null) {
        final index = _cachedProducts!.indexWhere((p) => p['id'] == productId);
        if (index >= 0) {
          _cachedProducts![index] = product;
        } else {
          _cachedProducts!.add(product);
        }
      }
    }

    _buildProductIndex(_cachedProducts!);
    await saveProducts(_cachedProducts!);
  }

  /// Check if cache needs refresh
  Future<bool> isCacheValid(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = type == 'menus' ? _keyMenusTimestamp : _keyProductsTimestamp;
      final timestamp = prefs.getInt(key);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final diff = now.difference(cacheTime).inMinutes;

      return diff < _cacheDurationMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMenus);
      await prefs.remove(_keyProducts);
      await prefs.remove(_keyMenusTimestamp);
      await prefs.remove(_keyProductsTimestamp);
      _cachedMenus = null;
      _cachedProducts = null;
      _productById = null;
      debugPrint('TokoOnlineCache: Cache cleared');
    } catch (e) {
      debugPrint('TokoOnlineCache: Error clearing cache: $e');
    }
  }

  /// Force refresh - clear cache and memory
  void invalidateCache() {
    _cachedMenus = null;
    _cachedProducts = null;
    _productById = null;
  }
}

// Global instance for easy access
final tokoOnlineCache = TokoOnlineCacheService();
