import 'package:flutter/material.dart';
import '../models/call_record.dart';
import '../theme/app_theme.dart';

class ThreatBadge extends StatelessWidget {
  final CallThreatLevel level;
  final bool large;

  const ThreatBadge({
    super.key,
    required this.level,
    this.large = false,
  });

  Color get _backgroundColor {
    switch (level) {
      case CallThreatLevel.safe:
        return AppColors.safeGreen.withOpacity(0.15);
      case CallThreatLevel.suspicious:
        return AppColors.warningAmber.withOpacity(0.15);
      case CallThreatLevel.dangerous:
        return AppColors.alertRedGlow;
      case CallThreatLevel.unknown:
        return AppColors.textMuted.withOpacity(0.15);
    }
  }

  Color get _textColor {
    switch (level) {
      case CallThreatLevel.safe:
        return AppColors.safeGreen;
      case CallThreatLevel.suspicious:
        return AppColors.warningAmber;
      case CallThreatLevel.dangerous:
        return AppColors.alertRed;
      case CallThreatLevel.unknown:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (level) {
      case CallThreatLevel.safe:
        return Icons.verified_user_rounded;
      case CallThreatLevel.suspicious:
        return Icons.warning_amber_rounded;
      case CallThreatLevel.dangerous:
        return Icons.dangerous_rounded;
      case CallThreatLevel.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get _label {
    switch (level) {
      case CallThreatLevel.safe:
        return 'SEGURA';
      case CallThreatLevel.suspicious:
        return 'SOSPECHOSA';
      case CallThreatLevel.dangerous:
        return '¡PELIGRO!';
      case CallThreatLevel.unknown:
        return 'DESCONOCIDA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: _textColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _textColor, size: large ? 20 : 14),
          SizedBox(width: large ? 8 : 4),
          Text(
            _label,
            style: TextStyle(
              color: _textColor,
              fontSize: large ? 14 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedThreatBadge extends StatefulWidget {
  final CallThreatLevel level;

  const AnimatedThreatBadge({super.key, required this.level});

  @override
  State<AnimatedThreatBadge> createState() => _AnimatedThreatBadgeState();
}

class _AnimatedThreatBadgeState extends State<AnimatedThreatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.level == CallThreatLevel.dangerous) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.level == CallThreatLevel.dangerous) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: ThreatBadge(level: widget.level, large: true),
          );
        },
      );
    }
    return ThreatBadge(level: widget.level, large: true);
  }
}
