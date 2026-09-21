import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

class AppFormatters {
  AppFormatters._();

  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  static String formatRelative(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
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
