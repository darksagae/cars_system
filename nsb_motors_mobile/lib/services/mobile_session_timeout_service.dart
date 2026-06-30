import 'dart:async';
import 'package:flutter/material.dart';

/// Signs the admin out after [idleLimit] with no touch or key activity.
class MobileSessionTimeoutService {
  MobileSessionTimeoutService._();
  static final MobileSessionTimeoutService instance = MobileSessionTimeoutService._();

  static const Duration idleLimit = Duration(minutes: 5);
  static const Duration _tick = Duration(seconds: 15);

  DateTime _lastActivity = DateTime.now();
  bool _active = false;
  Timer? _timer;
  VoidCallback? _onTimeout;

  void start(VoidCallback onTimeout) {
    _onTimeout = onTimeout;
    _active = true;
    _lastActivity = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _checkIdle());
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
  }

  void recordActivity() {
    if (!_active) return;
    _lastActivity = DateTime.now();
  }

  Future<void> checkIdleOnResume() async {
    if (!_active) return;
    if (DateTime.now().difference(_lastActivity) >= idleLimit) {
      await _lockOut();
    }
  }

  Future<void> _checkIdle() async {
    if (!_active) return;
    if (DateTime.now().difference(_lastActivity) >= idleLimit) {
      await _lockOut();
    }
  }

  Future<void> _lockOut() async {
    stop();
    _onTimeout?.call();
  }
}

/// Bumps idle timer on pointer and keyboard activity.
class SessionActivityWrapper extends StatelessWidget {
  final Widget child;

  const SessionActivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => MobileSessionTimeoutService.instance.recordActivity(),
      child: Focus(
        onKeyEvent: (_, __) {
          MobileSessionTimeoutService.instance.recordActivity();
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }
}
