import 'package:flutter/foundation.dart';

class MenuPrabayarItem {
  final int id;
  final int urutan;
  final int adminUserId;
  final String namaKategori;
  final String gambarKategori;
  final String? iconTemplate;
  final String createdAt;
  final String updatedAt;

  MenuPrabayarItem({
    required this.id,
    required this.urutan,
    required this.adminUserId,
    required this.namaKategori,
    required this.gambarKategori,
    this.iconTemplate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuPrabayarItem.fromJson(Map<String, dynamic> json) {
    return MenuPrabayarItem(
      id: json['id'] ?? 0,
      urutan: json['urutan'] ?? 0,
      adminUserId: json['admin_user_id'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      gambarKategori: json['gambar_kategori'] ?? '',
      iconTemplate: json['icon_template'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class MenuPrabayarResponse {
  final List<MenuPrabayarItem> menus;

  MenuPrabayarResponse({required this.menus});

  factory MenuPrabayarResponse.fromJson(dynamic json) {
    List<MenuPrabayarItem> menusList = [];

    try {
      // Case 1: Response adalah List langsung
      if (json is List) {
        menusList = List<MenuPrabayarItem>.from(
          json.map(
            (item) => MenuPrabayarItem.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : item,
            ),
          ),
        );
      }
      // Case 2: Response adalah Map dengan key 'data'
      else if (json is Map && json['data'] is List) {
        menusList = List<MenuPrabayarItem>.from(
          (json['data'] as List).map(
            (item) => MenuPrabayarItem.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : item,
            ),
          ),
        );
      }
      // Case 3: Response adalah Map dengan key 'menus'
      else if (json is Map && json['menus'] is List) {
        menusList = List<MenuPrabayarItem>.from(
          (json['menus'] as List).map(
            (item) => MenuPrabayarItem.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : item,
            ),
          ),
        );
      }
      // Case 4: Response adalah Map langsung (untuk single object)
      else if (json is Map) {
        menusList = [
          MenuPrabayarItem.fromJson(Map<String, dynamic>.from(json)),
        ];
      }
    } catch (e) {
      debugPrint('Error parsing MenuPrabayarResponse: $e');
    }

    return MenuPrabayarResponse(menus: menusList);
  }
}
