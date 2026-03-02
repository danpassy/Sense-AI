/// Constantes BLE pour la communication avec les appareils STM32WB
class BleConstants {
  // ========== Service My_P2P_Server ==========
  // UUID du service P2P personnalisé
  static const String serviceP2PUuid = '0000fe40-cc7a-482a-984a-7f2ed5b3e58f';
  
  // UUID de la caractéristique LED_C (contrôle LED - Read/Write)
  static const String ledCharUuid = '0000fe41-8e22-4541-9d4c-21edae82ed19';
  
  // UUID de la caractéristique SWITCH_C (notifications du bouton)
  static const String switchCharUuid = '0000fe42-8e22-4541-9d4c-21edae82ed19';
  
  // UUID de la caractéristique LONG_C (notifications longues)
  static const String longCharUuid = '0000fe43-8e22-4541-9d4c-21edae82ed19';

  // ========== Transfert fichiers SD (My_P2P_Server) ==========
  // UUID de la caractéristique FILE_CTRL (WriteWithoutResponse)
  static const String fileCtrlCharUuid = '0000fe44-8e22-4541-9d4c-21edae82ed19';
  // UUID de la caractéristique FILE_DATA (Notify)
  static const String fileDataCharUuid = '0000fe45-8e22-4541-9d4c-21edae82ed19';
  
  // ========== Service Heart Rate ==========
  // UUID du service Heart Rate (standard BLE)
  static const String serviceHeartRateUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  
  // UUID de la caractéristique Heart Rate Measurement (notifications)
  static const String heartRateMeasCharUuid = '00002a37-0000-1000-8000-00805f9b34fb';
  
  // UUID de la caractéristique Body Sensor Location (read)
  static const String heartRateSensorLocCharUuid = '00002a38-0000-1000-8000-00805f9b34fb';
  
  // UUID de la caractéristique Heart Rate Control Point (write)
  static const String heartRateCtrlPointCharUuid = '00002a39-0000-1000-8000-00805f9b34fb';
  
  // ========== Descripteurs ==========
  // UUID du descripteur CCCD (Client Characteristic Configuration Descriptor)
  static const String cccdUuid = '00002902-0000-1000-8000-00805f9b34fb';
  
  // ========== Configuration ==========
  // Nom du périphérique attendu (optionnel)
  static const String deviceName = 'MyCST';
  
  // Durée du scan en secondes
  static const int scanDuration = 15;
  
  // Timeout de connexion en secondes
  static const int connectionTimeout = 15;
  
  // ========== Valeurs de contrôle ==========
  // Commande pour allumer la LED (0x00 0x01)
  static const List<int> ledOn = [0x00, 0x01];
  
  // Commande pour éteindre la LED (0x00 0x00)
  static const List<int> ledOff = [0x00, 0x00];
  
  // Commande pour réinitialiser l'énergie dépensée (Heart Rate Control Point)
  static const List<int> resetEnergyExpended = [0x01];
  
  // ========== Enregistrement STM32 (LED_C, octet 0 = 0x02) ==========
  // Arrêter l'enregistrement
  static const List<int> recordingStop = [0x02, 0x00];
  // Démarrer: [0x02, 1+activityIndex]. activityIndex 0..5 = COURSE,MARCHE,VELO,FITNESS,YOGA,AUTRE
  static List<int> recordingStartWithActivity(int activityIndex) =>
      [0x02, 1 + activityIndex.clamp(0, 5)];
}

