import 'package:intl/intl.dart';

class CurrencyUtils {
  static String format(double amount) {
    // Standard thousands separator formatter
    final formatter = NumberFormat('#,###', 'es_CO');
    return '\$${formatter.format(amount)}';
  }

  static String formatWithDecimal(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es_CO');
    return '\$${formatter.format(amount)}';
  }
}
