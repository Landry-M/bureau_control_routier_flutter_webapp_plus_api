import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuration de l'URL de base de l'API
  static const String _localhost = 'localhost:8000';
  static const String _androidEmulator = '10.0.2.2:8000';
  static const String _iosSimulator = 'localhost:8000';
  
  /// Retourne l'URL de base appropriée selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      // Application web - utilise localhost
      return 'http://$_localhost/api/routes/index.php';
    }
    
    if (Platform.isAndroid) {
      // Émulateur Android - utilise 10.0.2.2
      return 'http://$_androidEmulator/api/routes/index.php';
    }
    
    if (Platform.isIOS) {
      // Simulateur iOS - utilise localhost
      return 'http://$_iosSimulator/api/routes/index.php';
    }
    
    // Desktop (macOS, Windows, Linux) - utilise localhost
    return 'http://$_localhost/api/routes/index.php';
  }
  
  /// URL pour émulateur Android
  static String get androidEmulatorUrl => 'http://$_androidEmulator/api/routes/index.php';
  
  /// URL pour simulateur iOS  
  static String get iosSimulatorUrl => 'http://$_iosSimulator/api/routes/index.php';
  
  /// URL pour localhost (web/desktop)
  static String get localhostUrl => 'http://$_localhost/api/routes/index.php';
  
  /// URL de base pour les images et fichiers statiques (sans /api/routes/index.php)
  static String get imageBaseUrl {
    if (kIsWeb) {
      return 'http://$_localhost';
    }
    
    if (Platform.isAndroid) {
      return 'http://$_androidEmulator';
    }
    
    if (Platform.isIOS) {
      return 'http://$_iosSimulator';
    }
    
    return 'http://$_localhost';
  }

  /// Méthode pour forcer une URL spécifique (utile pour les tests)
  static String getCustomUrl(String host, int port) {
    return 'http://$host:$port/api/routes/index.php';
  }
}
