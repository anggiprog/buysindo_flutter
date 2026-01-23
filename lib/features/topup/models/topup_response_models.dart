// Models untuk TopUp API Responses

class MinimalTopupResponse {
  final String? status;
  final int? minimalTopup;
  final bool? amountMeetsMinimal;
  final String? message;

  MinimalTopupResponse({
    this.status,
    this.minimalTopup,
    this.amountMeetsMinimal,
    this.message,
  });

  factory MinimalTopupResponse.fromJson(Map<String, dynamic> json) {
    return MinimalTopupResponse(
      status: json['status'] as String?,
      minimalTopup: json['minimal_topup'] as int?,
      amountMeetsMinimal: json['amount_meets_minimal'] as bool?,
      message: json['message'] as String?,
    );
  }
}

class AdminFeeResponse {
  final String? status;
  final int? biayaAdminManual;

  AdminFeeResponse({this.status, this.biayaAdminManual});

  factory AdminFeeResponse.fromJson(Map<String, dynamic> json) {
    return AdminFeeResponse(
      status: json['status'] as String?,
      biayaAdminManual: json['biaya_admin_manual'] as int?,
    );
  }
}

class RekeningStatusResponse {
  final bool? success;
  final String? message;
  final RekeningData? data;

  RekeningStatusResponse({this.success, this.message, this.data});

  factory RekeningStatusResponse.fromJson(Map<String, dynamic> json) {
    return RekeningStatusResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? RekeningData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RekeningData {
  final int? id;
  final int? adminUserId;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  RekeningData({
    this.id,
    this.adminUserId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory RekeningData.fromJson(Map<String, dynamic> json) {
    return RekeningData(
      id: json['id'] as int?,
      adminUserId: json['admin_user_id'] as int?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class StatusPaymentResponse {
  final String? merchant;
  final int? status;

  StatusPaymentResponse({this.merchant, this.status});

  factory StatusPaymentResponse.fromJson(Map<String, dynamic> json) {
    return StatusPaymentResponse(
      merchant: json['merchant'] as String?,
      status: json['status'] as int?,
    );
  }
}

class BankAccountResponse {
  final String? status;
  final List<BankAccount>? data;

  BankAccountResponse({this.status, this.data});

  factory BankAccountResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>?;
    return BankAccountResponse(
      status: json['status'] as String?,
      data: dataList != null
          ? dataList
                .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class BankAccount {
  final int? id;
  final int? adminUserId;
  final String? namaBank;
  final String? nomorRekening;
  final String? atasNamaRekening;
  final String? logoBank;
  final int? jenisPembayaranId;
  final dynamic superadminUsers;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  BankAccount({
    this.id,
    this.adminUserId,
    this.namaBank,
    this.nomorRekening,
    this.atasNamaRekening,
    this.logoBank,
    this.jenisPembayaranId,
    this.superadminUsers,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int?,
      adminUserId: json['admin_user_id'] as int?,
      namaBank: json['nama_bank'] as String?,
      nomorRekening: json['nomor_rekening'] as String?,
      atasNamaRekening: json['atas_nama_rekening'] as String?,
      logoBank: json['logo_bank'] as String?,
      jenisPembayaranId: json['jenis_pembayaran_id'] as int?,
      superadminUsers: json['superadmin_users'],
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class TopupResponse {
  final bool? status;
  final String? message;
  final TopupData? data;

  TopupResponse({this.status, this.message, this.data});

  factory TopupResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 [TOPUP_RESPONSE] Full response JSON: $json');

    // Parse status - can be bool or string
    bool? parsedStatus;
    final statusValue = json['status'];
    print(
      '🔍 [TOPUP_RESPONSE] Status value: $statusValue (type: ${statusValue.runtimeType})',
    );

    if (statusValue is bool) {
      parsedStatus = statusValue;
    } else if (statusValue is String) {
      parsedStatus =
          statusValue.toLowerCase() == 'true' ||
          statusValue.toLowerCase() == 'success';
    } else if (statusValue == 1) {
      parsedStatus = true;
    } else if (statusValue == 0) {
      parsedStatus = false;
    }

    print('🔍 [TOPUP_RESPONSE] Parsed status: $parsedStatus');
    print('🔍 [TOPUP_RESPONSE] Data from response: ${json['data']}');

    return TopupResponse(
      status: parsedStatus,
      message: json['message'] as String?,
      data: json['data'] != null
          ? TopupData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TopupData {
  final int? id;
  final int? userId;
  final String? amount;
  final String? bankName;
  final String? nomorRekening;
  final String? namaRekening;
  final String? nomorTransaksi;
  final String? batasWaktu;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  TopupData({
    this.id,
    this.userId,
    this.amount,
    this.bankName,
    this.nomorRekening,
    this.namaRekening,
    this.nomorTransaksi,
    this.batasWaktu,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory TopupData.fromJson(Map<String, dynamic> json) {
    print('🔍 [TOPUP_DATA] Parsing TopupData from: $json');

    // Backend returns 'trx_id' but we also check 'nomor_transaksi' for compatibility
    final nomorTransaksi =
        (json['nomor_transaksi'] ?? json['trx_id']) as String?;
    print('🔍 [TOPUP_DATA] nomorTransaksi extracted: $nomorTransaksi');
    print('🔍 [TOPUP_DATA] Available keys: ${json.keys.toList()}');

    return TopupData(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      amount: (json['amount'] ?? json['topup'])?.toString(),
      bankName: (json['bank_name'] ?? json['nama_bank']) as String?,
      nomorRekening: json['nomor_rekening'] as String?,
      namaRekening: json['nama_rekening'] as String?,
      nomorTransaksi: nomorTransaksi,
      batasWaktu: json['batas_waktu'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
