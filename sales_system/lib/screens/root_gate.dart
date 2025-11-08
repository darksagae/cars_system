import 'package:flutter/material.dart';
import '../services/pairing_service.dart';
import 'pairing_lock_screen.dart';
import 'glass_login_screen.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final PairingService _pairingService = PairingService();
  bool _loading = true;
  bool _paired = false;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final paired = await _pairingService.isPaired();
    bool hasUser = false;
    if (paired) {
      hasUser = await AuthService().hasAnyUser();
    }
    setState(() {
      _paired = paired;
      _hasUser = hasUser;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_paired) {
      return const PairingLockScreen();
    }
    if (!_hasUser) {
      return const SignupScreen();
    }
    return const GlassLoginScreen();
  }
}


