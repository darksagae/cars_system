import 'package:flutter/material.dart';
import '../services/cloud_control_service.dart';
import '../services/mobile_session_timeout_service.dart';
import '../theme/leon_theme.dart';
import 'accounts_screen.dart';
import 'control_settings_screen.dart';
import 'home_tab_screen.dart';
import 'login_screen.dart';
import 'updates_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MobileSessionTimeoutService.instance.start(_logout);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MobileSessionTimeoutService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MobileSessionTimeoutService.instance.checkIdleOnResume();
    }
  }

  void _logout() async {
    MobileSessionTimeoutService.instance.stop();
    await CloudControlService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTabScreen(onGoToAccounts: () => setState(() => _selectedIndex = 1)),
      const AccountsScreen(),
      const UpdatesScreen(),
      ControlSettingsScreen(onLogout: _logout),
    ];

    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.people_rounded, label: 'Accounts'),
      _NavItem(icon: Icons.system_update_alt_rounded, label: 'Updates'),
      _NavItem(icon: Icons.tune_rounded, label: 'Settings'),
    ];

    return SessionActivityWrapper(
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: _buildFloatingNav(navItems),
      ),
    );
  }

  Widget _buildFloatingNav(List<_NavItem> navItems) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: LeonColors.accentDark,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: LeonColors.accentDark.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  MobileSessionTimeoutService.instance.recordActivity();
                  setState(() => _selectedIndex = index);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: LeonTypography.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
