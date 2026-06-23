import 'package:flutter/material.dart';
import 'glass_login_screen.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _loading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      // QR CODE SCANNING DEACTIVATED
      // Skip pairing check entirely - go straight to user authentication
      // For new devices, user will create account with username/password/confirm password
      final hasUser = await AuthService().hasAnyUser();
      
      setState(() {
        _hasUser = hasUser;
        _loading = false;
      });
    } catch (e) {
      // If there's any error, default to no user (will show signup screen)
      print('Error in user check: $e');
      setState(() {
        _hasUser = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // QR CODE SCANNING DEACTIVATED - Skip PairingLockScreen
    // Direct to signup if no user exists, otherwise login
    if (!_hasUser) {
      return const SignupScreen(); // New device: Create account with username/password/confirm password
    }
    return const GlassLoginScreen(); // Existing device: Login with username/password
  }
}