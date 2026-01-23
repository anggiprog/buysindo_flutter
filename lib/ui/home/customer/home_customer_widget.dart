import 'package:flutter/material.dart';
import '../../../core/app_config.dart';
import 'tabs/customer_dashboard.dart';
import 'tabs/transaction_history_tab.dart';
import 'tabs/account_tab.dart';
import 'notifications_page.dart';

class HomeCustomerScreen extends StatefulWidget {
  final int? initialTab;

  const HomeCustomerScreen({super.key, this.initialTab});

  @override
  State<HomeCustomerScreen> createState() => _HomeCustomerScreenState();
}

class _HomeCustomerScreenState extends State<HomeCustomerScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Use initialTab if provided, otherwise default to 0 (Beranda)
    _currentIndex = widget.initialTab ?? 0;
    debugPrint(
      '🎯 HomeCustomerScreen initialized with tab index: $_currentIndex',
    );
  }

  // Semua tab dalam satu list: Beranda, Riwayat, Notifikasi, Akun
  final List<Widget> _pages = [
    const CustomerDashboard(),
    const TransactionHistoryTab(),
    const NotificationsPage(),
    const AccountTab(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar akan dihandle oleh setiap child tab
      appBar: null,
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Container(
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
                onTap: _onTabTapped, // Menggunakan fungsi navigasi baru
                backgroundColor: Colors.transparent,
                selectedItemColor: appConfig.textColor,
                unselectedItemColor: appConfig.textColor.withOpacity(0.5),
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.home_filled),
                    ),
                    label: "Beranda",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.receipt_long),
                    ),
                    label: "Riwayat",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.notifications),
                    ),
                    label: "Notifikasi",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.person),
                    ),
                    label: "Akun",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
