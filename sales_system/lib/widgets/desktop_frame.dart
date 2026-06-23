import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../screens/root_gate.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../services/session_timeout_service.dart';

class DesktopFrame extends StatelessWidget {
  final Widget child;
  final String? title;

  const DesktopFrame({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    // Check if running on desktop platform (Windows, Linux, or macOS)
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    
    if (!isDesktop) {
      return child;
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = colors.surface;
    final Color border = colors.outlineVariant.withOpacity(0.4);
    final TextStyle titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: colors.onSurface, fontWeight: FontWeight.w600);

    // On macOS, buttons are typically on the left, on Windows/Linux they're on the right
    final isMacOS = Platform.isMacOS;

    return WindowBorder(
      color: border,
      width: 1,
      child: Column(
        children: [
          // Custom draggable title bar
          // WindowTitleBarBox creates space for native title bar and makes it draggable
          // This replaces the native title bar when combined with BDW_CUSTOM_FRAME
          WindowTitleBarBox(
            child: Container(
              color: bg,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // macOS: window buttons on the left
                  if (isMacOS) const WindowButtons(),
                  // Logo sits OUTSIDE [MoveWindow] so clicks register (MoveWindow steals drags/taps).
                  Padding(
                    padding: EdgeInsets.only(left: isMacOS ? 4.0 : 8.0),
                    child: _TitleBarLogo(
                      title: title,
                      titleStyle: titleStyle,
                      colorScheme: colors,
                    ),
                  ),
                  // Remaining title bar: draggable
                  Expanded(
                    child: MoveWindow(
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Windows/Linux: window buttons on the right
                  if (!isMacOS) const WindowButtons(),
                ],
              ),
            ),
          ),
          // App content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// NSB logo in the custom title bar: goes to Dashboard (home tab) when logged in.
class _TitleBarLogo extends StatelessWidget {
  final String? title;
  final TextStyle titleStyle;
  final ColorScheme colorScheme;

  const _TitleBarLogo({
    required this.title,
    required this.titleStyle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final user = await AuthService().getCurrentUser();
            // Title bar sits outside the Navigator subtree; use MaterialApp's key.
            final nav = SessionTimeoutService.navigatorKey.currentState;
            if (nav == null) return;
            if (user != null && user.isNotEmpty) {
              nav.pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeScreen(),
                ),
                (route) => false,
              );
            } else {
              nav.pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const RootGate(),
                ),
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: colorScheme.onSurface.withOpacity(0.08),
          splashColor: colorScheme.onSurface.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Image.asset(
              'assets/logo/logo.png',
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return title != null
                    ? Text(title!, style: titleStyle)
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final buttonColors = WindowButtonColors(
      iconNormal: colors.onSurface,
      mouseOver: colors.surfaceVariant,
      mouseDown: colors.surfaceVariant.withOpacity(0.8),
      iconMouseOver: colors.onSurface,
      iconMouseDown: colors.onSurface,
    );

    final closeColors = WindowButtonColors(
      iconNormal: colors.onSurface,
      mouseOver: Colors.red.withOpacity(0.9),
      mouseDown: Colors.red,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeColors),
      ],
    );
  }
}


