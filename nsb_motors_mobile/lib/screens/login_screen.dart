import 'package:flutter/material.dart';
import '../services/cloud_control_service.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_bezel_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cloud = CloudControlService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Enter your control panel username first');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final err = await _cloud.requestPasswordReset(username: username, source: 'control_panel');
      if (!mounted) return;
      if (err != null) {
        setState(() => _errorMessage = err);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A password reset link has been sent to the registered control panel email.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _cloud.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: LeonColors.canvas,
      body: SafeArea(
        child: wide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(child: _buildHeroImage(fullHeight: true)),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildFormCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.28, child: _buildHeroImage()),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFormCard(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroImage({bool fullHeight = false}) {
    return Container(
      width: double.infinity,
      height: fullHeight ? double.infinity : double.infinity,
      decoration: const BoxDecoration(color: LeonColors.accentDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login/login.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: leonHeroGradient),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          if (!fullHeight)
            Positioned(
              left: 24,
              bottom: 36,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NSBMotors Ug',
                    style: LeonTypography.heading(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Mobile control panel',
                    style: LeonTypography.sans(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return LeonBezelCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/logo/logo.png',
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: LeonTypography.heading(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to continue to NSBMotors Ug',
              textAlign: TextAlign.center,
              style: LeonTypography.sans(fontSize: 13, color: LeonColors.secondary),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) _buildErrorBanner(),
            _buildUsernameField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: LeonTypography.sans(fontSize: 13, color: LeonColors.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildFooterText(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: LeonTypography.sans(color: const Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Control panel username',
            style: LeonTypography.mono(fontSize: 11, fontWeight: FontWeight.w600, color: LeonColors.secondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          style: LeonTypography.mono(color: LeonColors.ink, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'NSBMotors',
            prefixIcon: Icon(Icons.person_outline, color: LeonColors.muted, size: 20),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your username';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password',
            style: LeonTypography.mono(fontSize: 11, fontWeight: FontWeight.w600, color: LeonColors.secondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          style: LeonTypography.mono(color: LeonColors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined, color: LeonColors.muted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: LeonColors.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text('Sign In', style: LeonTypography.sans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildFooterText() {
    return Text(
      'Mobile control panel only (username NSBMotors). '
      'Machine and web use the sales account (developer). '
      'Forgot password sends a reset link to the control panel email.',
      textAlign: TextAlign.center,
      style: LeonTypography.sans(fontSize: 12, color: LeonColors.muted),
    );
  }
}
