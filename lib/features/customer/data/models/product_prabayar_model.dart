class ProductPrabayar {
  final String productName;
  final String category;
  final String brand;
  final String? iconUrl;
  final String type;
  final int price;
  final int totalHarga;
  final int produkDiskon;
  final int markupMember; // Markup yang ditambahkan member
  final int hargaJualMember; // totalHarga + markupMember
  final String skuCode;
  final int status; // 1 untuk tersedia, 0 untuk gangguan
  final String description;

  ProductPrabayar({
    required this.productName,
    required this.category,
    required this.brand,
    this.iconUrl,
    required this.type,
    required this.price,
    required this.totalHarga,
    required this.produkDiskon,
    required this.markupMember,
    required this.hargaJualMember,
    required this.skuCode,
    required this.status,
    required this.description,
  });

  factory ProductPrabayar.fromJson(Map<String, dynamic> json) {
    final int totalHarga = json['total_harga'] ?? 0;
    final int markupMember = json['markup_member'] ?? 0;
    return ProductPrabayar(
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      iconUrl: json['icon_url'],
      type: json['type'] ?? '',
      price: json['price'] ?? 0,
      totalHarga: totalHarga,
      produkDiskon: json['produk_diskon'] ?? 0,
      markupMember: markupMember,
      hargaJualMember: json['harga_jual_member'] ?? (totalHarga + markupMember),
      skuCode: json['buyer_sku_code'] ?? '',
      status: json['buyer_product_status'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'category': category,
    'brand': brand,
    'icon_url': iconUrl,
    'type': type,
    'price': price,
    'total_harga': totalHarga,
    'produk_diskon': produkDiskon,
    'markup_member': markupMember,
    'harga_jual_member': hargaJualMember,
    'buyer_sku_code': skuCode,
    'buyer_product_status': status,
    'description': description,
  };
}

