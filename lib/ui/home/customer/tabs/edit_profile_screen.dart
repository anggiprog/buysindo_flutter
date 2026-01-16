import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_config.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../features/customer/data/models/user_model.dart' as models;

class EditProfileScreen extends StatefulWidget {
  final models.ProfileModel? profile;
  final models.UserModel? user;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _genderController;
  late TextEditingController _birthdateController;
  late TextEditingController _addressController;

  bool _isLoading = false;
  String? _selectedGender;
  final List<String> _genderOptions = ['Laki-Laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    _fullNameController = TextEditingController(
      text: widget.profile?.fullName ?? '',
    );
    _phoneController = TextEditingController(text: widget.profile?.phone ?? '');
    _birthdateController = TextEditingController(
      text: widget.profile?.birthdate ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile?.address ?? '',
    );

    // Normalize gender value to match _genderOptions
    String? genderFromApi = widget.profile?.gender;
    _selectedGender = null;

    if (genderFromApi != null) {
      // Check if it matches exactly with options
      if (_genderOptions.contains(genderFromApi)) {
        _selectedGender = genderFromApi;
      } else {
        // Try to normalize common variations
        String normalized = genderFromApi.trim().toLowerCase();
        if (normalized.contains('laki') ||
            normalized.contains('male') ||
            normalized.contains('m')) {
          _selectedGender = 'Laki-Laki';
        } else if (normalized.contains('perempuan') ||
            normalized.contains('female') ||
            normalized.contains('f')) {
          _selectedGender = 'Perempuan';
        }
      }
    }

    _genderController = TextEditingController(text: _selectedGender ?? '');
  }

  Future<void> _updateProfile() async {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final dio = Dio();
      final apiService = ApiService(dio);

      // Convert birthdate from DD-MM-YYYY to YYYY-MM-DD for API
      String birthdateForApi = _birthdateController.text;
      try {
        final parsedDate = DateFormat(
          'dd-MM-yyyy',
        ).parse(_birthdateController.text);
        birthdateForApi = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        // Use as-is if parsing fails
      }

      final response = await apiService.updateProfile(
        token: token,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        gender: _selectedGender ?? '',
        birthdate: birthdateForApi,
        address: _addressController.text,
      );

      debugPrint('Update Response: $response');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == true) {
          // Simpan data terbaru ke SharedPreferences untuk cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_full_name', _fullNameController.text);
          await prefs.setString('user_phone', _phoneController.text);
          await prefs.setString('user_gender', _selectedGender ?? '');
          await prefs.setString('user_birthdate', _birthdateController.text);
          await prefs.setString('user_address', _addressController.text);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Panggil callback untuk refresh data di AccountTab
          widget.onProfileUpdated?.call();

          // Kembali ke halaman sebelumnya setelah 1 detik
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal memperbarui profil',
          );
        }
      } else {
        throw Exception('Gagal memperbarui profil: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg =
          e.response?.data?['message'] ?? 'Terjadi kesalahan jaringan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      debugPrint('❌ Dio Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('❌ Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _birthdateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appConfig.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Lengkap
                  _buildTextField(
                    label: 'Nama Lengkap',
                    controller: _fullNameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // No Telepon
                  _buildTextField(
                    label: 'No Telepon',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Jenis Kelamin (Dropdown)
                  _buildDropdownField(
                    label: 'Jenis Kelamin',
                    value: _selectedGender,
                    items: _genderOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                        _genderController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Lahir (Date Picker)
                  _buildDateField(
                    label: 'Tanggal Lahir',
                    controller: _birthdateController,
                  ),
                  const SizedBox(height: 16),

                  // Alamat
                  _buildTextField(
                    label: 'Alamat',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan dan Batal
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _updateProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.black38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          initialValue: (value != null && items.contains(value)) ? value : null,
          items: items.toSet().toList().map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          // PINDAHKAN contentPadding KE DALAM decoration SEPERTI DI BAWAH INI:
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 15,
            ), // Padding diletakkan di sini
            prefixIcon: const Icon(Icons.wc_outlined, color: Colors.black),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.black38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final parsedDate = _parseDate(controller.text);
            // Ensure initialDate is within valid range
            DateTime initialDate = DateTime.now();
            if (parsedDate != null &&
                !parsedDate.isBefore(DateTime(1950)) &&
                !parsedDate.isAfter(DateTime.now())) {
              initialDate = parsedDate;
            }

            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: appConfig.primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              final formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
              controller.text = formattedDate;
            }
          },
          child: TextField(
            controller: controller,
            enabled: false,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.black,
              ),
              hintText: 'DD-MM-YYYY',
              hintStyle: const TextStyle(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      // Check format based on separators
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        // YYYY-MM-DD format (from API or user input)
        if (parts[0].length == 4) {
          return DateFormat('yyyy-MM-dd').parse(dateString);
        }
        // DD-MM-YYYY format (from user date picker)
        else if (parts[2].length == 4) {
          return DateFormat('dd-MM-yyyy').parse(dateString);
        }
      }

      // Fallback: try YYYY-MM-DD first (API format)
      try {
        return DateFormat('yyyy-MM-dd').parse(dateString);
      } catch (e) {
        // Then try DD-MM-YYYY (user format)
        return DateFormat('dd-MM-yyyy').parse(dateString);
      }
    } catch (e) {
      debugPrint('❌ Failed to parse date: $dateString - Error: $e');
      return null;
    }
  }
}
