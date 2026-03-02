import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/animated_fade_in.dart';
import '../../../../shared/widgets/scan_button.dart';
import '../../../../shared/widgets/feature_card.dart';
import '../../../ble/presentation/pages/ble_connected_page.dart';
import '../../../ble/presentation/pages/ble_scan_page.dart';
import '../../../ble/services/ble_service.dart';
import '../../../info/presentation/pages/data_ai_info_page.dart';
import '../../../info/presentation/pages/acquisition_info_page.dart';
import '../../../info/presentation/pages/cyber_security_info_page.dart';

/// Page d'accueil principale - Style Fitness Moderne
class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  
  const HomePage({super.key, required this.themeProvider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header moderne et minimaliste
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            
            // Bouton de scan
            SliverToBoxAdapter(
              child: _buildScanButton(context),
            ),
            
            // Fonctionnalités de l'application
            SliverToBoxAdapter(
              child: _buildAppFeatures(context),
            ),
            
            // Capteurs généraux
            SliverToBoxAdapter(
              child: _buildSensorsSection(context),
            ),
            
            // Fonctionnalités générales
            SliverToBoxAdapter(
              child: _buildGeneralFeatures(context),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                            letterSpacing: -1,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Bouton de bascule jour/nuit
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppTheme.darkSurfaceColor 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? Colors.amber : AppTheme.textPrimary,
                        ),
                        onPressed: () {
                          widget.themeProvider.toggleTheme();
                        },
                        tooltip: isDark ? 'Mode jour' : 'Mode nuit',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aujourd\'hui',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _ble,
      builder: (context, _) {
        final device = _ble.connectedDevice;
        final isConnected = _ble.isConnected && device != null;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

        if (!isConnected) {
          return Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingL,
              bottom: AppTheme.spacingXL,
            ),
            child: ScanButton(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BleScanPage(),
                  ),
                );
              },
            ),
          );
        }

        return AnimatedFadeIn(
          delay: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingXL,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.25),
                  width: 1.5,
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
                          color: AppTheme.successColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.bluetooth_connected_rounded,
                          color: AppTheme.successColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connecté',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BleConnectedPage(device: device),
                              ),
                            );
                          },
                          icon: const Icon(Icons.dashboard_rounded, size: 18),
                          label: const Text('Ouvrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _ble.disconnect();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Déconnecté'),
                                backgroundColor: AppTheme.warningColor,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('Déconnecter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Ouvre l’appareil pour accéder à Acquisition et aux fichiers STM32.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fonctionnalités de l\'application',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          FeatureCard(
            section: AppStrings.sectionA,
            title: AppStrings.sectionATitle,
            description: AppStrings.sectionADescription,
            icon: Icons.bluetooth_connected_rounded,
            color: AppTheme.primaryColor,
            index: 0,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AcquisitionInfoPage(),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          FeatureCard(
            section: AppStrings.sectionB,
            title: AppStrings.sectionBTitle,
            description: AppStrings.sectionBDescription,
            icon: Icons.psychology_rounded,
            color: AppTheme.accentColor,
            index: 1,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataAiInfoPage(),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          FeatureCard(
            section: AppStrings.sectionC,
            title: AppStrings.sectionCTitle,
            description: AppStrings.sectionCDescription,
            icon: Icons.security_rounded,
            color: AppTheme.warningColor,
            index: 2,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CyberSecurityInfoPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fonctionnalités générales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Visualisation des différents capteurs
          _buildGeneralFeatureItem(
            context,
            'Visualisation des capteurs',
            Icons.sensors_rounded,
            AppTheme.primaryColor,
            'Graphiques et visualisation en temps réel des données de tous les capteurs',
            isImplemented: true,
            index: 0,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Export des données
          _buildGeneralFeatureItem(
            context,
            'Export des données',
            Icons.file_download_rounded,
            AppTheme.successColor,
            'Téléchargement des fichiers (local + STM32) au format CSV',
            isImplemented: true,
            index: 1,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Acquisition (Start/Stop côté STM32)
          _buildGeneralFeatureItem(
            context,
            'Acquisition (Start/Stop)',
            Icons.play_circle_rounded,
            AppTheme.accentColor,
            'Démarrer/arrêter l’enregistrement sur le STM32 (ACQ_<ACT>_XXX.CSV)',
            isImplemented: true,
            index: 2,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Fichiers STM32
          _buildGeneralFeatureItem(
            context,
            'Fichiers STM32',
            Icons.folder_copy_rounded,
            AppTheme.warningColor,
            'Lister les fichiers SD et les télécharger sur le mobile',
            isImplemented: true,
            index: 3,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Traitement via IA
          _buildGeneralFeatureItem(
            context,
            'Traitement via IA',
            Icons.psychology_rounded,
            AppTheme.accentColor,
            'Analyse intelligente des données avec extraction de caractéristiques avancées',
            isImplemented: false,
            index: 4,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Cryptage des données
          _buildGeneralFeatureItem(
            context,
            'Cryptage des données',
            Icons.lock_rounded,
            AppTheme.warningColor,
            'Sécurisation et chiffrement des données sensibles',
            isImplemented: false,
            index: 5,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Calibration des capteurs
          _buildGeneralFeatureItem(
            context,
            'Calibration des capteurs',
            Icons.tune_rounded,
            AppTheme.secondaryColor,
            'Calibration et ajustement des capteurs pour une précision optimale',
            isImplemented: false,
            index: 6,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Historique des sessions
          _buildGeneralFeatureItem(
            context,
            'Historique des sessions',
            Icons.history_rounded,
            AppTheme.primaryColor,
            'Consultation de l\'historique et des sessions précédentes',
            isImplemented: false,
            index: 7,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Synchronisation
          _buildGeneralFeatureItem(
            context,
            'Synchronisation',
            Icons.cloud_sync_rounded,
            AppTheme.successColor,
            'Sauvegarde et synchronisation des données',
            isImplemented: false,
            index: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralFeatureItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description, {
    required bool isImplemented,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textLight = isDark ? AppTheme.darkTextLight : AppTheme.textLight;
    
    return AnimatedFadeIn(
      delay: Duration(milliseconds: 600 + (index * 50)),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isImplemented ? color.withOpacity(0.3) : textLight.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isImplemented
                              ? AppTheme.successColor.withOpacity(0.1)
                              : textLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isImplemented ? 'Géré' : 'Bientôt',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isImplemented ? AppTheme.successColor : textLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildSensorsSection(BuildContext context) {
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capteurs généraux',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildSensorItem(
              context,
              AppStrings.sensorAccelerometer,
              Icons.speed_rounded,
              AppTheme.primaryColor,
              'Mesure des accélérations 3 axes',
              true,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSensorItem(
              context,
              AppStrings.sensorGyroscope,
              Icons.explore_rounded,
              AppTheme.accentColor,
              'Vitesse angulaire 3 axes',
              true,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSensorItem(
              context,
              AppStrings.sensorTemperature,
              Icons.thermostat_rounded,
              AppTheme.warningColor,
              'Température interne STM32WB55',
              true,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSensorItem(
              context,
              AppStrings.sensorHeartRate,
              Icons.favorite_rounded,
              AppTheme.errorColor,
              'Fréquence cardiaque (MAX32664)',
              true,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSensorItem(
              context,
              AppStrings.sensorSpO2,
              Icons.air_rounded,
              AppTheme.successColor,
              'Oxymétrie (SpO₂)',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorItem(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    String description,
    bool isImplemented,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textLight = isDark ? AppTheme.darkTextLight : AppTheme.textLight;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: isImplemented ? color.withOpacity(0.3) : textLight.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isImplemented
                            ? AppTheme.successColor.withOpacity(0.1)
                            : textLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isImplemented ? 'Actif' : 'Bientôt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isImplemented ? AppTheme.successColor : textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}

