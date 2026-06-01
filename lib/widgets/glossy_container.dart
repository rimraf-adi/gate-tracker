import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlossyContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;

  const GlossyContainer({
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).cardColor;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
