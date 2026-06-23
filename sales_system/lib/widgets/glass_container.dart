import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_liquid_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final ImageFilter? backdropFilter;
  final bool enableBlur;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool enableHover;
  final Duration animationDuration;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = GlassLiquidTheme.radiusLarge,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.backdropFilter,
    this.enableBlur = true,
    this.gradient,
    this.onTap,
    this.enableHover = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.25),
          width: borderWidth,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: GlassLiquidTheme.glassShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
      ),
      child: enableBlur
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: backdropFilter ?? GlassLiquidTheme.backdropBlur,
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
    );

    if (onTap != null) {
      return AnimatedContainer(
        duration: animationDuration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: container,
          ),
        ),
      );
    }

    return container;
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool enableHover;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.margin,
    this.borderRadius = GlassLiquidTheme.radiusLarge,
    this.backgroundColor,
    this.borderColor,
    this.enableHover = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      enableHover: enableHover,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: GlassLiquidTheme.spacingMedium),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: GlassLiquidTheme.heading3,
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool isEnabled;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = GlassLiquidTheme.radiusMedium,
    this.padding,
    this.width,
    this.height,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GlassContainer(
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: GlassLiquidTheme.spacingLarge,
              vertical: GlassLiquidTheme.spacingMedium,
            ),
            borderRadius: widget.borderRadius,
            backgroundColor: widget.backgroundColor ?? GlassLiquidTheme.glassSecondary,
            borderColor: widget.borderColor ?? GlassLiquidTheme.glassBorder,
            enableBlur: true,
            onTap: widget.isEnabled && !widget.isLoading ? () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              widget.onPressed?.call();
            } : null,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          GlassLiquidTheme.textPrimary,
                        ),
                      ),
                    )
                  : widget.child,
            ),
          ),
        );
      },
    );
  }
}

class GlassInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const GlassInputField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = GlassLiquidTheme.radiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      backgroundColor: backgroundColor ?? GlassLiquidTheme.glassPrimary,
      borderColor: borderColor ?? GlassLiquidTheme.glassBorder,
      borderRadius: borderRadius,
      enableBlur: true,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        style: GlassLiquidTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: GlassLiquidTheme.bodyMedium.copyWith(
            color: GlassLiquidTheme.textTertiary,
          ),
          labelStyle: GlassLiquidTheme.bodyMedium,
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(child: prefixIcon),
                  ),
                )
              : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: GlassLiquidTheme.accentBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: GlassLiquidTheme.accentRed,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: GlassLiquidTheme.accentRed,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: GlassLiquidTheme.spacingMedium,
            vertical: GlassLiquidTheme.spacingMedium,
          ),
          filled: false,
        ),
      ),
    );
  }
}

class GlassFloatingPanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final bool enableBlur;
  final Alignment alignment;

  const GlassFloatingPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = GlassLiquidTheme.radiusXLarge,
    this.backgroundColor,
    this.enableBlur = true,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GlassContainer(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        enableBlur: enableBlur,
        boxShadow: [
          BoxShadow(
            color: GlassLiquidTheme.glassShadowLarge,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
        child: child,
      ),
    );
  }
}