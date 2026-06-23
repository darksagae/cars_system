import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_service.dart';
import '../screens/glass_login_screen.dart';

/// Tracks user activity while logged in and locks the app after [idleLimit] of inactivity.
class SessionTimeoutService {
  SessionTimeoutService._();
  static final SessionTimeoutService instance = SessionTimeoutService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const Duration idleLimit = Duration(minutes: 5);
  static const Duration _tick = Duration(seconds: 15);

  DateTime _lastActivity = DateTime.now();
  bool _sessionActive = false;
  Timer? _timer;

  bool get isSessionActive => _sessionActive;

  void startSession() {
    _sessionActive = true;
    _lastActivity = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _checkIdle());
  }

  void stopSession() {
    _sessionActive = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Call on pointer, mouse, or keyboard activity while the session is active.
  void recordActivity() {
    if (!_sessionActive) return;
    _lastActivity = DateTime.now();
  }

  /// When the app returns to foreground, lock immediately if still over the limit.
  Future<void> checkIdleOnResume() async {
    if (!_sessionActive) return;
    final user = await AuthService().getCurrentUser();
    if (user == null || user.isEmpty) {
      stopSession();
      return;
    }
    if (DateTime.now().difference(_lastActivity) >= idleLimit) {
      await _lockOut();
    }
  }

  Future<void> _checkIdle() async {
    if (!_sessionActive) return;
    final user = await AuthService().getCurrentUser();
    if (user == null || user.isEmpty) {
      stopSession();
      return;
    }
    if (DateTime.now().difference(_lastActivity) >= idleLimit) {
      await _lockOut();
    }
  }

  Future<void> _lockOut() async {
    stopSession();
    await AuthService().clearCurrentUser();
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const GlassLoginScreen()),
      (_) => false,
    );
  }
}

/// Wraps the app to bump user activity on pointer and keyboard input.
class SessionActivityWrapper extends StatefulWidget {
  const SessionActivityWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<SessionActivityWrapper> createState() => _SessionActivityWrapperState();
}

class _SessionActivityWrapperState extends State<SessionActivityWrapper> {
  bool _handleKey(KeyEvent event) {
    SessionTimeoutService.instance.recordActivity();
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionTimeoutService.instance.recordActivity(),
      onPointerSignal: (_) => SessionTimeoutService.instance.recordActivity(),
      child: widget.child,
    );
  }
}
