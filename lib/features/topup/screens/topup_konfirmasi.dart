import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';
import '../../../core/app_config.dart';
import '../../../ui/home/topup/topup_konfirmasi.dart';

class TopupKonfirmasiScreen extends StatelessWidget {
  final String trxId;
  final double amount;

  const TopupKonfirmasiScreen({
    Key? key,
    required this.trxId,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TopupKonfirmasi(
      nomorTransaksi: trxId,
      totalAmount: amount.toInt(),
      primaryColor: appConfig.primaryColor,
      apiService: ApiService(Dio()),
    );
  }
}
