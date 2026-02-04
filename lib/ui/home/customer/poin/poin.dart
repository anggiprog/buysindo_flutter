import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';
import 'tabs/jumlah_poin_tab.dart';
import 'tabs/riwayat_poin_tab.dart';

class PoinPage extends StatefulWidget {
  const PoinPage({super.key});

  @override
  State<PoinPage> createState() => _PoinPageState();
}

class _PoinPageState extends State<PoinPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Poin Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.stars_rounded, size: 20), text: 'JUMLAH POIN'),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'RIWAYAT POIN',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [JumlahPoinTab(), RiwayatPoinTab()],
      ),
    );
  }
}
