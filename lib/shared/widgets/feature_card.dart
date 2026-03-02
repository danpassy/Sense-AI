import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'animated_fade_in.dart';

/// Carte de fonctionnalité explicative (robuste anti-overflow)
class FeatureCard extends StatelessWidget {
  final String section;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int index;

  const FeatureCard({
    super.key,
    required this.section,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textLight = isDark ? AppTheme.darkTextLight : AppTheme.textLight;

    return AnimatedFadeIn(
      delay: Duration(milliseconds: 200 + (index * 100)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de section
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 26),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          section,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // Contenu (Expanded obligatoire pour éviter overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),

                // Chevron stable (ne doit pas forcer la Row)
                if (onTap != null) ...[
                  const SizedBox(width: AppTheme.spacingS),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: textLight,
                      size: 24,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}