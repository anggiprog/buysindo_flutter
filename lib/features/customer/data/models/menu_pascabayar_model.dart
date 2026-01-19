// Model/MenuPascabayarItem.dart

class MenuPascabayarItem {
  final int id;
  final String namaBrand;
  final String gambarBrand;
  final String? gambarUrl; // 👈 NEW: Full URL dari API

  MenuPascabayarItem({
    required this.id,
    required this.namaBrand,
    required this.gambarBrand,
    this.gambarUrl,
  });

  factory MenuPascabayarItem.fromJson(Map<String, dynamic> json) {
    return MenuPascabayarItem(
      id: json['id'] ?? 0,
      namaBrand: json['nama_brand'] ?? '',
      gambarBrand: json['gambar_brand'] ?? '',
      gambarUrl: json['gambar_url'], // 👈 NEW: Read from API response
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_brand': namaBrand,
      'gambar_brand': gambarBrand,
      'gambar_url': gambarUrl,
    };
  }
}
