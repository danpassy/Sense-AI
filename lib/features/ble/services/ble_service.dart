import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/constants/ble_constants.dart';

/// Modèle pour représenter une donnée reçue
class BleDataReceived {
  final String serviceUuid;
  final String characteristicUuid;
  final List<int> data;
  final DateTime timestamp;

  BleDataReceived({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.data,
    required this.timestamp,
  });
}

/// Service BLE pour la communication avec les appareils Bluetooth
class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  BleService._internal() {
    // Toujours fiable (Android/iOS) : l’état réel de scan
    _isScanningSub = FlutterBluePlus.isScanning.listen((v) {
      _isScanning = v;
      notifyListeners();
    });
  }

  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _discoveredServices = [];
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions = {};

  final _scannedDevicesController = StreamController<List<ScanResult>>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  final _dataReceivedController = StreamController<BleDataReceived>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<bool>? _isScanningSub;

  bool _isScanning = false;
  bool _isConnected = false;

  // --- Getters ---
  Stream<List<ScanResult>> get scannedDevicesStream => _scannedDevicesController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<BleDataReceived> get dataReceivedStream => _dataReceivedController.stream;

  /// Important pour l’UI (iOS): suivre l’état en continu
  Stream<BluetoothAdapterState> get adapterStateStream => FlutterBluePlus.adapterState;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothService> get discoveredServices => List.unmodifiable(_discoveredServices);
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;

  /// iOS: adapterState peut être `unknown` un court moment.
  /// On attend un état exploitable (on/off) ou bloquant (unauthorized/unavailable).
  Future<BluetoothAdapterState> _waitForAdapterReady({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);

    await for (final s in FlutterBluePlus.adapterState) {
      // États bloquants (flutter_blue_plus 1.36.8)
      if (s == BluetoothAdapterState.unauthorized || s == BluetoothAdapterState.unavailable) {
        return s;
      }

      // États exploitables
      if (s == BluetoothAdapterState.on || s == BluetoothAdapterState.off) {
        return s;
      }

      // unknown -> on attend, mais pas indéfiniment
      if (DateTime.now().isAfter(deadline)) {
        return s;
      }
    }

    return BluetoothAdapterState.unknown;
  }

  /// Démarre le scan BLE
  Future<void> startScan() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth non supporté sur cet appareil');
      }

      final state = await _waitForAdapterReady();

      if (state == BluetoothAdapterState.off) {
        throw Exception('Veuillez activer le Bluetooth');
      }
      if (state == BluetoothAdapterState.unauthorized) {
        throw Exception('Permissions Bluetooth requises');
      }
      if (state == BluetoothAdapterState.unavailable) {
        throw Exception('Bluetooth indisponible sur cet appareil');
      }
      if (state != BluetoothAdapterState.on) {
        // unknown trop long
        throw Exception('Initialisation Bluetooth… réessayez');
      }

      // Résultats scan (évite multi-subs)
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scannedDevicesController.add(results);
      });

      // Le timeout stoppe le scan automatiquement
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: BleConstants.scanDuration),
      );

      // _isScanning est mis à jour via _isScanningSub
    } catch (_) {
      notifyListeners();
      rethrow;
    }
  }

  /// Arrête le scan BLE
  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      await FlutterBluePlus.stopScan();

      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  /// Se connecte à un périphérique
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await stopScan();

      _connectedDevice = device;

      // Écouter les changements d'état de connexion
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        _isConnected = (state == BluetoothConnectionState.connected);
        _connectionStateController.add(state);
        notifyListeners();

        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Se connecter
      await device.connect(
        timeout: Duration(seconds: BleConstants.connectionTimeout),
        autoConnect: false,
      );

      // Découvrir les services
      _discoveredServices = await device.discoverServices();

      // Activer les notifications
      await _enableAllNotifications();

      notifyListeners();
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Active les notifications sur toutes les caractéristiques qui le supportent
  Future<void> _enableAllNotifications() async {
    debugPrint('🔔 Activation des notifications...');
    int notificationCount = 0;

    final heartRateServiceUuid = BleConstants.serviceHeartRateUuid.toLowerCase();
    final heartRateCharUuid = BleConstants.heartRateMeasCharUuid.toLowerCase();

    for (final service in _discoveredServices) {
      final serviceUuidLower = service.uuid.toString().toLowerCase();
      debugPrint('📡 Service découvert: ${service.uuid}');

      final isHeartRateService = serviceUuidLower == heartRateServiceUuid;
      if (isHeartRateService) {
        debugPrint('  ❤️ SERVICE HEART RATE DÉTECTÉ!');
      }

      for (final characteristic in service.characteristics) {
        final charUuidLower = characteristic.uuid.toString().toLowerCase();
        final isHeartRateChar = charUuidLower == heartRateCharUuid;

        debugPrint(
          '  └─ Caractéristique: ${characteristic.uuid}, '
          'Notify: ${characteristic.properties.notify}, '
          'Indicate: ${characteristic.properties.indicate}',
        );

        if (isHeartRateChar) {
          debugPrint('  ❤️ CARACTÉRISTIQUE HEART RATE MEASUREMENT DÉTECTÉE!');
        }

        if (characteristic.properties.notify || characteristic.properties.indicate) {
          try {
            await characteristic.setNotifyValue(true);
            notificationCount++;

            if (isHeartRateChar) {
              debugPrint('  ✅✅✅ NOTIFICATIONS HEART RATE ACTIVÉES! ✅✅✅');
            } else {
              debugPrint('  ✅ Notifications activées pour: ${characteristic.uuid}');
            }

            final sub = characteristic.lastValueStream.listen(
              (value) {
                if (isHeartRateChar) {
                  debugPrint(
                    '❤️❤️❤️ HR NOTIF! len=${value.length} data='
                    '${value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
                  );
                } else {
                  debugPrint('📨 Notification reçue de ${characteristic.uuid}: ${value.length} octets');
                }

                _dataReceivedController.add(
                  BleDataReceived(
                    serviceUuid: service.uuid.toString(),
                    characteristicUuid: characteristic.uuid.toString(),
                    data: value,
                    timestamp: DateTime.now(),
                  ),
                );
              },
              onError: (error) {
                debugPrint('❌ Erreur stream notifications ${characteristic.uuid}: $error');
              },
            );

            _notificationSubscriptions[characteristic.uuid.toString()] = sub;
          } catch (e) {
            debugPrint('❌ Erreur activation notif ${characteristic.uuid}: $e');
          }
        } else if (isHeartRateChar) {
          debugPrint('  ⚠️ Heart Rate Measurement ne supporte pas notify/indicate');
        }
      }
    }

    debugPrint('✅ $notificationCount notification(s) activée(s) au total');

    if (notificationCount > 0) {
      final hrKey = BleConstants.heartRateMeasCharUuid;
      final heartRateActive = _notificationSubscriptions.containsKey(hrKey) ||
          _notificationSubscriptions.containsKey(hrKey.toLowerCase()) ||
          _notificationSubscriptions.containsKey(hrKey.toUpperCase());

      if (heartRateActive) {
        debugPrint('✅✅✅ CONFIRMATION: Notifications Heart Rate ACTIVES!');
      } else {
        debugPrint('⚠️ Notifications Heart Rate NON actives!');
      }
    }
  }

  /// Se déconnecte du périphérique
  Future<void> disconnect() async {
    try {
      for (final subscription in _notificationSubscriptions.values) {
        await subscription.cancel();
      }
      _notificationSubscriptions.clear();

      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _handleDisconnection();
    } catch (_) {
      // ignore
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _discoveredServices = [];
    _isConnected = false;
    notifyListeners();
  }

  BluetoothCharacteristic? _findCharacteristic(String serviceUuid, String characteristicUuid) {
    for (final service in _discoveredServices) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
            return characteristic;
          }
        }
      }
    }
    return null;
  }

  /// Écrit des données dans une caractéristique
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  ) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Non connecté à un périphérique');
    }

    final characteristic = _findCharacteristic(serviceUuid, characteristicUuid);
    if (characteristic == null) {
      throw Exception('Caractéristique non trouvée: $characteristicUuid');
    }

    if (!characteristic.properties.write && !characteristic.properties.writeWithoutResponse) {
      throw Exception("La caractéristique ne supporte pas l'écriture");
    }

    if (characteristic.properties.writeWithoutResponse) {
      await characteristic.write(data, withoutResponse: true);
    } else {
      await characteristic.write(data, withoutResponse: false);
    }

    return true;
  }

  /// Lit des données d'une caractéristique
  Future<List<int>?> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Non connecté à un périphérique');
    }

    final characteristic = _findCharacteristic(serviceUuid, characteristicUuid);
    if (characteristic == null) {
      throw Exception('Caractéristique non trouvée: $characteristicUuid');
    }

    if (!characteristic.properties.read) {
      throw Exception('La caractéristique ne supporte pas la lecture');
    }

    return await characteristic.read();
  }

  /// Contrôle la LED (allumer/éteindre)
  Future<bool> controlLed(bool turnOn) async {
    final data = turnOn ? BleConstants.ledOn : BleConstants.ledOff;
    return writeCharacteristic(
      BleConstants.serviceP2PUuid,
      BleConstants.ledCharUuid,
      data,
    );
  }

  /// Réinitialise l'énergie dépensée (Heart Rate Control Point)
  Future<bool> resetEnergyExpended() async {
    return writeCharacteristic(
      BleConstants.serviceHeartRateUuid,
      BleConstants.heartRateCtrlPointCharUuid,
      BleConstants.resetEnergyExpended,
    );
  }

  /// Démarre l'enregistrement sur le STM32
  Future<bool> startRecording(int activityIndex) async {
    return writeCharacteristic(
      BleConstants.serviceP2PUuid,
      BleConstants.ledCharUuid,
      BleConstants.recordingStartWithActivity(activityIndex),
    );
  }

  /// Arrête l'enregistrement sur le STM32
  Future<bool> stopRecording() async {
    return writeCharacteristic(
      BleConstants.serviceP2PUuid,
      BleConstants.ledCharUuid,
      BleConstants.recordingStop,
    );
  }

  /// --------- Fichiers STM32 (SD) ---------
  Future<bool> _writeFileCtrl(List<int> data) async {
    return writeCharacteristic(
      BleConstants.serviceP2PUuid,
      BleConstants.fileCtrlCharUuid,
      data,
    );
  }

  Future<bool> requestFileList() async => _writeFileCtrl([0x01]);

  Future<bool> requestFileGet(String fileName) async {
    final path = '0:/$fileName';
    final bytes = utf8.encode(path);
    return _writeFileCtrl([0x02, ...bytes]);
  }

  Future<bool> requestFileAbort() async => _writeFileCtrl([0x03]);

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _isScanningSub?.cancel();

    for (final sub in _notificationSubscriptions.values) {
      sub.cancel();
    }
    _notificationSubscriptions.clear();

    _scannedDevicesController.close();
    _connectionStateController.close();
    _dataReceivedController.close();

    super.dispose();
  }
}