import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.glowColor,
    this.onTap,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glowColor ?? AppColors.neonCyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: effectiveGlow.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveGlow.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: effectiveGlow.withOpacity(0.1),
              highlightColor: effectiveGlow.withOpacity(0.05),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Widget child;
  final bool isActive;

  const AlertCard({super.key, required this.child, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.alertRedGlow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.alertRed.withOpacity(isActive ? 0.6 : 0.2),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.alertRed.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.activeLabel,
    required this.inactiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? AppColors.safeGreen : AppColors.alertRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isActive ? AppColors.safeGreen : AppColors.alertRed)
                    .withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? activeLabel : inactiveLabel,
          style: TextStyle(
            color: isActive ? AppColors.safeGreen : AppColors.alertRed,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
