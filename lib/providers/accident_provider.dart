import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/accident_service.dart';

class AccidentProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _accidents = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 20;
  String _searchQuery = '';

  // Getters
  List<Map<String, dynamic>> get accidents => _accidents;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Charger les accidents (première page ou refresh)
  Future<void> loadAccidents({bool refresh = false}) async {
    if (refresh) {
      _accidents.clear();
      _currentPage = 1;
      _hasMore = true;
      _error = null;
    }

    if (_loading || !_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final accidentService = AccidentService(apiClient: client);

      print('DEBUG: Chargement des accidents - Page: $_currentPage, Limit: $_limit, Search: $_searchQuery');
      print('DEBUG: URL de base: ${ApiConfig.baseUrl}');

      final newAccidents = await accidentService.getAccidents(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      print('DEBUG: Accidents récupérés: ${newAccidents.length}');

      if (newAccidents.length < _limit) {
        _hasMore = false;
      }

      _accidents.addAll(newAccidents);
      _currentPage++;
      _loading = false;
      print('DEBUG: Total accidents: ${_accidents.length}');
    } catch (e) {
      print('DEBUG: Erreur lors du chargement des accidents: $e');
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  /// Rechercher dans les accidents
  Future<void> searchAccidents(String query) async {
    _searchQuery = query.trim();
    await loadAccidents(refresh: true);
  }

  /// Effacer la recherche
  Future<void> clearSearch() async {
    _searchQuery = '';
    await loadAccidents(refresh: true);
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadAccidents(refresh: true);
  }

  /// Charger plus d'accidents (scroll infini)
  Future<void> loadMore() async {
    if (!_loading && _hasMore) {
      await loadAccidents();
    }
  }

  /// Récupérer un accident par ID avec ses témoins
  Future<Map<String, dynamic>> getAccidentDetails(int id) async {
    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final accidentService = AccidentService(apiClient: client);
      
      final accident = await accidentService.getAccidentById(id);
      final witnesses = await accidentService.getAccidentWitnesses(id);
      final parties = await accidentService.getAccidentParties(id);
      
      return {
        ...accident,
        'temoins': witnesses,
        'parties_impliquees': parties,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails: $e');
    }
  }

  /// Mettre à jour un accident
  Future<bool> updateAccident(int id, Map<String, dynamic> accidentData) async {
    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final accidentService = AccidentService(apiClient: client);
      
      await accidentService.updateAccident(id, accidentData);
      
      // Mettre à jour l'accident dans la liste locale
      final index = _accidents.indexWhere((accident) => accident['id'] == id);
      if (index != -1) {
        _accidents[index] = {..._accidents[index], ...accidentData};
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Réinitialiser les données
  void reset() {
    _accidents.clear();
    _currentPage = 1;
    _hasMore = true;
    _loading = false;
    _error = null;
    _searchQuery = '';
    notifyListeners();
  }
}
