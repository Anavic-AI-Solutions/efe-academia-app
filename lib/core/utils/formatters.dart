import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static String formatCurrency(double amount) => NumberFormat.currency(
        locale: 'es_AR',
        symbol: r'$',
        decimalDigits: 2,
      ).format(amount);

  static String formatNumber(int number) =>
      NumberFormat('#,##0', 'es_AR').format(number);

  static String formatPercentage(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';
}
