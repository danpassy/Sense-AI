import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/ble_constants.dart';
import '../../../../shared/widgets/animated_fade_in.dart';

/// Page d'information détaillée sur l'acquisition et la communication
class AcquisitionInfoPage extends StatelessWidget {
  const AcquisitionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Acquisition et Communication',
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header avec icône
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark),
            ),
            
            // Section Communication
            SliverToBoxAdapter(
              child: _buildCommunicationSection(context, isDark),
            ),
            
            // Section Données Communiquées
            SliverToBoxAdapter(
              child: _buildDataSection(context, isDark),
            ),
            
            // Section Capteurs
            SliverToBoxAdapter(
              child: _buildSensorsSection(context, isDark),
            ),
            
            // Section Architecture
            SliverToBoxAdapter(
              child: _buildArchitectureSection(context, isDark),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 100),
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingL),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
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
        child: Column(
          children: [
            Icon(
              Icons.bluetooth_connected_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Système d\'Acquisition et Communication',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Communication Bluetooth Low Energy (BLE)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationSection(BuildContext context, bool isDark) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Comment la Communication Fonctionne',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.devices_rounded,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            'Compatibilité: connexion possible à une carte STM32 et à une carte Nordic nRF54L15.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildInfoItem(
                    context,
                    'Protocole',
                    'Bluetooth Low Energy (BLE) 5.0',
                    Icons.bluetooth_rounded,
                    AppTheme.primaryColor,
                    isDark,
                  ),
                  const Divider(height: 24),
                  _buildInfoItem(
                    context,
                    'Périphérique',
                    'STM32 (ex: STM32WB55) ou Nordic nRF54L15',
                    Icons.memory_rounded,
                    AppTheme.accentColor,
                    isDark,
                  ),
                  const Divider(height: 24),
                  _buildInfoItem(
                    context,
                    'Fréquence d\'émission',
                    '1 Hz (1 fois par seconde)',
                    Icons.schedule_rounded,
                    AppTheme.successColor,
                    isDark,
                  ),
                  const Divider(height: 24),
                  _buildInfoItem(
                    context,
                    'Portée',
                    'Jusqu\'à 10 mètres',
                    Icons.signal_cellular_alt_rounded,
                    AppTheme.warningColor,
                    isDark,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildServicesList(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services BLE Utilisés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildServiceCard(
          context,
          'My_P2PS (Personnalisé)',
          'Service principal pour les données personnalisées',
          [
            'LED_C : Contrôle de la LED',
            'SWITCH_C : Notifications du bouton',
            'LONG_C : Données longues (température, accéléromètre, gyroscope)',
          ],
          BleConstants.serviceP2PUuid,
          AppTheme.primaryColor,
          isDark,
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildServiceCard(
          context,
          'Heart Rate Service (Standard)',
          'Service standard BLE pour les données biométriques',
          [
            'Heart Rate Measurement : Fréquence cardiaque et SpO₂',
            'Body Sensor Location : Emplacement du capteur',
            'Heart Rate Control Point : Contrôle du service',
          ],
          BleConstants.serviceHeartRateUuid,
          AppTheme.errorColor,
          isDark,
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    List<String> characteristics,
    String uuid,
    Color color,
    bool isDark,
  ) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.settings_ethernet_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          ...characteristics.map((char) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_right_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        char,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppTheme.spacingS),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uuid,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, bool isDark) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingXL,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    Icons.data_object_rounded,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Données Communiquées',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildDataCard(
              context,
              'Données Biométriques',
              Icons.favorite_rounded,
              AppTheme.errorColor,
              [
                _buildDataItem('Fréquence cardiaque', '30-200 bpm', 'uint16'),
                _buildDataItem('SpO₂ (Saturation)', '0-100%', 'uint16'),
                _buildDataItem('Confiance', '0-100%', 'uint8'),
                _buildDataItem('Status', '0-3', 'uint8'),
              ],
              isDark,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildDataCard(
              context,
              'Données de Mouvement',
              Icons.speed_rounded,
              AppTheme.primaryColor,
              [
                _buildDataItem('Pitch (angle)', '0-360°', 'uint16'),
                _buildDataItem('Roll (angle)', '0-360°', 'uint16'),
                _buildDataItem('Gyro X', '±250 dps', 'int16'),
                _buildDataItem('Gyro Y', '±250 dps', 'int16'),
                _buildDataItem('Gyro Z', '±250 dps', 'int16'),
              ],
              isDark,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildDataCard(
              context,
              'Données Système',
              Icons.thermostat_rounded,
              AppTheme.warningColor,
              [
                _buildDataItem('Température', '-40 à +85°C', 'int16'),
              ],
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
    bool isDark,
  ) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDataItem(String name, String range, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsSection(BuildContext context, bool isDark) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingXL,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Capteurs Intégrés',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildSensorCard(
              context,
              'MAX32664',
              'Biometric Sensor Hub',
              'Hub biométrique avec algorithmes embarqués',
              [
                'Contrôle le capteur MAX30101',
                'Algorithmes de traitement embarqués',
                'Mode 1 : Fréquence cardiaque uniquement',
                'Mode 2 : Fréquence cardiaque + SpO₂',
                'Communication I2C (0x55)',
              ],
              Icons.favorite_rounded,
              AppTheme.errorColor,
              isDark,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildSensorCard(
              context,
              'MAX30101',
              'Pulse Oximeter & Heart-Rate Sensor',
              'Capteur optique pour la mesure biométrique',
              [
                'LEDs rouge et infrarouge',
                'Photodiodes pour la détection',
                'Mesure de la fréquence cardiaque',
                'Mesure de la saturation en oxygène (SpO₂)',
                'Contrôlé par MAX32664',
              ],
              Icons.air_rounded,
              AppTheme.errorColor,
              isDark,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildSensorCard(
              context,
              'LSM6DSOX',
              'Accelerometer & Gyroscope',
              'Capteur de mouvement 6 axes',
              [
                'Accéléromètre 3 axes (±2g)',
                'Gyroscope 3 axes (±250 dps)',
                'Fréquence d\'échantillonnage : 104 Hz',
                'Calcul d\'angles (Pitch/Roll)',
                'Communication I2C (0x6A)',
              ],
              Icons.speed_rounded,
              AppTheme.primaryColor,
              isDark,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildSensorCard(
              context,
              'STM32WB55',
              'Température interne',
              'Capteur de température intégré',
              [
                'Température du microcontrôleur',
                'Plage : -40°C à +85°C',
                'Précision : ±1°C',
                'Mesure continue',
              ],
              Icons.thermostat_rounded,
              AppTheme.warningColor,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    String name,
    String model,
    String description,
    List<String> features,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                    ),
                    Text(
                      model,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildArchitectureSection(BuildContext context, bool isDark) {
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingXL,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    Icons.architecture_rounded,
                    color: AppTheme.secondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Architecture du Système',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _buildArchitectureStep(
                    context,
                    '1',
                    'Acquisition des Données',
                    'Les capteurs acquièrent les données à 104 Hz (LSM6DSOX) et selon les algorithmes embarqués (MAX32664)',
                    Icons.sensors_rounded,
                    AppTheme.primaryColor,
                    isDark,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildArchitectureStep(
                    context,
                    '2',
                    'Traitement et Formatage',
                    'Le STM32WB55 traite les données, calcule les angles, et formate les données pour la transmission BLE',
                    Icons.memory_rounded,
                    AppTheme.accentColor,
                    isDark,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildArchitectureStep(
                    context,
                    '3',
                    'Transmission BLE',
                    'Les données sont transmises via Bluetooth Low Energy à 1 Hz vers l\'application mobile',
                    Icons.bluetooth_connected_rounded,
                    AppTheme.successColor,
                    isDark,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildArchitectureStep(
                    context,
                    '4',
                    'Affichage et Analyse',
                    'L\'application mobile reçoit, décode et affiche les données en temps réel avec graphiques',
                    Icons.phone_android_rounded,
                    AppTheme.warningColor,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureStep(
    BuildContext context,
    String step,
    String title,
    String description,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

