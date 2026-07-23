import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const double qarToPkrRate = 74.03;

  /// Formats an internal amount (stored in QAR) for display in the active currency.
  static String format(
    double amountInQAR,
    String currency, {
    bool includeCode = true,
    int decimalDigits = 2,
  }) {
    final double converted = currency == 'PKR' ? (amountInQAR * qarToPkrRate) : amountInQAR;
    
    final formatter = NumberFormat.currency(
      symbol: includeCode ? '$currency ' : '',
      decimalDigits: decimalDigits,
    );

    return formatter.format(converted).trim();
  }

  /// Compact formatting for charts and small labels (e.g. QAR 1.2k, PKR 85k)
  static String formatCompact(double amountInQAR, String currency) {
    final double converted = currency == 'PKR' ? (amountInQAR * qarToPkrRate) : amountInQAR;

    if (converted >= 1000000) {
      return '$currency ${(converted / 1000000).toStringAsFixed(1)}M';
    } else if (converted >= 1000) {
      return '$currency ${(converted / 1000).toStringAsFixed(1)}k';
    }
    return '$currency ${converted.toStringAsFixed(0)}';
  }

  /// Converts stored QAR value to target currency double value
  static double convert(double amountInQAR, String currency) {
    if (currency == 'PKR') {
      return amountInQAR * qarToPkrRate;
    }
    return amountInQAR;
  }

  /// Flag emoji for currency
  static String getCurrencyFlag(String currency) {
    if (currency == 'PKR') return '🇵🇰';
    return '🇶🇦';
  }

  /// Label for currency
  static String getCurrencyLabel(String currency) {
    if (currency == 'PKR') return 'Pakistani Rupee (PKR)';
    return 'Qatari Riyal (QAR)';
  }
}
