import 'package:flutter/material.dart';
import '../services/alert_service.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _alerts;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get alerts => _alerts;

  int get totalAlerts {
    if (_alerts == null) return 0;
    return (_alerts!['total'] as int?) ?? 0;
  }

  List<dynamic> get avisRechercheActifs {
    if (_alerts == null || _alerts!['data'] == null) return [];
    return (_alerts!['data']['avis_recherche_actifs'] as List?) ?? [];
  }

  List<dynamic> get assurancesExpirees {
    if (_alerts == null || _alerts!['data'] == null) return [];
    return (_alerts!['data']['assurances_expirees'] as List?) ?? [];
  }

  List<dynamic> get permisTemporairesExpires {
    if (_alerts == null || _alerts!['data'] == null) return [];
    return (_alerts!['data']['permis_temporaires_expires'] as List?) ?? [];
  }

  List<dynamic> get plaquesExpirees {
    if (_alerts == null || _alerts!['data'] == null) return [];
    return (_alerts!['data']['plaques_expirees'] as List?) ?? [];
  }

  List<dynamic> get permisConduireExpires {
    if (_alerts == null || _alerts!['data'] == null) return [];
    return (_alerts!['data']['permis_conduire_expires'] as List?) ?? [];
  }

  /// Charge toutes les alertes
  Future<void> loadAlerts(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _alertService.getAllAlerts(username);
      
      if (response['success'] == true) {
        _alerts = response;
        _error = null;
      } else {
        _error = response['message'] ?? 'Erreur lors du chargement des alertes';
        _alerts = null;
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _alerts = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les alertes
  Future<void> refresh(String username) async {
    await loadAlerts(username);
  }

  /// Réinitialise l'état
  void reset() {
    _isLoading = false;
    _error = null;
    _alerts = null;
    notifyListeners();
  }
}
