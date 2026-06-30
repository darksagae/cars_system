import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/leon_theme.dart';

/// Double-bezel liquid-glass card — mirrors web `.leon-bezel-outer` / `.leon-bezel-inner`.
class LeonBezelCard extends StatelessWidget {
  const LeonBezelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.accentBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    final outer = Container(
      margin: margin,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -1),
          end: const Alignment(0.8, 1),
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0.1),
            LeonColors.accentDark.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        boxShadow: [
          BoxShadow(
            color: LeonColors.accentDark.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: const Alignment(-0.6, -1),
                end: const Alignment(0.6, 1),
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.44),
                  LeonColors.accentLight.withValues(alpha: 0.64),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: accentBorder
                ? DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: LeonColors.accent, width: 4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );

    if (onTap == null) return outer;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: outer,
      ),
    );
  }
}
