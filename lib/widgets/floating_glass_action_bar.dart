import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingGlassActionBar extends StatelessWidget {
  final Widget? child;
  final Widget? mainAction;
  final Widget? secondaryAction;
  final double bottomPadding;
  final double horizontalPadding;

  const FloatingGlassActionBar({
    super.key,
    this.child,
    this.mainAction,
    this.secondaryAction,
    this.bottomPadding = 30,
    this.horizontalPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomPadding,
      left: horizontalPadding,
      right: horizontalPadding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child ?? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (mainAction != null) Expanded(child: mainAction!),
                if (secondaryAction != null) ...[
                  const SizedBox(width: 8),
                  secondaryAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
