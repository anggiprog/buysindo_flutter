import 'package:flutter/material.dart';
import '../../../../../core/app_config.dart';

class OjekOnlineTemplate extends StatelessWidget {
  const OjekOnlineTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header dengan Saldo & Poin
            _buildTopBranding(),

            // 2. Search Bar "Mau kemana?"
            _buildDestinationSearch(),

            // 3. Main Services Grid (Motor, Mobil, Makan, Paket)
            _buildMainServices(),

            // 4. Promo/News Banner
            _buildPromoSlider(),

            // 5. Recent Destinations (Tempat yang sering dikunjungi)
            _buildRecentDestinations(),

            const SizedBox(height: 100), // Ruang ekstra untuk BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildTopBranding() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: appConfig.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, Mang Agi!",
                  style: TextStyle(
                    color: appConfig.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Mau pergi ke mana hari ini?",
                  style: TextStyle(
                    color: appConfig.textColor.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    "2.450 Poin",
                    style: TextStyle(
                      color: appConfig.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSearch() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: appConfig.primaryColor),
          const SizedBox(width: 15),
          const Text(
            "Mau kemana hari ini?",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        children: [
          _serviceItem(Icons.directions_bike, "Ride", Colors.green),
          _serviceItem(Icons.directions_car, "Car", Colors.blue),
          _serviceItem(Icons.restaurant, "Food", Colors.red),
          _serviceItem(Icons.inventory_2, "Send", Colors.orange),
          _serviceItem(Icons.shopping_bag, "Mart", Colors.purple),
          _serviceItem(Icons.medical_services, "Health", Colors.teal),
          _serviceItem(Icons.receipt_long, "Bills", Colors.indigo),
          _serviceItem(Icons.grid_view, "More", Colors.grey),
        ],
      ),
    );
  }

  Widget _serviceItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPromoSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 25),
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  "https://img.freepik.com/free-vector/food-delivery-banner-with-photo_23-2149024503.jpg",
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentDestinations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tempat Terakhir",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.work, color: Colors.grey),
            ),
            title: const Text("Kantor AgiCell"),
            subtitle: const Text("Jl. Merdeka No. 123, Bandung"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.home, color: Colors.grey),
            ),
            title: const Text("Rumah"),
            subtitle: const Text("Komp. Permata Indah Blok C"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
