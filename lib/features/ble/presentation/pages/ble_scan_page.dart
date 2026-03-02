import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../core/constants/ble_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../shared/widgets/animated_fade_in.dart';
import '../../../../shared/widgets/ble_device_card.dart';
import '../../services/ble_service.dart';
import 'ble_connected_page.dart';

class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final BleService _bleService = BleService();

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  String? _errorMessage;

  // --- Recherche / proximité ---
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  bool _sortByProximity = true; // tri RSSI décroissant
  double _minRssi = -100; // filtre RSSI minimum (plus proche = valeur plus élevée)

  @override
  void initState() {
    super.initState();

    _adapterSub = _bleService.adapterStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _adapterState = s;
        if (s == BluetoothAdapterState.on) {
          _errorMessage = null;
        }
      });
    });

    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v == _query) return;
      setState(() => _query = v);
    });

    _primePermissions();
  }

  Future<void> _primePermissions() async {
    if (!Platform.isAndroid) return; // iOS: ne pas utiliser PermissionHelper pour BLE
    try {
      await PermissionHelper.checkBluetoothPermissions();
    } catch (_) {
      // ignore
    }
  }

  // ---------- Filtering helpers ----------
  String _deviceKey(ScanResult r) => r.device.remoteId.toString();

  List<ScanResult> _dedupKeepBestRssi(List<ScanResult> results) {
    final map = <String, ScanResult>{};
    for (final r in results) {
      final key = _deviceKey(r);
      final existing = map[key];
      if (existing == null) {
        map[key] = r;
      } else {
        if (r.rssi > existing.rssi) map[key] = r; // garder le plus proche
      }
    }
    return map.values.toList();
  }

  bool _matchesQuery(ScanResult r) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final name = r.device.platformName.trim().toLowerCase();
    final id = _deviceKey(r).toLowerCase();
    return name.contains(q) || id.contains(q);
  }

  bool _matchesRssi(ScanResult r) => r.rssi >= _minRssi;

  List<ScanResult> _applyFilters(List<ScanResult> raw) {
    var results = _dedupKeepBestRssi(raw);
    results = results.where(_matchesQuery).where(_matchesRssi).toList();
    if (_sortByProximity) {
      results.sort((a, b) => b.rssi.compareTo(a.rssi));
    }
    return results;
  }

  Map<String, List<ScanResult>> _categorizeDevices(List<ScanResult> results) {
    final known = <ScanResult>[];
    final unknown = <ScanResult>[];

    for (final r in results) {
      final name = r.device.platformName.trim();
      if (name.isNotEmpty &&
          name.toLowerCase() == BleConstants.deviceName.toLowerCase()) {
        known.add(r);
      } else {
        unknown.add(r);
      }
    }
    return {'known': known, 'unknown': unknown};
  }

  // ---------- Actions ----------
  Future<void> _startScan() async {
    setState(() => _errorMessage = null);

    // flutter_blue_plus 1.36.8 states: on, off, unauthorized, unavailable, unknown
    if (_adapterState == BluetoothAdapterState.off) {
      setState(() => _errorMessage = 'Bluetooth désactivé. Activez-le pour scanner.');
      return;
    }

    if (_adapterState == BluetoothAdapterState.unauthorized) {
      if (Platform.isAndroid) {
        final granted = await PermissionHelper.requestBluetoothPermissions();
        if (!granted) {
          setState(() => _errorMessage = 'Permissions Bluetooth requises.');
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      } else {
        setState(() => _errorMessage =
            'Permissions Bluetooth requises. Autorisez Bluetooth dans Réglages > Sens Ia.');
      }
      return;
    }

    if (_adapterState == BluetoothAdapterState.unavailable) {
      setState(() => _errorMessage = 'Bluetooth indisponible sur cet appareil.');
      return;
    }

    if (_adapterState == BluetoothAdapterState.unknown) {
      setState(() => _errorMessage = 'Initialisation Bluetooth… patientez puis réessayez.');
      return;
    }

    if (_adapterState != BluetoothAdapterState.on) {
      setState(() => _errorMessage = 'État Bluetooth inattendu: $_adapterState');
      return;
    }

    // ✅ Android seulement : permissions runtime via PermissionHelper
    if (Platform.isAndroid) {
      final has = await PermissionHelper.checkBluetoothPermissions();
      if (!has) {
        final granted = await PermissionHelper.requestBluetoothPermissions();
        if (!granted) {
          setState(() => _errorMessage = 'Permissions Bluetooth requises.');
          return;
        }
      }
    }

    try {
      await _bleService.startScan();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur scan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur scan: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _stopScan() async {
    try {
      await _bleService.stopScan();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _errorMessage = null);

    try {
      await _bleService.connectToDevice(device);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BleConnectedPage(device: device),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connexion impossible: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion impossible: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // ---------- UI ----------
  Widget _buildTopStatus() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final text = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    String title;
    Color color;
    IconData icon;

    switch (_adapterState) {
      case BluetoothAdapterState.on:
        title = 'Bluetooth prêt';
        color = AppTheme.successColor;
        icon = Icons.bluetooth_connected_rounded;
        break;
      case BluetoothAdapterState.off:
        title = 'Bluetooth désactivé';
        color = AppTheme.warningColor;
        icon = Icons.bluetooth_disabled_rounded;
        break;
      case BluetoothAdapterState.unauthorized:
        title = 'Permission Bluetooth requise';
        color = AppTheme.errorColor;
        icon = Icons.lock_rounded;
        break;
      case BluetoothAdapterState.unavailable:
        title = 'Bluetooth indisponible';
        color = AppTheme.errorColor;
        icon = Icons.block_rounded;
        break;
      case BluetoothAdapterState.unknown:
      default:
        title = 'Initialisation Bluetooth…';
        color = AppTheme.warningColor;
        icon = Icons.hourglass_bottom_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          _buildScanButton(),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final scanning = _bleService.isScanning;

    return ElevatedButton.icon(
      onPressed: scanning ? _stopScan : _startScan,
      icon: Icon(scanning ? Icons.stop_rounded : Icons.search_rounded),
      label: Text(scanning ? 'Stop' : 'Scanner'),
      style: ElevatedButton.styleFrom(
        backgroundColor: scanning ? AppTheme.errorColor : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  // --- Ergonomique : barre compacte + bouton filtres ---
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un appareil…',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => _searchCtrl.clear(),
              tooltip: 'Effacer',
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFiltersSheet,
            tooltip: 'Filtres',
          ),
        ],
      ),
    );
  }

 void _openFiltersSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, sheetSetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final text = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtres Bluetooth',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Trier par proximité (RSSI)',
                          style: TextStyle(color: text, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Switch(
                        value: _sortByProximity,
                        onChanged: (v) {
                          sheetSetState(() => _sortByProximity = v);
                          setState(() => _sortByProximity = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  Text(
                    'Proximité minimale : ${_minRssi.toInt()} dBm',
                    style: TextStyle(color: text.withOpacity(0.85)),
                  ),
                  Slider(
                    value: _minRssi,
                    min: -100,
                    max: -20,
                    divisions: 80,
                    label: '${_minRssi.toInt()} dBm',
                    onChanged: (v) {
                      sheetSetState(() => _minRssi = v);
                      setState(() => _minRssi = v);
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          sheetSetState(() {
                            _sortByProximity = true;
                            _minRssi = -100;
                          });
                          setState(() {
                            _sortByProximity = true;
                            _minRssi = -100;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildSectionHeader(String title, int count, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$title ($count)',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXL),
      child: Center(
        child: Text(
          _bleService.isScanning ? 'Scan en cours…' : 'Aucun appareil détecté. Lancez un scan.',
          style: TextStyle(color: textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Recherche BLE'),
        backgroundColor: bg,
        elevation: 0,
      ),
      body: AnimatedFadeIn(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              _buildTopStatus(),
              const SizedBox(height: AppTheme.spacingM),
              _buildSearchBar(),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingL),

              Expanded(
                child: StreamBuilder<List<ScanResult>>(
                  stream: _bleService.scannedDevicesStream,
                  initialData: const [],
                  builder: (context, snapshot) {
                    final raw = snapshot.data ?? const <ScanResult>[];
                    final filtered = _applyFilters(raw);

                    final categorized = _categorizeDevices(filtered);
                    final known = categorized['known']!;
                    final unknown = categorized['unknown']!;

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (known.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Appareils connus',
                            known.length,
                            AppTheme.successColor,
                            Icons.verified_rounded,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          ...known.asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                              child: BleDeviceCard(
                                scanResult: e.value,
                                index: e.key,
                                isKnown: true,
                                onTap: () => _connectToDevice(e.value.device),
                              ),
                            );
                          }),
                          const SizedBox(height: AppTheme.spacingXL),
                        ],
                        if (unknown.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Autres appareils',
                            unknown.length,
                            AppTheme.primaryColor,
                            Icons.bluetooth_searching_rounded,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          ...unknown.asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                              child: BleDeviceCard(
                                scanResult: e.value,
                                index: e.key + known.length,
                                isKnown: false,
                                onTap: () => _connectToDevice(e.value.device),
                              ),
                            );
                          }),
                        ],
                        if (known.isEmpty && unknown.isEmpty) _buildEmptyState(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _searchCtrl.dispose();
    _bleService.stopScan();
    super.dispose();
  }
}