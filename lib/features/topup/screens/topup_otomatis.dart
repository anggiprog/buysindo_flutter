import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';
import '../../../core/app_config.dart';
import '../../../ui/home/topup/topup_otomatis.dart';

class TopupOtomatisScreen extends StatelessWidget {
  final double initialAmount;

  const TopupOtomatisScreen({Key? key, required this.initialAmount})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TopupOtomatis(
      amount: initialAmount.toInt(),
      primaryColor: appConfig.primaryColor,
      apiService: ApiService(Dio()),
    );
  }
}
