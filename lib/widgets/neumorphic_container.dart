import 'package:flutter/material.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadiusGeometry? customBorderRadius;
  final bool isPressed;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.customBorderRadius,
    this.padding,
    this.margin,
    this.color,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? const Color(0xFFEFEEEE); // Neumorphic Base
    
    // Light Mode Shadows
    // Shadow 1 (Bottom Right): Darker Grey
    // Shadow 2 (Top Left): White

    List<BoxShadow> shadows = isPressed
        ? [
            // Inner shadow simulation
            BoxShadow(
              color: Colors.white,
              offset: const Offset(4.0, 4.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(-4.0, -4.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
          ]
        : [
            // Standard "Extruded" look
            BoxShadow(
              color: Colors.grey.shade400, // Darker shadow
              offset: const Offset(6.0, 6.0),
              blurRadius: 16.0,
              spreadRadius: 1.0,
            ),
            const BoxShadow(
              color: Colors.white, // Light highlight
              offset: const Offset(-6.0, -6.0),
              blurRadius: 16.0,
              spreadRadius: 1.0,
            ),
          ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        boxShadow: shadows,
        // Optional: Gradient for subtle convexity
        gradient: isPressed
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                ],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
