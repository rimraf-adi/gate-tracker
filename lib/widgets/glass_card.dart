import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
