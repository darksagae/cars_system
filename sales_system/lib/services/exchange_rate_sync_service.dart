import 'package:shared_preferences/shared_preferences.dart';

/// Applies admin-controlled exchange rates to local prefs.
class ExchangeRateSyncService {
  ExchangeRateSyncService._();
  static final ExchangeRateSyncService instance = ExchangeRateSyncService._();

  Future<void> applyRates({
    required double taxRate,
    required double cnfRate,
    bool taxRateLocked = true,
    bool cnfRateLocked = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('exchange_rate', taxRate);
    await prefs.setDouble('exchange_rate_tax', taxRate);
    await prefs.setDouble('exchange_rate_phase1', cnfRate);

    await prefs.setBool('exchange_rate_locked', taxRateLocked);
    await prefs.setBool('exchange_rate_phase1_locked', cnfRateLocked);

    if (taxRateLocked) {
      await prefs.setDouble('locked_exchange_rate', taxRate);
    }
    if (cnfRateLocked) {
      await prefs.setDouble('locked_exchange_rate_phase1', cnfRate);
    }

    await prefs.setString('exchange_rate_updated', DateTime.now().toIso8601String());
  }
}
