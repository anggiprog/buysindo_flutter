import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';

class DaftarTab extends StatelessWidget {
  final List<dynamic> referralList;
  final bool isLoading;

  const DaftarTab({
    super.key,
    required this.referralList,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                const Text(
                  "Daftar Referral yang Diajak",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Total Referral: ${referralList.length} User",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: referralList.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada user yang diajak",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: referralList.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = referralList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: primaryColor),
                        ),
                        title: Text(
                          user['full_name'] ?? user['username'] ?? "User",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          user['phone'] ?? user['email'] ?? "-",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Text(
                          "Aktif",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
