import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  // Configure your API base URL here (dev)
  static const String _defaultApiBase =
      'http://localhost/api/routes/index.php';

  final AuthService _authService;
  AuthProvider({AuthService? authService})
      : _authService =
            authService ?? AuthService(ApiClient(baseUrl: _defaultApiBase));

  String? _token;
  String _role = 'guest'; // guest, admin, superadmin
  String? _username;
  String? _userId;
  bool _loading = false;
  String? _error;
  bool _isFirstConnection = false;

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
      return true;
    } catch (e) {
      _loading = false;
      if (e is ApiException) {
        // Prefer "message", then aggregate validation errors if present
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
    _token = null;
    _role = 'guest';
    _username = null;
    _userId = null;
    _isFirstConnection = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_username');
    await prefs.remove('auth_user_id');
    notifyListeners();
  }
}
