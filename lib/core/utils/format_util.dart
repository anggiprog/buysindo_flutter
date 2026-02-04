import 'package:intl/intl.dart';

class FormatUtil {
  static String formatRupiah(dynamic nominal) {
    // Kita gunakan dynamic agar bisa menerima String maupun num (int/double)
    double value = double.tryParse(nominal.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  /// Format number with thousand separator (e.g., 1.000.000)
  static String formatNumber(dynamic number) {
    double value = double.tryParse(number.toString()) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(value.toInt());
  }
}
