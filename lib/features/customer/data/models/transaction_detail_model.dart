class TransactionDetailResponse {
  final bool status;
  final List<TransactionDetail> data;

  TransactionDetailResponse({required this.status, required this.data});

  factory TransactionDetailResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List?;
    return TransactionDetailResponse(
      status: json['status'] == 'success',
      data: dataList != null
          ? dataList.map((item) => TransactionDetail.fromJson(item)).toList()
          : [],
    );
  }
}

class TransactionDetail {
  final int id;
  final int userId;
  final String refId;
  final String buyerSkuCode;
  final String productName;
  final String nomorHp;
  final String sn;
  final String totalPrice;
  final String diskon;
  final String paymentType;
  final String status;
  final String tanggalTransaksi;
  final String namaToko;

  TransactionDetail({
    required this.id,
    required this.userId,
    required this.refId,
    required this.buyerSkuCode,
    required this.productName,
    required this.nomorHp,
    required this.sn,
    required this.totalPrice,
    required this.diskon,
    required this.paymentType,
    required this.status,
    required this.tanggalTransaksi,
    required this.namaToko,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      refId: json['ref_id'] ?? '',
      buyerSkuCode: json['buyer_sku_code'] ?? '',
      productName: json['product_name'] ?? '',
      nomorHp: json['nomor_hp'] ?? '',
      sn: json['sn'] ?? '',
      totalPrice: json['total_price']?.toString() ?? '0',
      diskon: json['diskon']?.toString() ?? '0',
      paymentType: json['payment_type'] ?? '',
      status: json['status'] ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] ?? '',
      namaToko: json['nama_toko'] ?? '',
    );
  }

  // Format price dengan separator
  String get formattedPrice {
    try {
      int price = int.parse(totalPrice);
      return 'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $totalPrice';
    }
  }

  String get formattedDiskon {
    try {
      int discount = int.parse(diskon);
      if (discount == 0) return '0';
      return 'Rp ${discount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $diskon';
    }
  }

  // Get status color
  bool get isSuccess => status.toUpperCase() == 'SUKSES';
}
