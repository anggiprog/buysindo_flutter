import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../features/customer/data/models/user_model.dart' as models;
import 'edit_profile_screen.dart';
import 'transaction_history_tab.dart';
import '../notifications_page.dart';
import '../../../../features/topup/screens/topup_history_screen.dart';
import 'animated_list_tile.dart';
import 'akun/buat_toko.dart';
import '../../kontak_admin.dart';
import '../../akun/ganti_password.dart';
import '../../pin.dart';
import '../../tentang_kami.dart';
import '../../referral/referral.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _isLoading = true;
  models.ProfileResponse? _profileData;
  String _saldo = "0";
  bool _isLoadingSaldo = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchSaldo();
  }

  Future<void> _fetchSaldo() async {
    setState(() => _isLoadingSaldo = true);
    try {
      String? token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingSaldo = false;
          _saldo = "0";
        });
        return;
      }
      final dio = Dio();
      final apiService = ApiService(dio);
      final response = await apiService.getSaldo(token);
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['saldo'] != null) {
        final saldo = response.data['saldo'].toString();
        setState(() {
          _saldo = saldo;
          _isLoadingSaldo = false;
        });
      } else {
        setState(() {
          _isLoadingSaldo = false;
          _saldo = "0";
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSaldo = false;
        _saldo = "0";
      });
    }
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final apiService = ApiService(dio);
      String? token = await SessionManager.getToken();

      if (token == null) {
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

      if (response.statusCode == 200) {
        try {
          final profileResponse = models.ProfileResponse.fromJson(
            response.data,
          );

          setState(() => _profileData = profileResponse);
        } catch (e) {
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

  //// Fungsi Hapus Cache
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
            TabBar(
              labelColor: themeColor,
              unselectedLabelColor: Colors.grey,
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
    final user =
        _profileData?.user ??
        models.UserModel(
          id: 0,
          email: "email@example.com",
          username: "-",
          referralCode: null,
        );
    String saldoDisplay = _isLoadingSaldo
        ? "Memuat..."
        : (_saldo.isEmpty || _saldo == "0")
        ? "-"
        : "Rp ${_formatRupiah(_saldo)}";
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AnimatedListTile(
          icon: Icons.account_balance_wallet,
          title: "Saldo",
          color: themeColor,
          trailing: saldoDisplay,
        ),
        const Divider(height: 1),
        AnimatedListTile(
          icon: Icons.history,
          title: "Riwayat",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionHistoryTab(),
              ),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.history_edu,
          title: "Histori Topup",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TopupHistoryScreen(),
              ),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.notifications_none,
          title: "Pemberitahuan",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.storefront,
          title: "Buat Nama Toko",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuatTokoPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.headset_mic_outlined,
          title: "Hubungi CS",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KontakAdminPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.lock_open,
          title: "Ganti Password",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GantiPasswordPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.pin,
          title: "PIN",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PinPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.info_outline,
          title: "Tentang Kami",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TentangKamiPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.star_border,
          title: "Rating Aplikasi",
          color: themeColor,
          onTap: () async {
            final subdomain = appConfig.subdomain.toLowerCase();
            if (subdomain.isNotEmpty) {
              final url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.$subdomain.app',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal membuka PlayStore")),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Link PlayStore belum tersedia"),
                  ),
                );
              }
            }
          },
        ),
        AnimatedListTile(
          icon: Icons.share_outlined,
          title: "Referral",
          color: themeColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReferralPage()),
            );
          },
        ),
        AnimatedListTile(
          icon: Icons.policy_outlined,
          title: "Kebijakan - FAQ - Terms",
          color: themeColor,
          onTap: () async {
            final subdomain = appConfig.subdomain.toLowerCase();
            if (subdomain.isNotEmpty) {
              final url = Uri.parse(
                'https://$subdomain.buysindo.com/privacy-policy/$subdomain',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gagal membuka halaman kebijakan"),
                    ),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Halaman kebijakan belum tersedia"),
                  ),
                );
              }
            }
          },
        ),
        AnimatedListTile(
          icon: Icons.delete_sweep_outlined,
          title: "Hapus Data Cache",
          color: themeColor,
          onTap: _clearCache,
        ),
        AnimatedListTile(
          icon: Icons.person_remove_outlined,
          title: "Minta Hapus Akun",
          color: themeColor,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Hapus Akun"),
                content: const Text(
                  "Apakah Anda yakin ingin menghapus akun? Anda akan diarahkan ke WhatsApp Admin untuk proses verifikasi penghapusan akun.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Ya, Hubungi Admin",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                // Tampilkan snackbar proses
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Menghubungkan ke Admin..."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                String? token = await SessionManager.getToken();
                if (token == null) return;

                final kontak = await ApiService.instance.getKontakAdmin(token);
                if (kontak != null && kontak['whatsapp'] != null) {
                  final phone = kontak['whatsapp'].toString().replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );

                  final username = user.username;
                  final email = user.email;
                  final message =
                      "Halo Admin, saya ingin mengajukan penghapusan akun saya di aplikasi ${appConfig.appName}.\n\n"
                      "Detail Akun:\n"
                      "Username: $username\n"
                      "Email: $email\n\n"
                      "Mohon instruksi selanjutnya. Terima kasih.";

                  final url = Uri.parse(
                    "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal membuka WhatsApp")),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nomor WhatsApp Admin tidak ditemukan"),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Terjadi kesalahan, silakan coba lagi"),
                    ),
                  );
                }
              }
            }
          },
        ),
        AnimatedListTile(
          icon: Icons.logout,
          title: "Keluar",
          color: Colors.red,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  String _formatRupiah(String value) {
    try {
      final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      String result = number.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      return result;
    } catch (e) {
      return value;
    }
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
