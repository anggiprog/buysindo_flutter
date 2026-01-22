import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../features/customer/data/models/user_model.dart' as models;
import 'edit_profile_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _isLoading = true;
  models.ProfileResponse? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final apiService = ApiService(dio);
      String? token = await SessionManager.getToken();

      if (token == null) {
        debugPrint('  - Status: ❌ Token null, tidak bisa fetch profile');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Gagal memuat data profile, periksa jaringan internet anda",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final response = await apiService.getProfile(token);

      debugPrint('  - Response received');
      debugPrint('  - Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final profileResponse = models.ProfileResponse.fromJson(
            response.data,
          );

          setState(() => _profileData = profileResponse);
          debugPrint('✅ Profile data loaded');
        } catch (e) {
          debugPrint('  - ❌ Parsing error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Gagal memuat data profile, periksa jaringan internet anda",
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        debugPrint('  - ❌ Response status: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Gagal memuat data profile, periksa jaringan internet anda",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error load profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal memuat data profile, periksa jaringan internet anda",
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi Hapus Cache
  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Membersihkan cache..."),
        duration: Duration(seconds: 1),
      ),
    );

    SessionManager.clearCacheExceptToken()
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cache berhasil dihapus! (Token tetap disimpan)"),
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal menghapus cache. Coba lagi.")),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    // Robust color validation
    Color themeColor = const Color(0xFF0D6EFD); // Default blue
    if (primaryColor.value != 0 &&
        primaryColor.value != 0xFFFFFFFF &&
        primaryColor.alpha > 200 &&
        primaryColor.computeLuminance() < 0.9) {
      themeColor = primaryColor;
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Memuat data profil..."),
            ],
          ),
        ),
      );
    }

    // Gunakan data yang ada atau buat model default
    final user =
        _profileData?.user ??
        models.UserModel(
          id: 0,
          email: "email@example.com",
          username: "-",
          referralCode: null,
        );

    final profile =
        _profileData?.profile ??
        models.ProfileModel(
          id: 0,
          userId: 0,
          fullName: "Nama tidak tersedia",
          phone: "-",
          gender: "-",
          birthdate: "-",
          address: "-",
          profilePicture: null,
          referralDate: null,
          verified: 0,
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          // Tombol Back muncul otomatis jika dipush dari Navigator
          title: const Text(
            "Profil Akun",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: false, // Set true jika ingin judul di tengah
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: themeColor,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          actions: [],
        ),
        body: Column(
          children: [
            // Header profil Anda yang warna hijau/backend
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              color: themeColor,
              child: Column(
                children: [
                  _buildAvatar(profile),
                  const SizedBox(height: 15),
                  Text(
                    profile.fullName ?? "Nama tidak tersedia",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // ... TabBar dan TabBarView Anda ...
            const TabBar(
              labelColor: Color(0xFF00897B), // Atau gunakan themeColor
              tabs: [
                Tab(text: "MENU"),
                Tab(text: "PROFIL"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMenuTab(themeColor),
                  _buildProfilTab(profile, user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(models.ProfileModel? profile) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white24,
          child: ClipOval(
            child: profile?.profilePicture != null
                ? Image.network(
                    profile!.profilePicture!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.person, size: 60, color: Colors.white),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.white),
          ),
        ),
        // Floating Edit Button
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              debugPrint("Tombol Edit ditekan");
              if (_profileData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      profile: _profileData!.profile,
                      user: _profileData!.user,
                      onProfileUpdated: _fetchProfile,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Silakan tunggu sampai data profil dimuat"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appConfig.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTab(Color themeColor) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildListTile(
          Icons.account_balance_wallet,
          "Saldo",
          themeColor,
          trailing: "Rp 663.656",
        ),
        const Divider(height: 1),
        _buildListTile(Icons.history, "Transaksi", themeColor),
        _buildListTile(Icons.history_edu, "Histori Topup", themeColor),
        _buildListTile(Icons.notifications_none, "Pemberitahuan", themeColor),
        _buildListTile(Icons.storefront, "Buat Nama Toko", themeColor),
        _buildListTile(Icons.headset_mic_outlined, "Hubungi CS", themeColor),
        _buildListTile(Icons.lock_open, "Ganti Password", themeColor),
        _buildListTile(Icons.pin, "PIN", themeColor),
        _buildListTile(Icons.info_outline, "Tentang Kami", themeColor),
        _buildListTile(Icons.star_border, "Rating Aplikasi", themeColor),
        _buildListTile(Icons.share_outlined, "Referral", themeColor),
        _buildListTile(
          Icons.policy_outlined,
          "Kebijakan - FAQ - Terms",
          themeColor,
        ),
        _buildListTile(
          Icons.delete_sweep_outlined,
          "Hapus Data Cache",
          themeColor,
          onTap: _clearCache,
        ),
        _buildListTile(
          Icons.person_remove_outlined,
          "Minta Hapus Akun",
          themeColor,
        ),
        _buildListTile(
          Icons.logout,
          "Keluar",
          Colors.red,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildProfilTab(models.ProfileModel? profile, models.UserModel? user) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildInfoTile("Nama Lengkap", profile?.fullName ?? "-"),
        _buildInfoTile("Username", user?.username ?? "-"),
        _buildInfoTile("Email", user?.email ?? "-"),
        _buildInfoTile("Telepon", profile?.phone ?? "-"),
        _buildInfoTile("Jenis Kelamin", profile?.gender ?? "-"),
        _buildInfoTile("Tanggal Lahir", profile?.birthdate ?? "-"),
        _buildInfoTile("Alamat", profile?.address ?? "-"),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    Color color, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          // Jika warna bukan merah (logout), gunakan warna teks dari backend
          color: color == Colors.red ? Colors.red : Colors.black87,
          fontSize: 15,
        ),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            )
          : Icon(
              Icons.chevron_right,
              size: 20,
              // --- GANTI DI SINI ---
              color: appConfig.primaryColor.withValues(alpha: 0.5),
            ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    // Convert birthdate format from YYYY-MM-DD to DD-MM-YYYY if it's birthdate field
    String displayValue = value;
    if (label == "Tanggal Lahir" && value != "-") {
      try {
        // Try to parse YYYY-MM-DD format
        final date = DateTime.parse(value);
        displayValue =
            '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      } catch (e) {
        // If it's already in correct format or parsing fails, use as-is
        displayValue = value;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Apakah anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
