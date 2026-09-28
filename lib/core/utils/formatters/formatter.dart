import 'package:intl/intl.dart';

class TFormatter {
  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat(
      'dd-MMM-yyyy',
    ).format(date); // Customize the date format as needed
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Format Indian phone number: +91 98765 43210
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Handle different input formats and normalize to +91XXXXXXXXXX
    String normalized = digitsOnly;

    if (normalized.startsWith('0') && normalized.length == 11) {
      // 09876543210 -> 9876543210
      normalized = normalized.substring(1);
    } else if (normalized.startsWith('91') && normalized.length == 12) {
      // 919876543210 -> 9876543210
      normalized = normalized.substring(2);
    } else if (normalized.startsWith('+91') && normalized.length == 13) {
      // +919876543210 -> 9876543210 (but digitsOnly would strip +)
    }

    // Format as +91 XXXXX XXXXX
    if (normalized.length == 10) {
      return '+91 ${normalized.substring(0, 5)} ${normalized.substring(5)}';
    } else if (normalized.length == 11 && normalized.startsWith('0')) {
      // 09876543210 -> +91 98765 43210
      final num = normalized.substring(1);
      return '+91 ${num.substring(0, 5)} ${num.substring(5)}';
    }

    // Return original if can't format
    return phoneNumber;
  }

  // Not fully tested.
  static String internationalFormatPhoneNumber(String phoneNumber) {
    // Format as +91 XXXXX XXXXX for Indian numbers
    return formatPhoneNumber(phoneNumber);
  }
}

/*
*
*
* */
