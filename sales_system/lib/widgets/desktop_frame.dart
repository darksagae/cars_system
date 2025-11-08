import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

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
                  // Title area (draggable) - this covers where native title bar would be
                  Expanded(
                    child: MoveWindow(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo instead of text title
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.asset(
                                'assets/logo/logo.png',
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to text if logo not found
                                  return title != null
                                      ? Text(title!, style: titleStyle)
                                      : const SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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


