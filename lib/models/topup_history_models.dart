class TopupManualHistory {
  final int id;
  final String trxId;
  final String topup;
  final String status;
  final String namaBank;
  final String namaRekening;
  final String nomorRekening;
  final String batasWaktu;
  final String? buktiTransfer;
  final String tanggal;

  TopupManualHistory({
    required this.id,
    required this.trxId,
    required this.topup,
    required this.status,
    required this.namaBank,
    required this.namaRekening,
    required this.nomorRekening,
    required this.batasWaktu,
    this.buktiTransfer,
    required this.tanggal,
  });

  factory TopupManualHistory.fromJson(Map<String, dynamic> json) {
    return TopupManualHistory(
      id: json['id'] ?? 0,
      trxId: json['trx_id']?.toString() ?? '',
      topup: json['topup']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      namaBank: json['nama_bank']?.toString() ?? '',
      namaRekening: json['nama_rekening']?.toString() ?? '',
      nomorRekening: json['nomor_rekening']?.toString() ?? '',
      batasWaktu: json['batas_waktu']?.toString() ?? '',
      buktiTransfer: json['bukti_transfer']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
    );
  }
}

class TopupManualHistoryResponse {
  final String status;
  final List<TopupManualHistory> data;

  TopupManualHistoryResponse({required this.status, required this.data});

  factory TopupManualHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TopupManualHistoryResponse(
      status: json['status']?.toString() ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => TopupManualHistory.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class TopupOtomatisHistory {
  final String? trxId;
  final String status;
  final int jumlahTopup;
  final String channel;
  final String createdAt;
  final String source;
  final String? paymentUrl;

  TopupOtomatisHistory({
    this.trxId,
    required this.status,
    required this.jumlahTopup,
    required this.channel,
    required this.createdAt,
    required this.source,
    this.paymentUrl,
  });

  factory TopupOtomatisHistory.fromJson(Map<String, dynamic> json) {
    return TopupOtomatisHistory(
      trxId: json['trx_id']?.toString(),
      status: json['status']?.toString() ?? '',
      jumlahTopup: int.tryParse(json['jumlah_topup']?.toString() ?? '0') ?? 0,
      channel: json['channel']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      paymentUrl: json['payment_url']?.toString(),
    );
  }
}

class TopupOtomatisHistoryResponse {
  final String status;
  final List<TopupOtomatisHistory> data;

  TopupOtomatisHistoryResponse({required this.status, required this.data});

  factory TopupOtomatisHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TopupOtomatisHistoryResponse(
      status: json['status']?.toString() ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => TopupOtomatisHistory.fromJson(item))
              .toList() ??
          [],
    );
  }
}
