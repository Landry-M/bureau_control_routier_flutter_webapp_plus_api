import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/vehicule_service.dart';

class VehiculeProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  // Pagination (client-side)
  int _page = 1;
  final int _perPage = 12;

  // Getters
  List<Map<String, dynamic>> get all => _all;
  List<Map<String, dynamic>> get displayedItems =>
      _searchQuery.isEmpty ? _all : _filtered;
  bool get loading => _loading;
  String? get error => _error;
  int get page => _page;
  int get perPage => _perPage;
  String get searchQuery => _searchQuery;

  List<Map<String, dynamic>> get pageItems {
    final items = displayedItems;
    final start = (_page - 1) * _perPage;
    final end = start + _perPage;
    if (start >= items.length) return [];
    return items.sublist(start, end > items.length ? items.length : end);
  }

  int get totalPages =>
      (displayedItems.length / _perPage).ceil().clamp(1, 1000000);

  /// Charger tous les véhicules
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final vehiculeService = VehiculeService(apiClient: client);

      final result = await vehiculeService.getVehicules(
        page: 1,
        limit: 1000, // Récupérer toutes les données
      );

      _all = result;
      _page = 1;
      _loading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  /// Aller à la page suivante
  void nextPage() {
    if (_page < totalPages) {
      _page++;
      notifyListeners();
    }
  }

  /// Aller à la page précédente
  void previousPage() {
    if (_page > 1) {
      _page--;
      notifyListeners();
    }
  }

  /// Aller à une page spécifique
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _page = page;
      notifyListeners();
    }
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await load();
  }

  /// Rechercher dans les véhicules
  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    _page = 1; // Retour à la première page lors d'une recherche

    if (_searchQuery.isEmpty) {
      _filtered = [];
    } else {
      _filtered = _all.where((vehicle) {
        final plaque = vehicle['plaque']?.toString().toLowerCase() ?? '';
        final marque = vehicle['marque']?.toString().toLowerCase() ?? '';
        final modele = vehicle['modele']?.toString().toLowerCase() ?? '';
        final couleur = vehicle['couleur']?.toString().toLowerCase() ?? '';
        final proprietaire =
            vehicle['proprietaire']?.toString().toLowerCase() ?? '';
        final annee = vehicle['annee']?.toString().toLowerCase() ?? '';

        return plaque.contains(_searchQuery) ||
            marque.contains(_searchQuery) ||
            modele.contains(_searchQuery) ||
            couleur.contains(_searchQuery) ||
            proprietaire.contains(_searchQuery) ||
            annee.contains(_searchQuery);
      }).toList();
    }

    notifyListeners();
  }

  /// Effacer la recherche
  void clearSearch() {
    _searchQuery = '';
    _filtered = [];
    _page = 1;
    notifyListeners();
  }

  /// Réinitialiser les données
  void reset() {
    _all = [];
    _filtered = [];
    _searchQuery = '';
    _page = 1;
    _loading = true;
    _error = null;
    notifyListeners();
  }
}
