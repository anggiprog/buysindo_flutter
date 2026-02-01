import 'package:flutter/material.dart';

class ClaimTab extends StatelessWidget {
  const ClaimTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              "UI masih dalam pengembangan\ndi tunggu ya",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
