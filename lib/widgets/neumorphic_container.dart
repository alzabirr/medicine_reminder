import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';

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
    final bgColor = color ?? Theme.of(context).cardColor;
    
    final shadows = isPressed 
      ? AppTheme.getNeumorphicShadowInset(context) 
      : AppTheme.getNeumorphicShadow(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        boxShadow: shadows,
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
