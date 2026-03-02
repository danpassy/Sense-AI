import 'package:permission_handler/permission_handler.dart';

/// Helper pour gérer les permissions Bluetooth
class PermissionHelper {
  /// Demande les permissions Bluetooth nécessaires
  static Future<bool> requestBluetoothPermissions() async {
    try {
      // Pour Android 12+ (API 31+)
      if (await Permission.bluetoothScan.isRestricted) {
        return false;
      }

      // Demander les permissions
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.location.request();

      return bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          (locationStatus.isGranted || locationStatus.isLimited);
    } catch (e) {
      // Fallback pour les versions antérieures à Android 12
      final locationStatus = await Permission.location.request();
      return locationStatus.isGranted || locationStatus.isLimited;
    }
  }

  /// Vérifie si les permissions sont accordées
  static Future<bool> checkBluetoothPermissions() async {
    try {
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      final locationStatus = await Permission.location.status;

      return bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          (locationStatus.isGranted || locationStatus.isLimited);
    } catch (e) {
      // Fallback pour les versions antérieures à Android 12
      final locationStatus = await Permission.location.status;
      return locationStatus.isGranted || locationStatus.isLimited;
    }
  }
}









