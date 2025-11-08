import 'package:intl/intl.dart';

class UgandaFormatters {
  // Currency formatter for Uganda Shilling
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_UG',
    symbol: 'UGX',
    decimalDigits: 0, // Uganda Shilling doesn't use decimals
  );

  // Format currency for display
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  // Format currency for input (without symbol)
  static String formatCurrencyInput(double amount) {
    return NumberFormat('#,##0').format(amount);
  }

  // Parse currency from string
  static double parseCurrency(String value) {
    // Remove any non-numeric characters except decimal point
    String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  // Uganda VAT rate (18%)
  static const double vatRate = 18.0;

  // Format VAT rate for display
  static String formatVatRate() {
    return '${vatRate.toStringAsFixed(0)}%';
  }

  // Calculate VAT amount
  static double calculateVat(double amount) {
    return amount * (vatRate / 100);
  }

  // Format phone number for Uganda
  static String formatUgandaPhone(String phone) {
    // Remove any non-numeric characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle different formats
    if (cleanPhone.startsWith('256')) {
      // Already in international format
      return '+$cleanPhone';
    } else if (cleanPhone.startsWith('0')) {
      // Local format, convert to international
      return '+256${cleanPhone.substring(1)}';
    } else if (cleanPhone.length == 9) {
      // 9 digits without country code
      return '+256$cleanPhone';
    } else {
      // Return as is if format is unclear
      return phone;
    }
  }

  // Format date for Uganda (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date and time for Uganda
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Common Uganda business terms
  static const Map<String, String> businessTerms = {
    'payment_terms': 'Payment Terms',
    'delivery_terms': 'Delivery Terms',
    'warranty': 'Warranty',
    'return_policy': 'Return Policy',
    'mobile_money': 'Mobile Money',
    'bank_transfer': 'Bank Transfer',
    'cash_payment': 'Cash Payment',
  };

  // Uganda mobile money providers
  static const List<String> mobileMoneyProviders = [
    'MTN Mobile Money',
    'Airtel Money',
    'Equity Bank Mobile',
    'Centenary Bank Mobile',
  ];

  // Uganda major cities for address autocomplete
  static const List<String> ugandaCities = [
    'Kampala',
    'Entebbe',
    'Jinja',
    'Mbale',
    'Gulu',
    'Mbarara',
    'Masaka',
    'Fort Portal',
    'Lira',
    'Arua',
    'Soroti',
    'Kabale',
    'Hoima',
    'Masindi',
    'Kasese',
  ];

  // Uganda districts
  static const List<String> ugandaDistricts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Mbale',
    'Gulu',
    'Lira',
    'Arua',
    'Mbarara',
    'Masaka',
    'Fort Portal',
    'Kasese',
    'Kabale',
    'Soroti',
    'Hoima',
    'Masindi',
    'Nebbi',
    'Adjumani',
    'Yumbe',
    'Koboko',
  ];
}
