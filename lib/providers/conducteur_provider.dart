import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ConducteurProvider with ChangeNotifier {
  List<Map<String, dynamic>> _conducteurs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // Getters
  List<Map<String, dynamic>> get conducteurs => _searchQuery.isEmpty ? _conducteurs : _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get itemsPerPage => _itemsPerPage;

  Future<void> fetchConducteurs({int page = 1, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _conducteurs.clear();
      _filtered.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/conducteurs?page=$page&limit=$_itemsPerPage');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> newConducteurs = data['data'] ?? [];
          
          if (refresh || page == 1) {
            _conducteurs = newConducteurs.cast<Map<String, dynamic>>();
          } else {
            _conducteurs.addAll(newConducteurs.cast<Map<String, dynamic>>());
          }
          
          _currentPage = page;
          _totalPages = data['pagination']['pages'] ?? 1;
          _totalItems = data['pagination']['total'] ?? 0;
          
          // Appliquer la recherche si nécessaire
          if (_searchQuery.isNotEmpty) {
            _applySearch();
          }
        } else {
          _error = data['message'] ?? 'Erreur lors du chargement des conducteurs';
        }
      } else {
        _error = 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchConducteurs(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      _filtered.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/conducteurs?search=${Uri.encodeComponent(_searchQuery)}&limit=100');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          _filtered = (data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          _error = data['message'] ?? 'Erreur lors de la recherche';
          _filtered.clear();
        }
      } else {
        _error = 'Erreur serveur: ${response.statusCode}';
        _filtered.clear();
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _filtered.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filtered.clear();
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filtered = _conducteurs.where((conducteur) {
      final nom = (conducteur['nom'] ?? '').toString().toLowerCase();
      final gsm = (conducteur['gsm'] ?? '').toString().toLowerCase();
      final adresse = (conducteur['adresse'] ?? '').toString().toLowerCase();
      
      return nom.contains(query) || 
             gsm.contains(query) || 
             adresse.contains(query);
    }).toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _filtered.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getConducteurById(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/conducteurs/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du conducteur: $e');
    }
    return null;
  }

  Future<bool> createConducteur(Map<String, dynamic> conducteurData) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/conducteur-vehicule/create'),
      );

      // Ajouter les champs de données
      conducteurData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          // Rafraîchir la liste
          await fetchConducteurs(refresh: true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du conducteur: $e');
    }
    return false;
  }

  Future<bool> updateConducteur(int id, Map<String, dynamic> conducteurData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/conducteurs/$id/update');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(conducteurData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Rafraîchir la liste
          await fetchConducteurs(refresh: true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du conducteur: $e');
    }
    return false;
  }

  Future<bool> deleteConducteur(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/conducteurs/$id/delete');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Rafraîchir la liste
          await fetchConducteurs(refresh: true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du conducteur: $e');
    }
    return false;
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchConducteurs(page: _currentPage + 1);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchConducteurs(page: _currentPage - 1);
    }
  }

  void refresh() {
    fetchConducteurs(refresh: true);
  }

  void reset() {
    _conducteurs.clear();
    _filtered.clear();
    _searchQuery = '';
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
