import 'cloud_api_service.dart';
import 'exchange_rate_sync_service.dart';
import 'mv_database_sync_service.dart';

/// Pulls cloud system settings (MV DB + exchange rates) and applies locally.
class SystemSettingsSyncService {
  SystemSettingsSyncService._();
  static final SystemSettingsSyncService instance = SystemSettingsSyncService._();

  bool _syncing = false;

  Future<void> syncFromCloud() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final data = await CloudApiService().fetchSystemSettings();
      if (data == null) return;

      final version = data['version']?.toString() ?? '0';
      final localVersion = await CloudApiService().getLocalSettingsVersion();
      if (version == localVersion) return;

      final mv = data['mvDatabase'] as Map<String, dynamic>?;
      if (mv != null) {
        final month = mv['month']?.toString() ?? '';
        final pdfUrl = mv['pdfUrl']?.toString() ?? '';
        if (month.isNotEmpty && pdfUrl.isNotEmpty) {
          try {
            await MvDatabaseSyncService.instance.syncFromUrl(
              fileUrl: pdfUrl,
              month: month,
              recordCount: (mv['rowCount'] as num?)?.toInt(),
            );
          } catch (e) {
            print('MV database sync error: $e');
          }
        }
      }

      final rates = data['exchangeRates'] as Map<String, dynamic>?;
      if (rates != null) {
        final tax = (rates['taxRate'] as num?)?.toDouble();
        final cnf = (rates['cnfRate'] as num?)?.toDouble();
        if (tax != null && tax > 0) {
          await ExchangeRateSyncService.instance.applyRates(
            taxRate: tax,
            cnfRate: cnf ?? tax,
            taxRateLocked: rates['taxRateLocked'] == true,
            cnfRateLocked: rates['cnfRateLocked'] == true,
          );
        }
      }

      await CloudApiService().setLocalSettingsVersion(version);
    } finally {
      _syncing = false;
    }
  }
}
