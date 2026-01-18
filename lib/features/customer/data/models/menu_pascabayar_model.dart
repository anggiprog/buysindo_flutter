// Model/MenuPascabayarItem.dart

class MenuPascabayarItem {
  final int id;
  final String namaBrand;
  final String gambarBrand;

  MenuPascabayarItem({
    required this.id,
    required this.namaBrand,
    required this.gambarBrand,
  });

  factory MenuPascabayarItem.fromJson(Map<String, dynamic> json) {
    return MenuPascabayarItem(
      id: json['id'] ?? 0,
      namaBrand: json['nama_brand'] ?? '',
      gambarBrand: json['gambar_brand'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_brand': namaBrand, 'gambar_brand': gambarBrand};
  }
}
