import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import '../widgets/glass_liquid_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left side - Image section (full height)
              Expanded(
                flex: 1,
                child: _buildLeftSection(),
              ),
              // Right side - Login form with logo
              Expanded(
                flex: 1,
                child: _buildRightSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLeftSection() {
    return Container(
      child: Image.asset(
        'assets/login/login.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A0A1A),
                  const Color(0xFF0A0A2A),
                ],
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.car,
                color: Colors.white,
                size: 150,
              ),
            ),
          );
        },
      ),
    );
  }






  Widget _buildRightSection() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          // Logo positioned in top middle, same width as login card
          _buildTopLogo(),
          const SizedBox(height: 60),
          // Login form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: _buildLoginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLogo() {
    return Container(
      width: 450, // Same width as login card
      height: 80,
      child: Center(
        child: Image.asset(
          'assets/logo/logo.png',
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 80,
              child: Center(
                child: Text(
                  'NSB Motors Uganda',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
                color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'NSB Motors Uganda',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Username field
                  _buildModernUsernameField(),
                  const SizedBox(height: 24),
                  
                  // Password field
                  _buildModernPasswordField(),
                  const SizedBox(height: 16),
                  
                  // Forgot password
                  _buildForgotPassword(),
                  const SizedBox(height: 32),
                  
                  // Sign in button
                  _buildModernLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter Username',
        hintStyle: GoogleFonts.poppins(
          color: Colors.white60,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: GlassLiquidTheme.accentBlue,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your username';
            }
            return null;
          },
    );
  }

  Widget _buildModernPasswordField() {
    return TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
        fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
        hintText: 'Enter Password',
            hintStyle: GoogleFonts.poppins(
              color: Colors.white60,
          fontSize: 16,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: FaIcon(
                _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                color: Colors.white60,
                size: 18,
              ),
            ),
            filled: true,
        fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: GlassLiquidTheme.accentBlue,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
    );
  }

  Widget _buildModernLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              'Sign In',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contact administrator for password reset',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final isValid = await AuthService().validateLogin(username: username, password: password);
    if (isValid) {
      // Login successful
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } else {
      // Login failed
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid username or password',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
