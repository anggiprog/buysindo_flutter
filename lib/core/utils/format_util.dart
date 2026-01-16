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
}
