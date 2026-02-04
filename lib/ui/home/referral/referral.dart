import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // SharedPreferences keys
  static const String _referralCodeKey = 'cached_referral_code';
  static const String _referralListKey = 'cached_referral_list';

  String _currentReferralCode = "-";
  List<dynamic> _referralList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFromCache();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load data from SharedPreferences cache first
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached referral code
      final cachedCode = prefs.getString(_referralCodeKey);
      if (cachedCode != null && cachedCode.isNotEmpty && mounted) {
        setState(() {
          _currentReferralCode = cachedCode;
        });
      }

      // Load cached referral list
      final cachedList = prefs.getStringList(_referralListKey);
      if (cachedList != null && cachedList.isNotEmpty && mounted) {
        // Simple parsing - stored as list of strings
        // For complex data, consider using jsonEncode/jsonDecode
      }
    } catch (e) {
      debugPrint("Error loading from cache: $e");
    }
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
      debugPrint('[Referral] Get referral code response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Response format: {"referral_code": "anggi123"}
        final referralCode = response.data['referral_code'];

        if (referralCode != null && referralCode.toString().isNotEmpty) {
          // Save to cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_referralCodeKey, referralCode.toString());

          if (mounted) {
            setState(() {
              _currentReferralCode = referralCode.toString();
            });
          }
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
      debugPrint('[Referral] Get referral list response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Response format: {"status": true, "jumlah_referral": 1, "referrals": [...]}
        final data = response.data;
        if (data['status'] == true && mounted) {
          setState(() {
            _referralList = data['referrals'] ?? [];
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
