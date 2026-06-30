import 'package:flutter/material.dart';
import '../../theme/leon_theme.dart';

/// Company logo + NSBMotors Ug on every control screen.
class LeonBrandHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  const LeonBrandHeader({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logo/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: LeonColors.accentTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded, color: LeonColors.accent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NSBMotors Ug',
                  style: LeonTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LeonColors.accent,
                    letterSpacing: 0.2,
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 2),
                  Text(title!, style: LeonTypography.heading(fontSize: 22)),
                ],
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LeonTypography.sans(fontSize: 11, color: LeonColors.secondary),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
