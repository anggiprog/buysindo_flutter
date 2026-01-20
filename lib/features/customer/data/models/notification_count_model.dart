class NotificationCountResponse {
  final dynamic status; // backend kadang mengirim string atau boolean
  final int jumlahBelumDibaca;

  NotificationCountResponse({required this.status, required this.jumlahBelumDibaca});

  factory NotificationCountResponse.fromJson(Map<String, dynamic> json) {
    final jumlah = json['jumlah_belum_dibaca'] ?? json['data'] ?? json['count'] ?? json['jumlah'];
    return NotificationCountResponse(
      status: json['status'],
      jumlahBelumDibaca: int.tryParse(jumlah?.toString() ?? '0') ?? 0,
    );
  }
}
