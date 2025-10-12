import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuration de l'URL de base de l'API
  static const String _localhost = 'localhost:8000';
  static const String _androidEmulator = '10.0.2.2:8000';
  static const String _iosSimulator = 'localhost:8000';
  static const String _production = 'controls.heaventech.net';
  
  /// Retourne l'URL de base appropriée selon la plateforme
  static String get baseUrl {
    // Détection automatique : si on est sur le domaine de production, utiliser l'API relative (même domaine)
    if (kIsWeb && Uri.base.host.contains('heaventech.net')) {
      print('DEBUG: Utilisation API production - ${Uri.base.host}');
      return '/api/routes/index.php'; // URL RELATIVE - pas de CORS !
    }
    
    if (kDebugMode) {
      // Mode développement - utilise localhost
      if (kIsWeb) {
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
    } else {
      // Mode production - utilise le domaine de production
      return 'https://$_production/api/routes/index.php';
    }
  }
  
  /// URL pour émulateur Android
  static String get androidEmulatorUrl => 'http://$_androidEmulator/api/routes/index.php';
  
  /// URL pour simulateur iOS  
  static String get iosSimulatorUrl => 'http://$_iosSimulator/api/routes/index.php';
  
  /// URL pour localhost (web/desktop)
  static String get localhostUrl => 'http://$_localhost/api/routes/index.php';
  
  /// URL de base pour les images et fichiers statiques (sans /api/routes/index.php)
  static String get imageBaseUrl {
    // Détection automatique : si on est sur le domaine de production, utiliser le domaine complet
    if (kIsWeb && Uri.base.host.contains('heaventech.net')) {
      return 'https://${Uri.base.host}'; // Utiliser le domaine actuel avec protocole HTTPS
    }
    
    if (kDebugMode) {
      // Mode développement - utilise localhost
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
    } else {
      // Mode production - utilise le domaine de production
      return 'https://$_production';
    }
  }

  /// URL complète avec domaine pour url_launcher (ouvrir dans le navigateur)
  /// Utilisé pour les PDF, prévisualisations, etc.
  static String get fullBaseUrl {
    // Toujours retourner une URL complète avec protocole et domaine
    if (kIsWeb && Uri.base.host.contains('heaventech.net')) {
      return 'https://${Uri.base.host}/api/routes/index.php';
    }
    
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://$_localhost/api/routes/index.php';
      }
      
      if (Platform.isAndroid) {
        return 'http://$_androidEmulator/api/routes/index.php';
      }
      
      if (Platform.isIOS) {
        return 'http://$_iosSimulator/api/routes/index.php';
      }
      
      return 'http://$_localhost/api/routes/index.php';
    } else {
      return 'https://$_production/api/routes/index.php';
    }
  }

  /// Méthode pour forcer une URL spécifique (utile pour les tests)
  static String getCustomUrl(String host, int port) {
    return 'http://$host:$port/api/routes/index.php';
  }

  /// URL pour la prévisualisation de contravention (affichage direct en HTML)
  static String getContraventionDisplayUrl(int contraventionId) {
    if (kIsWeb && Uri.base.host.contains('heaventech.net')) {
      return 'https://${Uri.base.host}/api/contravention_display.php?id=$contraventionId';
    }
    
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://$_localhost/api/contravention_display.php?id=$contraventionId';
      }
      
      if (Platform.isAndroid) {
        return 'http://$_androidEmulator/api/contravention_display.php?id=$contraventionId';
      }
      
      if (Platform.isIOS) {
        return 'http://$_iosSimulator/api/contravention_display.php?id=$contraventionId';
      }
      
      return 'http://$_localhost/api/contravention_display.php?id=$contraventionId';
    } else {
      return 'https://$_production/api/contravention_display.php?id=$contraventionId';
    }
  }
}
