import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? color;
  final double size;
  final String? tooltip;

  const ControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.color,
    this.size = 48,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.neonAccent;

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.25)
            : AppColors.cardBackground.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? activeColor : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: activeColor.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: AppColors.primaryViolet.withValues(alpha: 0.3),
          highlightColor: AppColors.primaryViolet.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.48,
              color: isActive ? activeColor : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
