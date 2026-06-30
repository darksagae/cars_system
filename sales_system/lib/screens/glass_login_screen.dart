import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/cloud_api_service.dart';
import '../services/session_timeout_service.dart';
import '../database/database_helper.dart';
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
  Timer? _autoLoginDebounce;
  bool _navigatedToHome = false;

  static const Duration _autoLoginDebounceDuration = Duration(milliseconds: 400);
  
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

    _usernameController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
  }

  void _onCredentialsChanged() {
    _autoLoginDebounce?.cancel();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      return;
    }
    _autoLoginDebounce = Timer(_autoLoginDebounceDuration, _trySilentAutoLogin);
  }

  /// Runs [validateLogin] when both fields are non-empty. Invalid credentials stay silent.
  Future<void> _trySilentAutoLogin() async {
    if (!mounted || _isLoading || _navigatedToHome) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    final ok = await AuthService().validateLogin(username: username, password: password);
    if (!mounted || _isLoading || _navigatedToHome) return;
    if (ok) {
      try {
        final online = await CloudApiService().isServerReachable();
        await _completeLoginSuccess(username, skipCloudLogin: !online);
      } catch (_) {
        _navigatedToHome = false;
      }
    }
  }

  Future<void> _completeLoginSuccess(
    String username, {
    bool freshMachineBind = false,
    bool skipCloudLogin = false,
  }) async {
    if (_navigatedToHome) return;

    final cloud = CloudApiService();
    final password = _passwordController.text;
    final online = !skipCloudLogin && await cloud.isServerReachable();

    if (online) {
      final loginResult = await cloud.login(
        username: username,
        password: password,
      );
      if (!loginResult.ok) {
        _navigatedToHome = false;
        throw _LoginFlowException(
          loginResult.error ?? 'Login failed',
          code: loginResult.code,
        );
      }

      final shouldWipeLocal = freshMachineBind || loginResult.freshMachineBind;
      if (shouldWipeLocal) {
        await DatabaseHelper().clearAllSalesData();
      }

      await AuthService().bindUserToThisMachine(username);
      await AuthService().upsertLocalPassword(
        username: username,
        password: password,
      );
      await cloud.syncProfileFromCloud();
      await cloud.pushProfileFromPrefs();
      await cloud.syncInvoicesFromCloud();
      await cloud.logActivity('user_login', metadata: await cloud.deviceMetaForActivity());
      await cloud.sendPresence(logActivity: true);
      cloud.startPresenceHeartbeat();
    } else {
      await AuthService().bindUserToThisMachine(username);
      await AuthService().upsertLocalPassword(
        username: username,
        password: password,
      );
    }

    _navigatedToHome = true;
    await AuthService().setCurrentUser(username);
    SessionTimeoutService.instance.startSession();
    if (!mounted) return;
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

  @override
  void dispose() {
    _autoLoginDebounce?.cancel();
    _usernameController.removeListener(_onCredentialsChanged);
    _passwordController.removeListener(_onCredentialsChanged);
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
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  if (!_isLoading) {
                    _handleLogin();
                  }
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
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
        onPressed: _isLoading ? null : _handleForgotPassword,
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

  Future<void> _handleForgotPassword() async {
    HapticFeedback.lightImpact();
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter your username first', style: GlassLiquidTheme.bodyMedium),
          backgroundColor: GlassLiquidTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final err = await CloudApiService().requestPasswordReset(username: username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              'Reset request sent. The administrator will reset your password using the mobile control app.',
          style: GlassLiquidTheme.bodyMedium,
        ),
        backgroundColor: err == null ? GlassLiquidTheme.accentGreen : GlassLiquidTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
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
    _autoLoginDebounce?.cancel();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final cloud = CloudApiService();
    final online = await cloud.isServerReachable();

    try {
      var authCheck = await AuthService().checkLogin(username: username, password: password);

      // Online: cloud may have newer credentials (admin password reset, new machine).
      if (!authCheck.ok && online) {
        final cloudLogin = await cloud.login(username: username, password: password);
        if (cloudLogin.ok) {
          await AuthService().upsertLocalPassword(username: username, password: password);
          authCheck = AuthCheckResult.success;
        } else if (cloudLogin.code == 'machine_not_bound' && mounted) {
          final link = await _confirmLinkDevice();
          if (link == true) {
            setState(() => _isLoading = true);
            final bind = await cloud.bindThisMachine(
              username: username,
              password: password,
            );
            if (!bind.ok) {
              await _showLoginError(bind.error ?? 'Could not link this device');
              return;
            }
            await AuthService().upsertLocalPassword(username: username, password: password);
            await AuthService().bindUserToThisMachine(username);
            try {
              await _completeLoginSuccess(username, freshMachineBind: true);
            } on _LoginFlowException catch (retry) {
              await _showLoginError(retry.error ?? 'Login failed');
            }
            return;
          }
          await _showLoginError(cloudLogin.error ?? 'This device is not linked to your account');
          return;
        } else {
          await _showLoginError(
            cloudLogin.error ?? 'Invalid username or password',
          );
          return;
        }
      }

      if (!authCheck.ok) {
        await _showLoginError(
          online
              ? (authCheck.error ?? 'Invalid username or password')
              : '${authCheck.error ?? 'Invalid username or password'}. '
                  'If your password was reset, connect to the internet and sign in again.',
        );
        return;
      }

      await _completeLoginSuccess(username, skipCloudLogin: !online);
    } on _LoginFlowException catch (e) {
      if (e.code == 'machine_not_bound' && mounted && online) {
        final link = await _confirmLinkDevice();
        if (link == true) {
          setState(() => _isLoading = true);
          final bind = await cloud.bindThisMachine(
            username: username,
            password: password,
          );
          if (!bind.ok) {
            await _showLoginError(bind.error ?? 'Could not link this device');
            return;
          }
          await AuthService().upsertLocalPassword(username: username, password: password);
          await AuthService().bindUserToThisMachine(username);
          try {
            await _completeLoginSuccess(username, freshMachineBind: true);
          } on _LoginFlowException catch (retry) {
            await _showLoginError(retry.error ?? 'Login failed');
          }
          return;
        }
        await _showLoginError(e.error ?? 'This device is not linked to your account');
        return;
      }
      await _showLoginError(
        e.code == 'wrong_machine'
            ? (e.error ?? 'Invalid user for this machine')
            : e.code == 'banned'
                ? (e.error ?? 'You are temporarily banned.')
                : (e.error ?? 'Login failed'),
      );
    } catch (e) {
      await _showLoginError('Login failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _confirmLinkDevice() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link this device?'),
        content: const Text(
          'This account is not linked to this computer yet. '
          'Link it now so only you can sign in on this machine. '
          'Your invoices will download from the cloud. '
          'You can still use web access from anywhere.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Link device')),
        ],
      ),
    );
  }

  Future<void> _showLoginError(String message) async {
    if (!mounted) return;
    setState(() => _isLoading = false);
    _navigatedToHome = false;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GlassLiquidTheme.bodyMedium),
        backgroundColor: GlassLiquidTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
        ),
      ),
    );
  }
}

class _LoginFlowException implements Exception {
  final String error;
  final String? code;
  const _LoginFlowException(this.error, {this.code});
}
