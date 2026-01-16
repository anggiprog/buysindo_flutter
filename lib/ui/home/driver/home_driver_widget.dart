import 'package:flutter/material.dart';
import '../../../core/app_config.dart';

class HomeDriverWidget extends StatelessWidget {
  const HomeDriverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mode Driver"),
        actions: [
          Switch(value: true, onChanged: (v) {}), // Switch Online/Offline
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bike,
              size: 100,
              color: appConfig.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              "Status: Siap Menerima Order",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
