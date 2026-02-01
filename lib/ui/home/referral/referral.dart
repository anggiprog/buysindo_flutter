import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/app_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/session_manager.dart';
import 'tabs/buat_tab.dart';
import 'tabs/daftar_tab.dart';
import 'tabs/claim_tab.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService(Dio());

  String _currentReferralCode = "-";
  List<dynamic> _referralList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchReferralCode(), _fetchReferralList()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchReferralCode() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      final response = await _apiService.getReferralCode(token);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _currentReferralCode = response.data['referral_code'] ?? "-";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch referral code: $e");
    }
  }

  Future<void> _fetchReferralList() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      final response = await _apiService.getReferralList(token);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _referralList = response.data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch referral list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Referral Program",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "BUAT"),
            Tab(text: "DAFTAR"),
            Tab(text: "CLAIM"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BuatTab(
            currentCode: _currentReferralCode,
            onSaved: _fetchReferralCode,
          ),
          DaftarTab(referralList: _referralList, isLoading: _isLoading),
          const ClaimTab(),
        ],
      ),
    );
  }
}
