import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _systemStats;
  List<Map<String, dynamic>> _desktopClients = [];
  List<Map<String, dynamic>> _uraUpdates = [];
  Map<String, dynamic>? _currentExchangeRate;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get systemStats => _systemStats;
  List<Map<String, dynamic>> get desktopClients => _desktopClients;
  List<Map<String, dynamic>> get uraUpdates => _uraUpdates;
  Map<String, dynamic>? get currentExchangeRate => _currentExchangeRate;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      try { _systemStats = await SupabaseService.getSystemStats(); } catch (_) {}

      try {
        final fetched = await SupabaseService.getDesktopClients();
        _desktopClients = fetched.where((c) {
          final s = (c['status'] ?? '').toString();
          return s == 'pending_pairing' || s == 'approved' || s == 'active';
        }).toList();
      } catch (_) {}

      try { _uraUpdates = await SupabaseService.getUraDatabaseUpdates(); } catch (_) {}
      try { _currentExchangeRate = await SupabaseService.getCurrentExchangeRate(); } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => initialize();

  Future<void> refreshDesktopClients() async {
    try {
      final fetched = await SupabaseService.getDesktopClients();
      _desktopClients = fetched.where((c) {
        final s = (c['status'] ?? '').toString();
        return s == 'pending_pairing' || s == 'approved' || s == 'active';
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing desktop clients: $e');
    }
  }

  Future<void> refreshUraUpdates() async {
    try {
      _uraUpdates = await SupabaseService.getUraDatabaseUpdates();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing URA updates: $e');
    }
  }

  Future<void> refreshExchangeRate() async {
    try {
      _currentExchangeRate = await SupabaseService.getCurrentExchangeRate();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing exchange rate: $e');
    }
  }

  Future<bool> updateExchangeRate(double rate, String source, {double? phase1Rate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.updateExchangeRate(
        rate: rate,
        source: source,
        phase1Rate: phase1Rate,
      );

      if (success) {
        for (final client in _desktopClients) {
          if (client['status'] == 'active') {
            try {
              final params = <String, dynamic>{'rate': rate, 'tax_rate': rate};
              if (phase1Rate != null) params['phase1_rate'] = phase1Rate;
              await SupabaseService.sendRemoteCommand(
                clientId: client['client_id'],
                command: 'update_exchange_rate',
                parameters: params,
              );
            } catch (e) {
              debugPrint('⚠️ Failed to update rate on ${client['client_id']}: $e');
            }
          }
        }

        try { _currentExchangeRate = await SupabaseService.getCurrentExchangeRate(); } catch (_) {}
        try { _systemStats = await SupabaseService.getSystemStats(); } catch (_) {}
      }

      return success;
    } catch (e) {
      debugPrint('Error updating exchange rate: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendRemoteCommand({
    required String clientId,
    required String command,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final success = await SupabaseService.sendRemoteCommand(
        clientId: clientId,
        command: command,
        parameters: parameters,
      );
      if (success) await refreshDesktopClients();
      return success;
    } catch (e) {
      debugPrint('Error sending remote command: $e');
      return false;
    }
  }

  Future<bool> createUraDatabaseUpdate({
    required String month,
    required String fileName,
    required int recordCount,
    required String fileUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.createUraDatabaseUpdate(
        month: month,
        fileName: fileName,
        recordCount: recordCount,
        fileUrl: fileUrl,
      );

      if (success) {
        try { _uraUpdates = await SupabaseService.getUraDatabaseUpdates(); } catch (_) {}
        try { _systemStats = await SupabaseService.getSystemStats(); } catch (_) {}
      }

      return success;
    } catch (e) {
      debugPrint('Error creating URA database update: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateClientStatus(String clientId, String status) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.updateClientStatus(clientId, status);

      if (success) {
          final fetched = await SupabaseService.getDesktopClients();
        _desktopClients = fetched.where((c) {
          final s = (c['status'] ?? '').toString();
          return s == 'pending_pairing' || s == 'approved' || s == 'active';
        }).toList();
        try { _systemStats = await SupabaseService.getSystemStats(); } catch (_) {}
      }

      return success;
    } catch (e) {
      debugPrint('Error updating client status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
