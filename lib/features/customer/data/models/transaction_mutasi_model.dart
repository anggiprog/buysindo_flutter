class TransactionMutasi {
  final int id;
  final String trxId;
  final int userId;
  final String username;
  final int saldoAwal;
  final int saldoAkhir;
  final int jumlah;
  final int markupAdmin;
  final int adminFee;
  final String keterangan;
  final String createdAt;
  final String? namaToko;

  TransactionMutasi({
    required this.id,
    required this.trxId,
    required this.userId,
    required this.username,
    required this.saldoAwal,
    required this.saldoAkhir,
    required this.jumlah,
    required this.markupAdmin,
    required this.adminFee,
    required this.keterangan,
    required this.createdAt,
    this.namaToko,
  });

  factory TransactionMutasi.fromJson(Map<String, dynamic> json) {
    return TransactionMutasi(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      trxId: json['trx_id']?.toString() ?? '',
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      saldoAwal: json['saldo_awal'] is int
          ? json['saldo_awal']
          : int.tryParse(json['saldo_awal'].toString()) ?? 0,
      saldoAkhir: json['saldo_akhir'] is int
          ? json['saldo_akhir']
          : int.tryParse(json['saldo_akhir'].toString()) ?? 0,
      jumlah: json['jumlah'] is int
          ? json['jumlah']
          : int.tryParse(json['jumlah'].toString()) ?? 0,
      markupAdmin: json['markup_admin'] is int
          ? json['markup_admin']
          : int.tryParse(json['markup_admin'].toString()) ?? 0,
      adminFee: json['admin_fee'] is int
          ? json['admin_fee']
          : int.tryParse(json['admin_fee'].toString()) ?? 0,
      keterangan: json['keterangan']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      namaToko: json['nama_toko']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trx_id': trxId,
      'user_id': userId,
      'username': username,
      'saldo_awal': saldoAwal,
      'saldo_akhir': saldoAkhir,
      'jumlah': jumlah,
      'markup_admin': markupAdmin,
      'admin_fee': adminFee,
      'keterangan': keterangan,
      'created_at': createdAt,
      'nama_toko': namaToko,
    };
  }

  // Formatter untuk display
  String get formattedSaldoAwal =>
      'Rp ${saldoAwal.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  String get formattedSaldoAkhir =>
      'Rp ${saldoAkhir.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  String get formattedJumlah {
    final isDebit = jumlah < 0;
    final absValue = jumlah.abs();
    return '${isDebit ? '-' : '+'}Rp ${absValue.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  String get formattedMarkupAdmin =>
      'Rp ${markupAdmin.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  String get formattedAdminFee =>
      'Rp ${adminFee.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  bool get isDebit => jumlah < 0;
  bool get isCredit => jumlah > 0;
}
