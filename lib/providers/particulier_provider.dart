import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ParticulierProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _particuliers = [];
  bool _isLoading = false;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _searchQuery = '';

  // Getters
  List<Map<String, dynamic>> get particuliers => _particuliers;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;

  /// Récupérer tous les particuliers avec pagination
  Future<void> fetchParticuliers({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/particuliers',
          'page': page.toString(),
          'limit': limit.toString(),
          if (search.isNotEmpty) 'search': search,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _particuliers = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _currentPage = data['pagination']['page'] ?? 1;
          _totalPages = data['pagination']['pages'] ?? 1;
          _totalCount = data['pagination']['total'] ?? 0;
          _searchQuery = search;
          _error = '';
        } else {
          _error = data['error'] ?? 'Erreur lors du chargement des particuliers';
          _particuliers = [];
        }
      } else {
        _error = 'Erreur HTTP: ${response.statusCode}';
        _particuliers = [];
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _particuliers = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Rechercher des particuliers
  Future<void> searchParticuliers(String query) async {
    await fetchParticuliers(page: 1, search: query);
  }

  /// Charger la page suivante
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages && !_isLoading) {
      await fetchParticuliers(
        page: _currentPage + 1,
        search: _searchQuery,
      );
    }
  }

  /// Charger la page précédente
  Future<void> loadPreviousPage() async {
    if (_currentPage > 1 && !_isLoading) {
      await fetchParticuliers(
        page: _currentPage - 1,
        search: _searchQuery,
      );
    }
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await fetchParticuliers(page: 1, search: _searchQuery);
  }

  /// Réinitialiser les données
  void reset() {
    _particuliers = [];
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _searchQuery = '';
    _error = '';
    _isLoading = false;
    notifyListeners();
  }
}
