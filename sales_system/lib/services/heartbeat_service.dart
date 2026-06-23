import 'dart:async';
import 'pairing_service.dart';
import 'remote_command_service.dart';

class HeartbeatService {
  static final HeartbeatService _instance = HeartbeatService._internal();
  factory HeartbeatService() => _instance;
  HeartbeatService._internal();

  Timer? _timer;
  final RemoteCommandService _remote = RemoteCommandService();

  Future<void> start({Duration interval = const Duration(seconds: 20)}) async {
    _timer?.cancel();
    final paired = await PairingService().isPaired();
    if (!paired) return;
    try {
      await _remote.initialize();
    } catch (_) {}
    _timer = Timer.periodic(interval, (_) async {
      try {
        // updateLastSeen has built-in retry logic, so we don't need to catch here
        await _remote.updateLastSeen();
      } catch (e) {
        // Only log unexpected errors (shouldn't happen since updateLastSeen handles retries)
        print('⚠️ Unexpected error in heartbeat: $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}



