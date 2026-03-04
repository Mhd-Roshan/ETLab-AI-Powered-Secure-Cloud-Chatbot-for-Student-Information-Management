import 'package:flutter/material.dart';

class LiquidGlassButton extends StatelessWidget {
  final Widget label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isFullWidth;

  const LiquidGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        label,
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        // Liquid glass: frosted clear background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.70),
            Colors.white.withOpacity(0.30),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.90), width: 1.5),
        boxShadow: [
          // Soft outer shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // Inner highlight shimmer
          BoxShadow(
            color: Colors.white.withOpacity(0.40),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(14),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                child: IconTheme(
                  data: IconThemeData(color: Colors.grey.shade800, size: 20),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

