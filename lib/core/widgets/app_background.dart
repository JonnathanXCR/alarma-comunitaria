import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool showGlows;

  const AppBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.showGlows = true,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD41111);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);
    final bgColor = backgroundColor ?? defaultBg;

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          if (showGlows) ...[
            // Background glows
            Positioned(
              top: -64,
              right: -64,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.05),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              left: -48,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.05),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Content
          child,
        ],
      ),
    );
  }
}
