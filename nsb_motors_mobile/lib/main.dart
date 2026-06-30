import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/leon_theme.dart';
import 'services/cloud_control_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const NSBMotorsControlApp());
}

class NSBMotorsControlApp extends StatelessWidget {
  const NSBMotorsControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NSBMotors Ug',
      debugShowCheckedModeBanner: false,
      theme: buildLeonTheme(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _cloud = CloudControlService();
  bool _checking = true;
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await _cloud.isAuthenticated && await _cloud.isAdmin;
    if (mounted) {
      setState(() {
        _authed = ok;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return _authed ? const HomeScreen() : const LoginScreen();
  }
}
