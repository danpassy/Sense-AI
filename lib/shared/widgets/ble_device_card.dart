import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/theme/app_theme.dart';
import 'animated_fade_in.dart';

/// Carte d'appareil BLE avec design moderne
class BleDeviceCard extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback? onTap;
  final int index;
  final bool isKnown;

  const BleDeviceCard({
    super.key,
    required this.scanResult,
    this.onTap,
    this.index = 0,
    this.isKnown = false,
  });

  String _getDeviceName(BluetoothDevice device) {
    final name = device.platformName;
    if (name.isNotEmpty) return name;
    return 'Périphérique inconnu';
  }

  String _getRssiLabel(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -70) return 'Bon';
    if (rssi >= -85) return 'Moyen';
    return 'Faible';
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return AppTheme.successColor;
    if (rssi >= -70) return AppTheme.primaryColor;
    if (rssi >= -85) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final device = scanResult.device;
    final name = _getDeviceName(device);
    final rssi = scanResult.rssi;
    final rssiLabel = _getRssiLabel(rssi);
    final rssiColor = _getRssiColor(rssi);

    final knownColor = AppTheme.successColor;
    final borderColor = isKnown ? knownColor.withOpacity(0.4) : rssiColor.withOpacity(0.2);
    final borderWidth = isKnown ? 2.0 : 1.5;

    return AnimatedFadeIn(
      delay: Duration(milliseconds: 100 + (index * 50)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isKnown
                  ? [
                      BoxShadow(
                        color: knownColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : AppTheme.softShadow,
            ),
            child: Row(
              children: [
                // Icône Bluetooth
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isKnown
                          ? [knownColor.withOpacity(0.2), knownColor.withOpacity(0.1)]
                          : [rssiColor.withOpacity(0.2), rssiColor.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    isKnown ? Icons.verified_rounded : Icons.bluetooth_connected_rounded,
                    color: isKnown ? knownColor : rssiColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // Infos (doit être flexible pour éviter overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne: Nom + badge "Connu"
                      Row(
                        children: [
                          // Nom : ellipsis obligatoire
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                            ),
                          ),

                          if (isKnown) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: knownColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 12, color: knownColor),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Connu',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: knownColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Ligne RSSI
                      Row(
                        children: [
                          Icon(Icons.signal_cellular_alt_rounded, size: 14, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$rssi dBm • $rssiLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // ID device
                      Text(
                        device.remoteId.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingS),

                // Badge RSSI (contraint pour éviter overflow)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rssiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: rssiColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      rssiLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: rssiColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingS),

                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}