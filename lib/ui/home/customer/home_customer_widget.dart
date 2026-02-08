import 'package:flutter/material.dart';
import '../../../core/app_config.dart';
import 'tabs/customer_dashboard.dart';
import 'tabs/transaction_history_tab.dart';
import 'tabs/account_tab.dart';
import 'notifications_page.dart';

class HomeCustomerScreen extends StatefulWidget {
  final int? initialTab;
  final int? subTabIndex;

  const HomeCustomerScreen({super.key, this.initialTab, this.subTabIndex});

  @override
  State<HomeCustomerScreen> createState() => _HomeCustomerScreenState();
}

class _HomeCustomerScreenState extends State<HomeCustomerScreen> {
  late int _currentIndex;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pages.isEmpty) {
      _pages.addAll([
        const CustomerDashboard(),
        TransactionHistoryTab(initialSubTab: widget.subTabIndex),
        const NotificationsPage(),
        const AccountTab(),
      ]);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConfig,
      builder: (context, _) {
        // PERBAIKAN: Navbar hanya sembunyi jika showNavbar == 0
        // Syarat "|| tampilan == 'app_custom'" dihapus
        final bool hideNavbar = appConfig.showNavbar == 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: null,
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: hideNavbar ? null : _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        child: Container(
          color: appConfig.primaryColor,
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: BottomNavigationBar(
              elevation: 0,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              selectedItemColor: appConfig.textColor,
              unselectedItemColor: appConfig.textColor.withOpacity(0.5),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: "Beranda",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: "Riwayat",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: "Notifikasi",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Akun",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
