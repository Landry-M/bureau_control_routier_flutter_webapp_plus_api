import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';
import '../services/session_schedule_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthProvider({AuthService? authService})
      : _authService =
            authService ?? AuthService(ApiClient(baseUrl: ApiConfig.baseUrl));

  String? _token;
  String _role = 'guest'; // guest, admin, superadmin
  String? _username;
  String? _userId;
  bool _loading = false;
  String? _error;
  bool _isFirstConnection = false;
  
  // Vérification périodique des horaires
  Timer? _scheduleCheckTimer;
  bool _scheduleCheckEnabled = true;
  DateTime? _lastScheduleCheck;
  
  // Gestion de l'inactivité
  Timer? _inactivityCheckTimer;
  DateTime? _lastActivityTime;
  static const Duration inactivityTimeout = Duration(minutes: 30);
  static const Duration warningBeforeTimeout = Duration(minutes: 5); // Avertir 5 min avant
  
  // Callback appelé si l'utilisateur est hors horaires ou inactif
  Function()? onScheduleViolation;
  Function()? onInactivityTimeout;
  Function(int minutesRemaining)? onInactivityWarning;
  bool _warningShown = false; // Pour éviter d'afficher l'avertissement plusieurs fois

  String? get token => _token;
  String get role => _role;
  String get username => _username ?? 'Utilisateur';
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isFirstConnection => _isFirstConnection;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _role = prefs.getString('auth_role') ?? 'guest';
    _username = prefs.getString('auth_username');
    _userId = prefs.getString('auth_user_id');
    _isFirstConnection = false; // Always false on load, will be set by API
    notifyListeners();
    
    // Démarrer les vérifications périodiques si l'utilisateur est authentifié
    if (isAuthenticated) {
      startScheduleCheck();
      startInactivityCheck();
    }
  }

  Future<bool> login(
      {required String matricule, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await _authService.login(matricule: matricule, password: password);
      // Expecting token & role in response. Fallbacks for scaffolding
      final token = (data['token'] ?? 'demo_token') as String;
      final role = (data['role'] ?? 'admin') as String;
      final username =
          (data['username'] ?? data['matricule'] ?? 'Utilisateur') as String;
      final userId = data['user']?['id']?.toString();
      final isFirstConnection = data['first_connection'] == true || 
                                data['first_connection'] == 'true' || 
                                data['first_connection'] == 1;

      _token = token;
      _role = role;
      _username = username;
      _userId = userId;
      _isFirstConnection = isFirstConnection;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_role', role);
      await prefs.setString('auth_username', username);
      if (userId != null) {
        await prefs.setString('auth_user_id', userId);
      }

      _loading = false;
      notifyListeners();
      
      // Démarrer les vérifications périodiques après connexion réussie
      startScheduleCheck();
      startInactivityCheck();
      
      return true;
    } catch (e) {
      _loading = false;
      if (e is ApiException) {
        // Prefer "message", then aggregate validation errors if present
        String baseMsg = e.message;
        String agg = '';
        if (e.details != null && e.details!['errors'] is Map<String, dynamic>) {
          final errs = e.details!['errors'] as Map<String, dynamic>;
          agg = errs.entries
              .expand((en) => (en.value is List)
                  ? List<String>.from(en.value)
                  : [en.value.toString()])
              .join('\n');
        }
        final composed = [agg.isNotEmpty ? agg : null, baseMsg]
            .where((s) => s != null && s.trim().isNotEmpty)
            .map((s) => s?.trim() ?? '')
            .join('\n');
        _error = composed.isNotEmpty
            ? '$composed (code ${e.statusCode})'
            : 'Erreur de connexion (code ${e.statusCode})';
      } else {
        _error = 'Erreur de connexion: ${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeFirstConnection({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_userId == null) {
      _error = 'Utilisateur non identifié';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.completeFirstConnection(
        userId: _userId!,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _isFirstConnection = false;
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      if (e is ApiException) {
        // Use the exact error message from API
        if (e.details != null && e.details!['errors'] is Map<String, dynamic>) {
          final errs = e.details!['errors'] as Map<String, dynamic>;
          final messages = errs.entries
              .expand((e) => (e.value is List)
                  ? List<String>.from(e.value)
                  : [e.value.toString()])
              .join('\n');
          _error = messages.isNotEmpty ? messages : e.message;
        } else {
          _error = e.message;
        }
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Arrêter les vérifications périodiques
    _stopScheduleCheck();
    _stopInactivityCheck();
    
    _token = null;
    _role = 'guest';
    _username = null;
    _userId = null;
    _isFirstConnection = false;
    _lastActivityTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_username');
    await prefs.remove('auth_user_id');
    notifyListeners();
  }
  
  /// Démarre la vérification périodique des horaires (toutes les 5 minutes)
  void startScheduleCheck() {
    if (_role == 'superadmin' || !isAuthenticated) {
      return; // Pas de vérification pour les superadmins
    }
    
    _stopScheduleCheck(); // Arrêter toute vérification existante
    
    // Vérifier immédiatement
    _checkSchedule();
    
    // Puis vérifier toutes les 5 minutes
    _scheduleCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _checkSchedule(),
    );
  }
  
  /// Arrête la vérification périodique
  void _stopScheduleCheck() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = null;
  }
  
  /// Vérifie les horaires de connexion
  Future<void> _checkSchedule() async {
    if (!_scheduleCheckEnabled || !isAuthenticated || _role == 'superadmin') {
      return;
    }
    
    _lastScheduleCheck = DateTime.now();
    
    try {
      final result = await SessionScheduleService.checkSchedule(
        userId: _userId,
        matricule: _username,
      );
      
      if (!result.authorized && result.reason == 'outside_schedule') {
        // Utilisateur en dehors des horaires
        if (onScheduleViolation != null) {
          onScheduleViolation!();
        }
      } else if (!result.authorized && result.reason == 'account_disabled') {
        // Compte désactivé
        if (onScheduleViolation != null) {
          onScheduleViolation!();
        }
      }
    } catch (e) {
      // En cas d'erreur, on ne déconnecte pas l'utilisateur
      debugPrint('Erreur lors de la vérification des horaires: $e');
    }
  }
  
  /// Force une vérification immédiate des horaires
  Future<bool> checkScheduleNow() async {
    if (!isAuthenticated || _role == 'superadmin') {
      return true; // Toujours autorisé pour les superadmins
    }
    
    try {
      final result = await SessionScheduleService.checkSchedule(
        userId: _userId,
        matricule: _username,
      );
      
      return result.authorized;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des horaires: $e');
      return true; // En cas d'erreur, autoriser par défaut
    }
  }
  
  /// Démarre la vérification d'inactivité (toutes les minutes)
  void startInactivityCheck() {
    if (!isAuthenticated) {
      return;
    }
    
    _stopInactivityCheck(); // Arrêter toute vérification existante
    
    // Enregistrer l'activité initiale
    _lastActivityTime = DateTime.now();
    
    // Vérifier toutes les minutes
    _inactivityCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _checkInactivity(),
    );
  }
  
  /// Arrête la vérification d'inactivité
  void _stopInactivityCheck() {
    _inactivityCheckTimer?.cancel();
    _inactivityCheckTimer = null;
  }
  
  /// Enregistre une activité utilisateur (appelée lors d'interactions)
  void recordActivity() {
    if (!isAuthenticated) {
      return;
    }
    
    _lastActivityTime = DateTime.now();
    _warningShown = false; // Réinitialiser le flag d'avertissement
    debugPrint('Activité utilisateur enregistrée: ${_lastActivityTime}');
  }
  
  /// Vérifie si l'utilisateur est inactif depuis trop longtemps
  void _checkInactivity() {
    if (!isAuthenticated || _lastActivityTime == null) {
      return;
    }
    
    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastActivityTime!);
    
    debugPrint('Vérification inactivité: ${inactiveDuration.inMinutes} minutes');
    
    // Vérifier si le timeout est atteint
    if (inactiveDuration >= inactivityTimeout) {
      // L'utilisateur est inactif depuis trop longtemps
      debugPrint('Session expirée par inactivité (${inactiveDuration.inMinutes} minutes)');
      
      if (onInactivityTimeout != null) {
        onInactivityTimeout!();
      }
    }
    // Vérifier si on doit afficher l'avertissement
    else if (!_warningShown && inactiveDuration >= (inactivityTimeout - warningBeforeTimeout)) {
      final minutesRemaining = inactivityTimeout.inMinutes - inactiveDuration.inMinutes;
      debugPrint('Avertissement inactivité: $minutesRemaining minutes restantes');
      
      _warningShown = true;
      
      if (onInactivityWarning != null) {
        onInactivityWarning!(minutesRemaining);
      }
    }
  }
  
  /// Obtient le temps restant avant expiration de session
  Duration? getTimeUntilSessionExpiry() {
    if (!isAuthenticated || _lastActivityTime == null) {
      return null;
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastActivityTime!);
    final remaining = inactivityTimeout - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  @override
  void dispose() {
    _stopScheduleCheck();
    _stopInactivityCheck();
    super.dispose();
  }
}
