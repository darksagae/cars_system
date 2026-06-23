import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_liquid_theme.dart';
import 'glass_container.dart';

class GlassStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int animationDelay;

  const GlassStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.animationDelay = 0,
  });
  @override
  State<GlassStatCard> createState() => _GlassStatCardState();
}

class _GlassStatCardState extends State<GlassStatCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovering ? const Color(0xFFFFF1E6) : GlassLiquidTheme.glassPrimary;
    final br = _isHovering ? const Color(0xFFFFE4C7) : GlassLiquidTheme.glassBorder;
    final textColor = _isHovering ? Colors.black : GlassLiquidTheme.textPrimary;
    final subText = _isHovering ? Colors.black.withOpacity(0.7) : GlassLiquidTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bg == const Color(0xFFFFF1E6) ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
          border: Border.all(
            color: br == const Color(0xFFFFE4C7) ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
          ),
        ),
        padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingSmall),
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(_isHovering ? 0.15 : 0.2),
                  borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
                  border: Border.all(
                      color: widget.color.withOpacity(_isHovering ? 0.4 : 0.3),
                    width: 1,
                  ),
                ),
                child: FaIcon(
                    widget.icon,
                    color: _isHovering ? Colors.black : widget.color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GlassLiquidTheme.spacingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(_isHovering ? 0.14 : 0.1),
                  borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
                ),
                child: Text(
                  'LIVE',
                  style: GlassLiquidTheme.caption.copyWith(
                      color: _isHovering ? Colors.black : widget.color,
                    fontWeight: FontWeight.w600,
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Text(
              widget.value,
            style: GlassLiquidTheme.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
                color: textColor,
              ),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          Text(
              widget.title,
            style: GlassLiquidTheme.bodyMedium.copyWith(
                color: subText,
              ),
          ),
        ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: widget.animationDelay))
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
    );
  }
}

class GlassActivityCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? time;
  final VoidCallback? onTap;

  const GlassActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.time,
    this.onTap,
  });
  @override
  State<GlassActivityCard> createState() => _GlassActivityCardState();
}

class _GlassActivityCardState extends State<GlassActivityCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovering ? const Color(0xFFFFF1E6) : GlassLiquidTheme.glassSecondary;
    final br = _isHovering ? const Color(0xFFFFE4C7) : GlassLiquidTheme.glassBorder.withOpacity(0.5);
    final titleColor = _isHovering ? Colors.black : GlassLiquidTheme.textPrimary;
    final subColor = _isHovering ? Colors.black.withOpacity(0.7) : GlassLiquidTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bg == const Color(0xFFFFF1E6) ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
          border: Border.all(
            color: br == const Color(0xFFFFE4C7) ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
          ),
        ),
        padding: const EdgeInsets.all(GlassLiquidTheme.spacingMedium),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
          child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(GlassLiquidTheme.spacingSmall),
            decoration: BoxDecoration(
                color: widget.color.withOpacity(_isHovering ? 0.15 : 0.2),
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
            ),
            child: FaIcon(
                widget.icon,
                color: _isHovering ? Colors.black : widget.color,
              size: 16,
            ),
          ),
          const SizedBox(width: GlassLiquidTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.title,
                  style: GlassLiquidTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                ),
                const SizedBox(height: 4),
                Text(
                    widget.subtitle,
                    style: GlassLiquidTheme.bodySmall.copyWith(color: subColor),
                ),
              ],
            ),
          ),
            if (widget.time != null)
            Text(
                widget.time!,
                style: GlassLiquidTheme.caption.copyWith(color: subColor),
            ),
        ],
          ),
        ),
      ),
    );
  }
}

class GlassQuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassQuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<GlassQuickActionCard> createState() => _GlassQuickActionCardState();
}

class _GlassQuickActionCardState extends State<GlassQuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: GlassLiquidTheme.glassShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: widget.color.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                child: Column(
                  children: [
                    FaIcon(
                      widget.icon,
                      color: widget.color,
                      size: 32,
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingSmall),
                    Text(
                      widget.title,
                      style: GlassLiquidTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GlassLiquidTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GlassNavigationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const GlassNavigationCard({
    super.key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: GlassLiquidTheme.spacingMedium,
        vertical: GlassLiquidTheme.spacingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            color: isSelected ? GlassLiquidTheme.accentBlue : GlassLiquidTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: GlassLiquidTheme.spacingSmall),
          Text(
            title,
            style: GlassLiquidTheme.bodyMedium.copyWith(
              color: isSelected ? GlassLiquidTheme.accentBlue : GlassLiquidTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class GlassProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressText;
  final Color color;
  final IconData icon;

  const GlassProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressText,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Hoverable(
      builder: (isHovering) {
        final bg = isHovering ? const Color(0xFFFFF1E6) : GlassLiquidTheme.glassPrimary;
        final br = isHovering ? const Color(0xFFFFE4C7) : GlassLiquidTheme.glassBorder;
        final titleColor = isHovering ? Colors.black : GlassLiquidTheme.textPrimary;
        final subColor = isHovering ? Colors.black.withOpacity(0.7) : GlassLiquidTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg == const Color(0xFFFFF1E6) ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
        border: Border.all(
          color: br == const Color(0xFFFFE4C7) ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                color: isHovering ? Colors.black : color,
                size: 20,
              ),
              const SizedBox(width: GlassLiquidTheme.spacingSmall),
              Text(
                title,
                style: GlassLiquidTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              Text(
                progressText,
                style: GlassLiquidTheme.bodyMedium.copyWith(
                  color: isHovering ? Colors.black : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: isHovering ? Colors.black.withOpacity(0.08) : GlassLiquidTheme.glassSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isHovering ? Colors.black : color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isHovering ? Colors.black : color).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _Hoverable extends StatefulWidget {
  final Widget Function(bool isHovering) builder;
  const _Hoverable({required this.builder});
  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: widget.builder(_isHovering),
    );
  }
}
