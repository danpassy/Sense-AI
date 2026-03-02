import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/ble_constants.dart';
import '../../../../shared/widgets/animated_fade_in.dart';
import '../../../acquisition/presentation/pages/acquisition_list_page.dart';
import '../../services/ble_service.dart';
import '../models/data_point.dart';
import 'ble_scan_page.dart';

/// Page affichant les données reçues de l'appareil BLE connecté
class BleConnectedPage extends StatefulWidget {
  final BluetoothDevice device;

  const BleConnectedPage({super.key, required this.device});

  @override
  State<BleConnectedPage> createState() => _BleConnectedPageState();
}

class _BleConnectedPageState extends State<BleConnectedPage> with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  bool _isConnected = false;
  List<BleDataReceived> _receivedData = [];
  bool _isConnecting = true;
  bool? _ledState;
  bool _isControllingLed = false;
  bool _isResettingEnergy = false;
  double? _temperature;
  DateTime? _lastTemperatureUpdate;

  // Données biométriques (Heart Rate Service)
  int? _heartRate;  // bpm
  int? _spo2;       // % (reçu comme "Energy Expended")
  int? _confidence;  // % (optionnel, si disponible)
  DateTime? _lastBiometricUpdate;

  // Données LSM6DSOX (Gyroscope et Accéléromètre en angles)
  double? _gyroX;   // dps
  double? _gyroY;   // dps
  double? _gyroZ;   // dps
  double? _pitch;   // degrés (angle d'inclinaison)
  double? _roll;    // degrés (angle d'inclinaison)
  DateTime? _lastMotionUpdate;

  // Contrôleur d'onglets
  late TabController _tabController;

  // Historique des données pour les graphiques (limité à 100 points)
  static const int _maxDataPoints = 100;
  List<DataPoint> _temperatureHistory = [];
  List<DataPoint> _heartRateHistory = [];
  List<DataPoint> _spo2History = [];
  List<DataPoint> _pitchHistory = [];
  List<DataPoint> _rollHistory = [];
  List<DataPoint> _gyroXHistory = [];
  List<DataPoint> _gyroYHistory = [];
  List<DataPoint> _gyroZHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _connectToDevice();
    _listenToData();
  }

  /// Ajoute un point de données à l'historique (limité à _maxDataPoints)
  void _addToHistory(List<DataPoint> history, double value) {
    final now = DateTime.now();
    history.add(DataPoint(timestamp: now, value: value));
    if (history.length > _maxDataPoints) {
      history.removeAt(0);
    }
  }

  Future<void> _connectToDevice() async {
    try {
      setState(() {
        _isConnecting = true;
      });
      
      await _bleService.connectToDevice(widget.device);
      
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _listenToData() {
    _bleService.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isConnected = (state == BluetoothConnectionState.connected);
        });
        
        if (state == BluetoothConnectionState.disconnected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Déconnecté de l\'appareil'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          // Remplacer la page actuelle par la page de scan (garde la page d'accueil dans la pile)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BleScanPage(),
            ),
          );
        }
      }
    });

    _bleService.dataReceivedStream.listen((data) {
      if (mounted) {
        setState(() {
          _receivedData.insert(0, data); // Ajouter au début de la liste
          // Limiter à 100 entrées pour éviter les problèmes de mémoire
          if (_receivedData.length > 100) {
            _receivedData = _receivedData.take(100).toList();
          }
          
          // Debug: Afficher toutes les données reçues
          debugPrint('📦 Données reçues - Service: ${data.serviceUuid}, Char: ${data.characteristicUuid}, Taille: ${data.data.length}, Données: ${data.data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          
          // Vérifier si c'est une notification de température (SWITCH_C)
          final charUuidLower = data.characteristicUuid.toLowerCase();
          final switchCharUuidLower = BleConstants.switchCharUuid.toLowerCase();
          final heartRateCharUuidLower = BleConstants.heartRateMeasCharUuid.toLowerCase();
          
          debugPrint('🔍 Comparaison UUID - Reçu: $charUuidLower');
          
          if (charUuidLower == switchCharUuidLower) {
            debugPrint('✅ Caractéristique SWITCH_C détectée! Taille des données: ${data.data.length}');
            
            if (data.data.length >= 2) {
              // La température est envoyée comme int16 (little-endian) * 100
              final int16Value = (data.data[0] | (data.data[1] << 8));
              // Gérer le signe pour int16
              final int16Signed = int16Value > 32767 ? int16Value - 65536 : int16Value;
              final tempValue = int16Signed / 100.0;
              
              debugPrint('🌡️ Température décodée - Raw: $int16Value, Signed: $int16Signed, Temp: $tempValue°C');
              
              _temperature = tempValue;
              _lastTemperatureUpdate = DateTime.now();
              
              // Ajouter à l'historique pour les graphiques
              _addToHistory(_temperatureHistory, _temperature!);
              
              debugPrint('✅ Température mise à jour: $_temperature°C');
            } else {
              debugPrint('⚠️ Données trop courtes pour être une température (${data.data.length} < 2)');
            }
          }
          
          // Vérifier si c'est une notification LONG_C (données LSM6DSOX)
          final longCharUuidLower = BleConstants.longCharUuid.toLowerCase();
          if (charUuidLower == longCharUuidLower) {
            debugPrint('📊 Caractéristique LONG_C détectée! Taille des données: ${data.data.length}');
            
            // Format LSM6DSOX: 12 bytes (6 bytes gyro + 6 bytes accel angles, little-endian)
            // Bytes 0-1: Gyro X (int16 signed, little-endian) * 100
            // Bytes 2-3: Gyro Y (int16 signed, little-endian) * 100
            // Bytes 4-5: Gyro Z (int16 signed, little-endian) * 100
            // Bytes 6-7: Accel Pitch 0-360° (uint16 unsigned, little-endian) * 100 (range: 0-36000)
            // Bytes 8-9: Accel Roll 0-360° (uint16 unsigned, little-endian) * 100 (range: 0-36000)
            // Bytes 10-11: Reserved (0)
            
            if (data.data.length >= 12) {
              // Décoder gyroscope d'abord (int16 signed little-endian, divisé par 100 pour obtenir dps)
              final gyroXRaw = (data.data[0] | (data.data[1] << 8));
              final gyroXRawSigned = gyroXRaw > 32767 ? gyroXRaw - 65536 : gyroXRaw;
              _gyroX = gyroXRawSigned / 100.0;
              
              final gyroYRaw = (data.data[2] | (data.data[3] << 8));
              final gyroYRawSigned = gyroYRaw > 32767 ? gyroYRaw - 65536 : gyroYRaw;
              _gyroY = gyroYRawSigned / 100.0;
              
              final gyroZRaw = (data.data[4] | (data.data[5] << 8));
              final gyroZRawSigned = gyroZRaw > 32767 ? gyroZRaw - 65536 : gyroZRaw;
              _gyroZ = gyroZRawSigned / 100.0;
              
              // Décoder angles accéléromètre 0-360° (uint16 unsigned little-endian, divisé par 100 pour obtenir degrés)
              // Format: uint16 little-endian, valeur × 100 (ex: 12345 = 123.45°)
              // Pitch et Roll sont dans la plage 0-360° (pas de valeurs négatives)
              
              // Décoder Pitch (bytes 6-7): uint16 little-endian
              final pitchRaw = data.data[6] | (data.data[7] << 8);
              _pitch = (pitchRaw / 100.0).clamp(0.0, 360.0);  // 0-36000 / 100 = 0-360°
              
              // Décoder Roll (bytes 8-9): uint16 little-endian
              final rollRaw = data.data[8] | (data.data[9] << 8);
              _roll = (rollRaw / 100.0).clamp(0.0, 360.0);  // 0-36000 / 100 = 0-360°
              
              _lastMotionUpdate = DateTime.now();
              
              // Ajouter à l'historique pour les graphiques
              if (_pitch != null) _addToHistory(_pitchHistory, _pitch!);
              if (_roll != null) _addToHistory(_rollHistory, _roll!);
              if (_gyroX != null) _addToHistory(_gyroXHistory, _gyroX!);
              if (_gyroY != null) _addToHistory(_gyroYHistory, _gyroY!);
              if (_gyroZ != null) _addToHistory(_gyroZHistory, _gyroZ!);
              
              // Debug: Log decoded values with raw bytes for verification
              debugPrint('📊 LSM6DSOX décodé - Gyro: X=${_gyroX?.toStringAsFixed(2)}dps Y=${_gyroY?.toStringAsFixed(2)}dps Z=${_gyroZ?.toStringAsFixed(2)}dps');
              debugPrint('📊 LSM6DSOX décodé - Accel: Pitch=${_pitch?.toStringAsFixed(2)}° (raw=$pitchRaw) Roll=${_roll?.toStringAsFixed(2)}° (raw=$rollRaw)');
              debugPrint('📊 Bytes Pitch: [${data.data[6].toRadixString(16).padLeft(2, '0')} ${data.data[7].toRadixString(16).padLeft(2, '0')}] Roll: [${data.data[8].toRadixString(16).padLeft(2, '0')} ${data.data[9].toRadixString(16).padLeft(2, '0')}]');
            } else {
              debugPrint('⚠️ Données LSM6DSOX trop courtes (${data.data.length} < 12)');
            }
          }
          
          // Vérifier si c'est une notification Heart Rate (données biométriques)
          // Comparer avec format court (2a37) et format long (00002a37-0000-1000-8000-00805f9b34fb)
          // Normaliser l'UUID en enlevant les tirets pour la comparaison
          final normalizedCharUuid = charUuidLower.replaceAll('-', '');
          final normalizedHeartRateUuid = heartRateCharUuidLower.replaceAll('-', '');
          final isHeartRateChar = normalizedCharUuid == normalizedHeartRateUuid || 
                                  normalizedCharUuid.contains('2a37') ||
                                  charUuidLower == '2a37' ||
                                  charUuidLower.endsWith('2a37') ||
                                  charUuidLower.startsWith('2a37');
          
          // Debug pour voir ce qui est comparé
          if (charUuidLower.contains('2a37') || normalizedCharUuid.contains('2a37')) {
            debugPrint('🔍 UUID Heart Rate détecté: $charUuidLower (normalisé: $normalizedCharUuid)');
          }
          
          if (isHeartRateChar) {
            debugPrint('❤️❤️❤️ CARACTÉRISTIQUE HEART RATE MESUREMENT DÉTECTÉE! Taille: ${data.data.length}');
            debugPrint('📦 Données brutes: ${data.data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
            
            if (data.data.length >= 5) {
              // Format Heart Rate Service (standard Bluetooth):
              // Byte 0: Flags (0x09 = 16-bit HR + Energy Expended present)
              // Byte 1-2: Heart Rate (16-bit, little-endian) en bpm
              // Byte 3-4: Energy Expended (16-bit, little-endian) - utilisé pour SpO2
              
              final flags = data.data[0];
              final has16BitHR = (flags & 0x01) != 0;  // Bit 0: HR format (0=8-bit, 1=16-bit)
              final hasEnergy = (flags & 0x08) != 0;    // Bit 3: Energy Expended present
              
              debugPrint('📊 Flags: 0x${flags.toRadixString(16).padLeft(2, '0')}, 16-bit HR: $has16BitHR, Energy: $hasEnergy');
              
              if (has16BitHR && data.data.length >= 5) {
                // Heart Rate 16-bit (little-endian)
                final hrValue = data.data[1] | (data.data[2] << 8);
                _heartRate = hrValue;
                
                debugPrint('❤️ Heart Rate décodé: $_heartRate bpm');
                
                // Energy Expended (utilisé pour SpO2 dans notre cas)
                if (hasEnergy && data.data.length >= 5) {
                  final spo2Value = data.data[3] | (data.data[4] << 8);
                  
                  // Vérifier que SpO2 est dans une plage valide (0-100%)
                  // Si > 100%, c'est probablement un compteur de fallback = capteur non connecté
                  if (spo2Value <= 100) {
                    _spo2 = spo2Value;
                    debugPrint('🫁 SpO2 décodé: $_spo2%');
                  } else if (spo2Value == 0) {
                    // 0% = capteur non connecté ou pas de doigt détecté
                    _spo2 = null;
                    debugPrint('⚠️ SpO2 invalide (0%): Capteur non connecté ou pas de doigt détecté');
                  } else {
                    // > 100% = compteur de fallback = capteur non connecté
                    _spo2 = null;
                    debugPrint('⚠️ SpO2 invalide ($spo2Value%): Capteur MAX32664 probablement non connecté');
                  }
                }
                
                _lastBiometricUpdate = DateTime.now();
                
                // Ajouter à l'historique pour les graphiques
                if (_heartRate != null) _addToHistory(_heartRateHistory, _heartRate!.toDouble());
                if (_spo2 != null) _addToHistory(_spo2History, _spo2!.toDouble());
                
                debugPrint('✅✅✅ DONNÉES BIOMÉTRIQUES MISES À JOUR: HR=$_heartRate bpm, SpO2=$_spo2%');
              } else if (!has16BitHR && data.data.length >= 2) {
                // Heart Rate 8-bit
                _heartRate = data.data[1];
                if (hasEnergy && data.data.length >= 4) {
                  final spo2Value = data.data[2] | (data.data[3] << 8);
                  _spo2 = spo2Value;
                }
                _lastBiometricUpdate = DateTime.now();
                debugPrint('✅ Données biométriques mises à jour (8-bit): HR=$_heartRate bpm, SpO2=$_spo2%');
              } else {
                debugPrint('⚠️ Format Heart Rate non supporté ou données incomplètes');
              }
            } else {
              debugPrint('⚠️ Données Heart Rate trop courtes (${data.data.length} < 5)');
            }
          }
        });
      }
    });
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bleService.disconnect();
      if (mounted) {
        // Remplacer la page actuelle par la page de scan (garde la page d'accueil dans la pile)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BleScanPage(),
          ),
        );
      }
    }
  }

  String _formatBytes(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase();
  }

  String _formatUuid(String uuid) {
    if (uuid.length > 8) {
      return uuid.substring(0, 8).toUpperCase();
    }
    return uuid.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _disconnect();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Appareil connecté',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _disconnect,
            tooltip: 'Déconnecter',
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_rounded),
                text: 'Vue d\'ensemble',
              ),
              Tab(
                icon: Icon(Icons.favorite_rounded),
                text: 'Biométrie',
              ),
              Tab(
                icon: Icon(Icons.sensors_rounded),
                text: 'Mouvement',
              ),
              Tab(
                icon: Icon(Icons.play_circle_outline_rounded),
                text: 'Acquisition',
              ),
            ],
          ),
        ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connexion en cours...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Onglet 1: Vue d'ensemble
                SafeArea(
                  key: const ValueKey('overview'),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Statut de connexion
                      SliverToBoxAdapter(
                        child: _buildConnectionStatus(context),
                      ),
                      
                      // Informations du périphérique
                      SliverToBoxAdapter(
                        child: _buildDeviceInfo(context),
                      ),
                      
                      // Contrôles
                      SliverToBoxAdapter(
                        child: _buildControlsSection(context),
                      ),
                      
                      // Affichage de la température
                      SliverToBoxAdapter(
                        child: _buildTemperatureSection(context),
                      ),
                      
                      // Affichage des données biométriques (HR + SpO2)
                      SliverToBoxAdapter(
                        child: _buildBiometricSection(context),
                      ),
                      
                      // Affichage des données LSM6DSOX (Accéléromètre + Gyroscope)
                      SliverToBoxAdapter(
                        child: _buildMotionSection(context),
                      ),
                      
                      // Services découverts
                      SliverToBoxAdapter(
                        child: _buildServicesSection(context),
                      ),
                      
                      // Données reçues
                      SliverToBoxAdapter(
                        child: _buildReceivedDataSection(context),
                      ),
                      
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  ),
                ),
                // Onglet 2: Graphiques biométriques
                _buildBiometricChartsTab(context),
                // Onglet 3: Graphiques mouvement
                _buildMotionChartsTab(context),
                // Onglet 4: Acquisition
                const AcquisitionListPage(),
              ],
            ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _isConnected ? AppTheme.successColor : AppTheme.errorColor;
    final statusText = _isConnected ? 'Connecté' : 'Déconnecté';
    final statusIcon = _isConnected ? Icons.check_circle_rounded : Icons.error_rounded;
    
    return AnimatedFadeIn(
      delay: Duration.zero,
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingL),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isConnected
                        ? 'Réception des données en cours...'
                        : 'En attente de connexion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
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

  Widget _buildDeviceInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 100),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Informations du périphérique',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(
              context,
              'Nom',
              widget.device.platformName.isNotEmpty
                  ? widget.device.platformName
                  : 'N/A',
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow(
              context,
              'Adresse',
              widget.device.remoteId.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final services = _bleService.discoveredServices;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_rounded,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Services découverts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (services.isEmpty)
              Text(
                'Aucun service découvert',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
              )
            else
              ...services.map((service) => _buildServiceItem(context, service)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, BluetoothService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service: ${_formatUuid(service.uuid.toString())}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '${service.characteristics.length} caractéristique(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedDataSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.data_object_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          'Données reçues',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_receivedData.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _receivedData.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (_receivedData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'En attente de données...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._receivedData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return _buildDataItem(context, data, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(BuildContext context, BleDataReceived data, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    
    return AnimatedFadeIn(
      delay: Duration(milliseconds: 400 + (index * 20)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}:${data.timestamp.second.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Service: ${_formatUuid(data.serviceUuid)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 11,
                  ),
            ),
            Text(
              'Caractéristique: ${_formatUuid(data.characteristicUuid)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackgroundColor : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: SelectableText(
                _formatBytes(data.data),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Taille: ${data.data.length} octet(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.control_camera_rounded,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Contrôles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildLedControl(context),
            const SizedBox(height: AppTheme.spacingM),
            _buildHeartRateControl(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLedControl(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Contrôle LED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isControllingLed || !_isConnected
                          ? null
                          : () async {
                              setState(() {
                                _isControllingLed = true;
                              });
                              setLocalState(() {});
                              try {
                                await _bleService.controlLed(true);
                                setState(() {
                                  _ledState = true;
                                  _isControllingLed = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('LED allumée'),
                                      backgroundColor: AppTheme.successColor,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  _isControllingLed = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: _isControllingLed
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.power_settings_new_rounded, size: 18),
                      label: const Text('Allumer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isControllingLed || !_isConnected
                          ? null
                          : () async {
                              setState(() {
                                _isControllingLed = true;
                              });
                              setLocalState(() {});
                              try {
                                await _bleService.controlLed(false);
                                setState(() {
                                  _ledState = false;
                                  _isControllingLed = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('LED éteinte'),
                                      backgroundColor: AppTheme.successColor,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  _isControllingLed = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: _isControllingLed
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.power_off_rounded, size: 18),
                      label: const Text('Éteindre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                      ),
                    ),
                  ),
                ],
              ),
              if (_ledState != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingS),
                  child: Row(
                    children: [
                      Icon(
                        _ledState! ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: _ledState! ? AppTheme.successColor : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        _ledState! ? 'LED allumée' : 'LED éteinte',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeartRateControl(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Heart Rate Control',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ElevatedButton.icon(
                onPressed: _isResettingEnergy || !_isConnected
                    ? null
                    : () async {
                        setState(() {
                          _isResettingEnergy = true;
                        });
                        setLocalState(() {});
                        try {
                          await _bleService.resetEnergyExpended();
                          setState(() {
                            _isResettingEnergy = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Énergie dépensée réinitialisée'),
                                backgroundColor: AppTheme.successColor,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            _isResettingEnergy = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                icon: _isResettingEnergy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réinitialiser l\'énergie dépensée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemperatureSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 175),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Température interne',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (_temperature != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningColor.withOpacity(0.1),
                      AppTheme.errorColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_temperature!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningColor,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      '°C',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkBackgroundColor : Colors.white).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'En attente de données...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            if (_lastTemperatureUpdate != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dernière mise à jour: ${_lastTemperatureUpdate!.hour.toString().padLeft(2, '0')}:${_lastTemperatureUpdate!.minute.toString().padLeft(2, '0')}:${_lastTemperatureUpdate!.second.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            fontSize: 11,
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

  Widget _buildBiometricSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Données biométriques',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Heart Rate
            if (_heartRate != null)
              _buildBiometricCard(
                context,
                icon: Icons.favorite_rounded,
                iconColor: AppTheme.errorColor,
                label: 'Fréquence cardiaque',
                value: '$_heartRate',
                unit: 'bpm',
                gradientColors: [
                  AppTheme.errorColor.withOpacity(0.1),
                  AppTheme.errorColor.withOpacity(0.05),
                ],
              )
            else
              _buildBiometricPlaceholder(
                context,
                icon: Icons.favorite_outline_rounded,
                label: 'Fréquence cardiaque',
              ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // SpO2
            if (_spo2 != null)
              _buildBiometricCard(
                context,
                icon: Icons.air_rounded,
                iconColor: AppTheme.primaryColor,
                label: 'Saturation en oxygène',
                value: '$_spo2',
                unit: '%',
                gradientColors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              )
            else
              _buildBiometricPlaceholder(
                context,
                icon: Icons.air_outlined,
                label: 'Saturation en oxygène',
              ),
            
            if (_lastBiometricUpdate != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dernière mise à jour: ${_lastBiometricUpdate!.hour.toString().padLeft(2, '0')}:${_lastBiometricUpdate!.minute.toString().padLeft(2, '0')}:${_lastBiometricUpdate!.second.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            fontSize: 11,
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

  Widget _buildMotionSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Capteur de mouvement (LSM6DSOX)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Accéléromètre (angles d'inclinaison) - affiché en premier
            Text(
              'Accéléromètre (angles)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            
            if (_pitch != null && _roll != null)
              Column(
                children: [
                  _buildMotionValueCard(
                    context,
                    icon: Icons.swap_vert_rounded,
                    label: 'Pitch',
                    value: _pitch!,
                    unit: '°',
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  _buildMotionValueCard(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Roll',
                    value: _roll!,
                    unit: '°',
                    color: AppTheme.successColor,
                  ),
                ],
              )
            else
              _buildMotionPlaceholder(
                context,
                label: 'Accéléromètre',
              ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Gyroscope - affiché en second
            Text(
              'Gyroscope',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            
            if (_gyroX != null && _gyroY != null && _gyroZ != null)
              Column(
                children: [
                  _buildMotionValueCard(
                    context,
                    icon: Icons.rotate_right_rounded,
                    label: 'X',
                    value: _gyroX!,
                    unit: 'dps',
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  _buildMotionValueCard(
                    context,
                    icon: Icons.rotate_right_rounded,
                    label: 'Y',
                    value: _gyroY!,
                    unit: 'dps',
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  _buildMotionValueCard(
                    context,
                    icon: Icons.rotate_right_rounded,
                    label: 'Z',
                    value: _gyroZ!,
                    unit: 'dps',
                    color: AppTheme.primaryColor,
                  ),
                ],
              )
            else
              _buildMotionPlaceholder(
                context,
                label: 'Gyroscope',
              ),
            
            if (_lastMotionUpdate != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dernière mise à jour: ${_lastMotionUpdate!.hour.toString().padLeft(2, '0')}:${_lastMotionUpdate!.minute.toString().padLeft(2, '0')}:${_lastMotionUpdate!.second.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            fontSize: 11,
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

  Widget _buildMotionValueCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required String unit,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          Text(
            '${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotionPlaceholder(
    BuildContext context, {
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackgroundColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sensors_off_rounded,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            '$label: En attente de données...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkBackgroundColor : Colors.white).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              '$label: En attente de données...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Ne pas déconnecter automatiquement, laisser l'utilisateur le faire
    super.dispose();
  }

  /// Onglet des graphiques biométriques
  Widget _buildBiometricChartsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildChartCard(
                  context,
                  'Température',
                  '°C',
                  _temperatureHistory,
                  AppTheme.warningColor,
                  Icons.thermostat_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'Fréquence Cardiaque',
                  'bpm',
                  _heartRateHistory,
                  AppTheme.errorColor,
                  Icons.favorite_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'SpO₂',
                  '%',
                  _spo2History,
                  AppTheme.primaryColor,
                  Icons.air_rounded,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet des graphiques de mouvement
  Widget _buildMotionChartsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildChartCard(
                  context,
                  'Pitch (Inclinaison)',
                  '°',
                  _pitchHistory,
                  AppTheme.accentColor,
                  Icons.trending_up_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'Roll (Roulis)',
                  '°',
                  _rollHistory,
                  AppTheme.secondaryColor,
                  Icons.trending_flat_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'Gyroscope X',
                  'dps',
                  _gyroXHistory,
                  AppTheme.successColor,
                  Icons.swap_horiz_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'Gyroscope Y',
                  'dps',
                  _gyroYHistory,
                  AppTheme.primaryColor,
                  Icons.swap_vert_rounded,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildChartCard(
                  context,
                  'Gyroscope Z',
                  'dps',
                  _gyroZHistory,
                  AppTheme.warningColor,
                  Icons.rotate_right_rounded,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de graphique avec titre et unité
  Widget _buildChartCard(
    BuildContext context,
    String title,
    String unit,
    List<DataPoint> data,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                    ),
                    if (data.isNotEmpty)
                      Text(
                        '${data.last.value.toStringAsFixed(1)} $unit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'En attente de données...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                    ),
                  )
                : _buildLineChart(data, color, isDark),
          ),
        ],
      ),
    );
  }

  /// Construit un graphique linéaire avec fl_chart
  Widget _buildLineChart(List<DataPoint> data, Color color, bool isDark) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;
      return FlSpot(index, point.value);
    }).toList();

    final minY = data.map((p) => p.value).reduce((a, b) => a < b ? a : b) - 5;
    final maxY = data.map((p) => p.value).reduce((a, b) => a > b ? a : b) + 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 10 ? (data.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final point = data[value.toInt()];
                  final time = '${point.timestamp.hour.toString().padLeft(2, '0')}:${point.timestamp.minute.toString().padLeft(2, '0')}:${point.timestamp.second.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: (maxY - minY) / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

