import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/cloud_api_service.dart';
import '../widgets/glass_liquid_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Setup New Device',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account (internet required)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter a username';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cloud = CloudApiService();
      if (!await cloud.isServerReachable()) {
        throw Exception(
          'Internet connection is required to register. Connect to the internet and try again.',
        );
      }

      final hasAnyUser = await _auth.hasAnyUser();
      final role = hasAnyUser ? 'user' : 'admin';
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      final registered = await cloud.register(
        username: username,
        password: password,
        role: role,
        displayName: username,
      );
      if (!registered) {
        throw Exception('This machine is already registered to another account.');
      }

      final machineId = await _auth.getThisMachineId();
      await _auth.createUser(
        username: username,
        password: password,
        role: role,
        machineId: machineId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              role == 'admin' 
                ? 'Admin account created successfully! Please sign in.' 
                : 'Account created. Please sign in.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: GlassLiquidTheme.accentGreen,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.poppins()),
            backgroundColor: GlassLiquidTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}



