import 'package:flutter/foundation.dart';

class AppConfigModel {
  final int id;
  final String appName;
  final String packageName;
  final String appType;
  final String primaryColor;
  final String textColor;
  final String? logoUrl;
  final String subdomain;
  final String template;
  final String template2;
  final String tampilan;
  final String status;

  AppConfigModel({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.appType,
    required this.primaryColor,
    required this.textColor,
    this.logoUrl,
    required this.subdomain,
    required this.template,
    required this.template2,
    required this.tampilan,
    required this.status,
  });

  factory AppConfigModel.fromApi(Map<String, dynamic> json) {
    // Debug log untuk memastikan data mentah dari API terlihat
    debugPrint('');
    debugPrint('🔍 PARSING DATA API (RAW JSON):');
    debugPrint('Full JSON: $json');
    debugPrint('');

    // Ekstrak semua field dengan logging detail
    final id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0;
    final appName = json['app_name']?.toString() ?? 'Apk Customer';
    final packageName = json['package_name']?.toString() ?? '';
    final appType = json['app_type']?.toString() ?? 'customer';
    final primaryColor =
        json['primary_color']?.toString() ??
        json['branding']?['primary_color']?.toString() ??
        '#0d6efd';
    final textColor =
        json['text_color']?.toString() ??
        json['branding']?['text_color']?.toString() ??
        '#ffffff';
    final logoUrl =
        json['logo_url']?.toString() ??
        json['branding']?['logo_url']?.toString();
    final subdomain =
        json['subdomain']?.toString() ??
        json['server_info']?['subdomain']?.toString() ??
        '';

    // 🔴 FIELD KRITIS: Debugging template
    final templateRaw = json['template'];
    final template = templateRaw?.toString() ?? '';
    final template2Raw = json['template2'];
    final template2 = template2Raw?.toString() ?? '';
    final tampilanRaw = json['tampilan'];
    final tampilan = tampilanRaw?.toString() ?? '';

    debugPrint('🔴 FIELD TEMPLATE (CRITICAL):');
    debugPrint('  - Nilai raw: $tampilanRaw');
    debugPrint('  - Tipe: ${tampilanRaw.runtimeType}');
    debugPrint('  - Setelah toString(): "$tampilan"');
    debugPrint('  - Panjang: ${tampilan.length}');
    debugPrint('  - isEmpty: ${tampilan.isEmpty}');
    debugPrint('  - Bytes: ${tampilan.codeUnits}');
    debugPrint('');

    final status = json['status']?.toString() ?? 'nonactive';

    debugPrint('✅ SEMUA FIELD BERHASIL DI-EXTRACT');
    debugPrint('');

    return AppConfigModel(
      id: id,
      appName: appName,
      packageName: packageName,
      appType: appType,
      primaryColor: primaryColor,
      textColor: textColor,
      logoUrl: logoUrl,
      subdomain: subdomain,
      template: template,
      template2: template2,
      tampilan: tampilan,
      status: status,
    );
  }
}
