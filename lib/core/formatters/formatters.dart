import 'package:intl/intl.dart';
import '../localization/app_localizations.dart';

/// Formatting utilities for currency, dates, numbers and phone numbers
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat.compact(locale: 'en_US');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Format EGP Currency e.g. "1,450.00 EGP" or "1,450.00 ج.م"
  static String formatEGP(double amount) {
    final isAr = AppLocalizations.current.locale.languageCode == 'ar';
    return '${_currencyFormatter.format(amount)} ${isAr ? 'ج.م' : 'EGP'}';
  }

  /// Compact EGP format e.g. "45.2K EGP" or "45.2K ج.م"
  static String formatCompactEGP(double amount) {
    final isAr = AppLocalizations.current.locale.languageCode == 'ar';
    return '${_compactFormatter.format(amount)} ${isAr ? 'ج.م' : 'EGP'}';
  }

  /// Format Date
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Format Date & Time
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Format Time
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date);
  }

  /// Format Egyptian Phone Numbers e.g. "+20 100 000 0000"
  static String formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 11 && clean.startsWith('01')) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 7)} ${clean.substring(7)}';
    }
    return phone;
  }
}
