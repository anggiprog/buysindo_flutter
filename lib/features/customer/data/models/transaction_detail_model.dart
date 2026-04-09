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
  final int markupMember;
  final int hargaJualMember;
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
    required this.markupMember,
    required this.hargaJualMember,
    required this.paymentType,
    required this.status,
    required this.tanggalTransaksi,
    required this.namaToko,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    final int totalPrice =
        int.tryParse(json['total_price']?.toString() ?? '0') ?? 0;
    final int markupMember =
        int.tryParse(json['markup_member']?.toString() ?? '0') ?? 0;
    int hargaJualMember =
        int.tryParse(json['harga_jual_member']?.toString() ?? '0') ?? 0;

    // Fallback: jika harga_jual_member = 0, gunakan total_price (untuk transaksi lama)
    if (hargaJualMember == 0) {
      hargaJualMember = totalPrice;
    }

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
      markupMember: markupMember,
      hargaJualMember: hargaJualMember,
      paymentType: json['payment_type'] ?? '',
      status: json['status'] ?? '',
      tanggalTransaksi: json['tanggal_transaksi'] ?? '',
      namaToko: json['nama_toko'] ?? '',
    );
  }

  // Format price dengan separator - menggunakan hargaJualMember
  String get formattedPrice {
    try {
      return 'Rp ${hargaJualMember.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $hargaJualMember';
    }
  }

  // Format harga sebelum diskon (hargaJualMember + diskon)
  String get formattedHargaSebelumDiskon {
    try {
      int discount = int.tryParse(diskon) ?? 0;
      int hargaSebelumDiskon = hargaJualMember + discount;
      return 'Rp ${hargaSebelumDiskon.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $hargaJualMember';
    }
  }

  // Cek apakah ada diskon
  bool get hasDiskon {
    try {
      int discount = int.tryParse(diskon) ?? 0;
      return discount > 0;
    } catch (e) {
      return false;
    }
  }

  // Format markup member
  String get formattedMarkupMember {
    try {
      return 'Rp ${markupMember.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $markupMember';
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

  // Check if transaction is pending
  bool get isPending => status.toUpperCase() == 'PENDING';

  // Check if transaction failed
  bool get isFailed => !isSuccess && !isPending;
}

