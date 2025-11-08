import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _systemStats;
  List<Map<String, dynamic>> _desktopClients = [];
  List<Map<String, dynamic>> _uraUpdates = [];
  Map<String, dynamic>? _currentExchangeRate;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get systemStats => _systemStats;
  List<Map<String, dynamic>> get desktopClients => _desktopClients;
  List<Map<String, dynamic>> get uraUpdates => _uraUpdates;
  Map<String, dynamic>? get currentExchangeRate => _currentExchangeRate;

  // Initialize app data
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      await Future.wait([
        _loadSystemStats(),
        _loadDesktopClients(),
        _loadUraUpdates(),
        _loadExchangeRate(),
      ]);
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load system statistics
  Future<void> _loadSystemStats() async {
    try {
      _systemStats = await SupabaseService.getSystemStats();
      notifyListeners();
    } catch (e) {
      print('Error loading system stats: $e');
    }
  }

  // Load desktop clients
  Future<void> _loadDesktopClients() async {
    try {
      final fetched = await SupabaseService.getDesktopClients();
      // Filter out legacy/irrelevant statuses
      final newClients = fetched.where((c) {
        final s = (c['status'] ?? '').toString();
        return s == 'pending_pairing' || s == 'approved' || s == 'active';
      }).toList();
      if (newClients.isNotEmpty) {
        // Check if data actually changed
        final oldLastSeen = _desktopClients.isNotEmpty 
            ? _desktopClients.first['last_seen'] 
            : null;
        final newLastSeen = newClients.first['last_seen'];
        
        _desktopClients = newClients;
        notifyListeners();
        
        // Debug: log when data changes
        if (oldLastSeen != newLastSeen) {
          print('🔄 Desktop clients updated. Latest last_seen: $newLastSeen');
        }
      } else {
        _desktopClients = newClients;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading desktop clients: $e');
    }
  }

  // Load URA updates
  Future<void> _loadUraUpdates() async {
    try {
      _uraUpdates = await SupabaseService.getUraDatabaseUpdates();
      notifyListeners();
    } catch (e) {
      print('Error loading URA updates: $e');
    }
  }

  // Load exchange rate
  Future<void> _loadExchangeRate() async {
    try {
      _currentExchangeRate = await SupabaseService.getCurrentExchangeRate();
      notifyListeners();
    } catch (e) {
      print('Error loading exchange rate: $e');
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  // Refresh only desktop clients (for real-time updates)
  Future<void> refreshDesktopClients() async {
    await _loadDesktopClients();
  }

  // Refresh URA database updates
  Future<void> refreshUraUpdates() async {
    await _loadUraUpdates();
  }

  // Refresh exchange rate
  Future<void> refreshExchangeRate() async {
    await _loadExchangeRate();
  }

  // Update exchange rate (supports dual rates: tax and phase1)
  Future<bool> updateExchangeRate(double rate, String source, {double? phase1Rate}) async {
    _setLoading(true);
    
    try {
      // Update in Supabase
      final success = await SupabaseService.updateExchangeRate(
        rate: rate,
        source: source,
        phase1Rate: phase1Rate,
      );
      
      if (success) {
        // Also send remote command to all active desktop clients to update their local exchange rate
        for (final client in _desktopClients) {
          if (client['status'] == 'active') {
            try {
              final params = <String, dynamic>{
                'rate': rate,
                'tax_rate': rate,
              };
              if (phase1Rate != null) {
                params['phase1_rate'] = phase1Rate;
              }
              await SupabaseService.sendRemoteCommand(
                clientId: client['client_id'],
                command: 'update_exchange_rate',
                parameters: params,
              );
            } catch (e) {
              print('⚠️ Failed to update exchange rate on client ${client['client_id']}: $e');
              // Continue with other clients even if one fails
            }
          }
        }
        
        await _loadExchangeRate();
        await _loadSystemStats();
      }
      
      return success;
    } catch (e) {
      print('Error updating exchange rate: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send remote command
  Future<bool> sendRemoteCommand({
    required String clientId,
    required String command,
    Map<String, dynamic>? parameters,
  }) async {
    _setLoading(true);
    
    try {
      final success = await SupabaseService.sendRemoteCommand(
        clientId: clientId,
        command: command,
        parameters: parameters,
      );
      
      if (success) {
        await _loadDesktopClients(); // Refresh client status
      }
      
      return success;
    } catch (e) {
      print('Error sending remote command: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create URA database update
  Future<bool> createUraDatabaseUpdate({
    required String month,
    required String fileName,
    required int recordCount,
    required String fileUrl,
  }) async {
    _setLoading(true);
    
    try {
      final success = await SupabaseService.createUraDatabaseUpdate(
        month: month,
        fileName: fileName,
        recordCount: recordCount,
        fileUrl: fileUrl,
      );
      
      if (success) {
        await _loadUraUpdates();
        await _loadSystemStats();
      }
      
      return success;
    } catch (e) {
      print('Error creating URA database update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update client status
  Future<bool> updateClientStatus(String clientId, String status) async {
    _setLoading(true);
    
    try {
      final success = await SupabaseService.updateClientStatus(clientId, status);
      
      if (success) {
        await _loadDesktopClients();
        await _loadSystemStats();
      }
      
      return success;
    } catch (e) {
      print('Error updating client status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
