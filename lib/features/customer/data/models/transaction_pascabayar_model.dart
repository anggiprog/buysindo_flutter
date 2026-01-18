class TransactionPascabayarResponse {
  final bool status;
  final List<TransactionPascabayar> data;

  TransactionPascabayarResponse({required this.status, required this.data});

  factory TransactionPascabayarResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List?;
    return TransactionPascabayarResponse(
      status: json['status'] == 'success' || json['status'] == true,
      data: dataList != null
          ? dataList
                .map((item) => TransactionPascabayar.fromJson(item))
                .toList()
          : [],
    );
  }
}

class TransactionPascabayar {
  final int id;
  final int userId;
  final String refId;
  final String brand;
  final String buyerSkuCode;
  final String customerNo;
  final String customerName;
  final String nilaiTagihan;
  final String admin;
  final String totalPembayaranUser;
  final String periode;
  final String denda;
  final String status;
  final int? daya;
  final int? lembarTagihan;
  final String? meterAwal;
  final String? meterAkhir;
  final String createdAt;
  final String sn;
  final String productName;
  final String namaToko;

  TransactionPascabayar({
    required this.id,
    required this.userId,
    required this.refId,
    required this.brand,
    required this.buyerSkuCode,
    required this.customerNo,
    required this.customerName,
    required this.nilaiTagihan,
    required this.admin,
    required this.totalPembayaranUser,
    required this.periode,
    required this.denda,
    required this.status,
    this.daya,
    this.lembarTagihan,
    this.meterAwal,
    this.meterAkhir,
    required this.createdAt,
    required this.sn,
    required this.productName,
    required this.namaToko,
  });

  factory TransactionPascabayar.fromJson(Map<String, dynamic> json) {
    return TransactionPascabayar(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      refId: json['ref_id'] ?? '',
      brand: json['brand'] ?? '',
      buyerSkuCode: json['buyer_sku_code'] ?? '',
      customerNo: json['customer_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      nilaiTagihan: json['nilai_tagihan']?.toString() ?? '0',
      admin: json['admin']?.toString() ?? '0',
      totalPembayaranUser: json['total_pembayaran_user']?.toString() ?? '0',
      periode: json['periode'] ?? '',
      denda: json['denda']?.toString() ?? '0',
      status: json['status'] ?? '',
      daya: json['daya'],
      lembarTagihan: json['lembar_tagihan'],
      meterAwal: json['meter_awal']?.toString(),
      meterAkhir: json['meter_akhir']?.toString(),
      createdAt: json['created_at'] ?? '',
      sn: json['sn'] ?? '',
      productName: json['product_name'] ?? '',
      namaToko: json['nama_toko'] ?? '',
    );
  }

  // Format price dengan separator
  String get formattedTotal {
    try {
      int price = int.parse(totalPembayaranUser);
      return 'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $totalPembayaranUser';
    }
  }

  String get formattedNilaiTagihan {
    try {
      int price = int.parse(nilaiTagihan);
      return 'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $nilaiTagihan';
    }
  }

  String get formattedAdmin {
    try {
      int price = int.parse(admin);
      return 'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $admin';
    }
  }

  String get formattedDenda {
    try {
      int price = int.parse(denda);
      if (price == 0) return '-';
      return 'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    } catch (e) {
      return 'Rp $denda';
    }
  }

  String get formattedPeriode {
    try {
      if (periode.length == 6) {
        final year = periode.substring(0, 4);
        final month = periode.substring(4, 6);
        final monthNames = [
          '',
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        return '${monthNames[int.parse(month)]} $year';
      }
      return periode;
    } catch (e) {
      return periode;
    }
  }

  // Get status color
  bool get isSuccess =>
      status.toUpperCase() == 'SUKSES' || status.toUpperCase() == 'SUCCESS';

  bool get isPending => status.toUpperCase() == 'PENDING';

  bool get isFailed =>
      status.toUpperCase() == 'GAGAL' || status.toUpperCase() == 'FAILED';
}
