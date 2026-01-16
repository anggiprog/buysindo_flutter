import 'package:flutter/material.dart';
import '../../../core/app_config.dart';

class HomeMitraWidget extends StatelessWidget {
  const HomeMitraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Mitra Toko")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Ringkasan Toko",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text("Pesanan Masuk"),
              trailing: Badge(label: Text("3")),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.inventory, color: appConfig.primaryColor),
              title: const Text("Kelola Stok Barang"),
            ),
          ),
        ],
      ),
    );
  }
}
