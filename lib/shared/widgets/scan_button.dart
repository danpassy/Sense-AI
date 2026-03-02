import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'animated_fade_in.dart';

/// Bouton de scan BLE (style moderne)
class ScanButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ScanButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingXL,
                horizontal: AppTheme.spacingL,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: const Icon(
                      Icons.bluetooth_searching_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanner les appareils',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rechercher des capteurs BLE',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

