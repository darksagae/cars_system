import 'package:flutter/material.dart';
import '../../theme/leon_theme.dart';

/// Uppercase mono section label — mirrors `.leon-section-header__title`.
class LeonSectionHeader extends StatelessWidget {
  const LeonSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.color = LeonColors.accent,
  });

  final String title;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: LeonTypography.mono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.4,
      ),
    );

    if (trailing == null) return label;

    return Row(
      children: [
        Expanded(child: label),
        trailing!,
      ],
    );
  }
}
