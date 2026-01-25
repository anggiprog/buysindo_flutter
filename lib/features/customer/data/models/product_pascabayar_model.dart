class ProductPascabayarResponse {
  final bool status;
  final String message;
  final String paket;
  final String limit;
  final int total;
  final int totalPascabayar;
  final List<ProductPascabayar> products;

  ProductPascabayarResponse({
    required this.status,
    required this.message,
    required this.paket,
    required this.limit,
    required this.total,
    required this.totalPascabayar,
    required this.products,
  });

  factory ProductPascabayarResponse.fromJson(Map<String, dynamic> json) {
    return ProductPascabayarResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      paket: json['paket'] ?? '',
      limit: json['limit']?.toString() ?? '',
      total: json['total'] ?? 0,
      totalPascabayar: json['total_pascabayar'] ?? 0,
      products:
          (json['products'] as List<dynamic>?)
              ?.map(
                (e) => ProductPascabayar.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'paket': paket,
      'limit': limit,
      'total': total,
      'total_pascabayar': totalPascabayar,
      'products': products.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductPascabayar {
  final String productName;
  final String buyerSkuCode;
  final String admin;
  final String commission;
  final String category;
  final String brand;
  final String sellerName;
  final String price;
  final String adminFee;
  final String markupAdmin;
  final String produkDiskon;
  final String totalHarga;
  final bool buyerProductStatus;
  final bool sellerProductStatus;
  final String desc;

  ProductPascabayar({
    required this.productName,
    required this.buyerSkuCode,
    required this.admin,
    required this.commission,
    required this.category,
    required this.brand,
    required this.sellerName,
    required this.price,
    required this.adminFee,
    required this.markupAdmin,
    required this.produkDiskon,
    required this.totalHarga,
    required this.buyerProductStatus,
    required this.sellerProductStatus,
    required this.desc,
  });

  factory ProductPascabayar.fromJson(Map<String, dynamic> json) {
    return ProductPascabayar(
      productName: json['product_name'] ?? '',
      buyerSkuCode: json['buyer_sku_code'] ?? '',
      admin: json['admin']?.toString() ?? '0',
      commission: json['commission']?.toString() ?? '0',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      sellerName: json['seller_name'] ?? '',
      price: json['price']?.toString() ?? '0',
      adminFee: json['admin_fee']?.toString() ?? '0',
      markupAdmin: json['markup_admin']?.toString() ?? '0',
      produkDiskon: json['produk_diskon']?.toString() ?? '0',
      totalHarga: json['total_harga']?.toString() ?? '0',
      buyerProductStatus: json['buyer_product_status'] ?? false,
      sellerProductStatus: json['seller_product_status'] ?? false,
      desc: json['desc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'buyer_sku_code': buyerSkuCode,
      'admin': admin,
      'commission': commission,
      'category': category,
      'brand': brand,
      'seller_name': sellerName,
      'price': price,
      'admin_fee': adminFee,
      'markup_admin': markupAdmin,
      'produk_diskon': produkDiskon,
      'total_harga': totalHarga,
      'buyer_product_status': buyerProductStatus,
      'seller_product_status': sellerProductStatus,
      'desc': desc,
    };
  }
}

class BillCheckResponse {
  final String status;
  final String message;
  final String refId;
  final String productName;
  final String buyerSkuCode;
  final String brand;
  final String customerName;
  final String customerNo;
  final String periode;
  final int tagihan;
  final int admin;
  final int denda;
  final int totalTagihan;
  final int lembarTagihan;

  BillCheckResponse({
    required this.status,
    required this.message,
    required this.refId,
    required this.productName,
    required this.buyerSkuCode,
    required this.brand,
    required this.customerName,
    required this.customerNo,
    required this.periode,
    required this.tagihan,
    required this.admin,
    required this.denda,
    required this.totalTagihan,
    required this.lembarTagihan,
  });

  factory BillCheckResponse.fromJson(Map<String, dynamic> json) {
    return BillCheckResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      refId: json['ref_id'] ?? '',
      productName: json['product_name'] ?? '',
      buyerSkuCode: json['buyer_sku_code'] ?? '',
      brand: json['brand'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerNo: json['customer_no'] ?? '',
      periode: json['periode'] ?? '',
      tagihan: json['tagihan'] ?? 0,
      admin: json['admin'] ?? 0,
      denda: json['denda'] ?? 0,
      totalTagihan: json['total_tagihan'] ?? 0,
      lembarTagihan: json['lembar_tagihan'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'ref_id': refId,
      'product_name': productName,
      'buyer_sku_code': buyerSkuCode,
      'brand': brand,
      'customer_name': customerName,
      'customer_no': customerNo,
      'periode': periode,
      'tagihan': tagihan,
      'admin': admin,
      'denda': denda,
      'total_tagihan': totalTagihan,
      'lembar_tagihan': lembarTagihan,
    };
  }
}
