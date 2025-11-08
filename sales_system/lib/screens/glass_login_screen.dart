import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_liquid_theme.dart';
import '../widgets/glass_container.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';

class GlassLoginScreen extends StatefulWidget {
  const GlassLoginScreen({super.key});

  @override
  State<GlassLoginScreen> createState() => _GlassLoginScreenState();
}

class _GlassLoginScreenState extends State<GlassLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _formAnimationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Left side - Image section (50%)
                  Expanded(
                    flex: 1,
                    child: _buildLeftSection(),
                  ),
                  // Right side - Login form (50%)
                  Expanded(
                    flex: 1,
                    child: _buildRightSection(),
                  ),
                ],
              ),
            ),
          );
        },
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
      child: Center(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _formAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _formAnimation.value)),
                child: Opacity(
                  opacity: _formAnimation.value,
                  child: _buildLoginForm(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }



  Widget _buildLoginForm() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 450,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusXXLarge),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: GlassLiquidTheme.glassShadowLarge,
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(GlassLiquidTheme.spacingXXLarge),
        child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and header
            _buildHeader(),
            const SizedBox(height: GlassLiquidTheme.spacingXXLarge),
            
            // Username field
            _buildUsernameField(),
            const SizedBox(height: GlassLiquidTheme.spacingLarge),
            
            // Password field
            _buildPasswordField(),
            const SizedBox(height: GlassLiquidTheme.spacingMedium),
            
            // Forgot password
            _buildForgotPassword(),
            const SizedBox(height: GlassLiquidTheme.spacingXLarge),
            
            // Sign in button
            _buildLoginButton(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo (original shape)
        Center(
          child: SizedBox(
            width: 140,
            height: 80,
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: GlassLiquidTheme.spacingLarge),
        
        // Title
        Text(
          'Welcome Back',
          style: GlassLiquidTheme.heading1.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: GlassLiquidTheme.spacingSmall),
        Text(
          'Sign in to continue to NSB Motors Uganda',
          style: GlassLiquidTheme.bodyLarge.copyWith(
            color: GlassLiquidTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return GlassInputField(
      controller: _usernameController,
      hintText: 'Enter your username',
      prefixIcon: FaIcon(
        FontAwesomeIcons.user,
        color: GlassLiquidTheme.textSecondary,
        size: 16,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return GlassInputField(
      controller: _passwordController,
      hintText: 'Enter your password',
      obscureText: _obscurePassword,
      prefixIcon: FaIcon(
        FontAwesomeIcons.lock,
        color: GlassLiquidTheme.textSecondary,
        size: 16,
      ),
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        icon: FaIcon(
          _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
          color: GlassLiquidTheme.textSecondary,
          size: 16,
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

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GlassButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Contact administrator for password reset',
                style: GlassLiquidTheme.bodyMedium,
              ),
              backgroundColor: GlassLiquidTheme.accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: GlassLiquidTheme.spacingMedium,
          vertical: GlassLiquidTheme.spacingSmall,
        ),
        child: Text(
          'Forgot Password?',
          style: GlassLiquidTheme.bodyMedium.copyWith(
            color: GlassLiquidTheme.accentBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GlassButton(
        onPressed: _isLoading ? null : _handleLogin,
        isEnabled: !_isLoading,
        backgroundColor: GlassLiquidTheme.accentBlue.withOpacity(0.2),
        borderColor: GlassLiquidTheme.accentBlue.withOpacity(0.5),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: GlassLiquidTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: GlassLiquidTheme.spacingSmall),
                  FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final isValid = await AuthService().validateLogin(username: username, password: password);
    if (isValid) {
      await AuthService().setCurrentUser(username);
      // Login successful
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      // Login failed
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid username or password',
              style: GlassLiquidTheme.bodyMedium,
            ),
            backgroundColor: GlassLiquidTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }
}
