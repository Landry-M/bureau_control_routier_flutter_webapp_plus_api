import 'package:flutter/material.dart';
import '../services/global_search_service.dart';

class GlobalSearchProvider with ChangeNotifier {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';
  
  List<Map<String, dynamic>> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;
  bool get hasResults => _results.isNotEmpty;
  
  Future<void> search(String query, {String? username}) async {
    if (query.trim().isEmpty) {
      _results.clear();
      _query = '';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    _query = query;
    notifyListeners();
    
    try {
      final response = await GlobalSearchService.search(query, username: username);
      
      if (response['success'] == true) {
        _results = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _error = null;
      } else {
        _results = [];
        _error = response['message'] ?? 'Erreur lors de la recherche';
      }
    } catch (e) {
      _results = [];
      _error = 'Erreur de connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearResults() {
    _results.clear();
    _query = '';
    _error = null;
    notifyListeners();
  }
  
  Map<String, dynamic>? getResultById(String type, int id) {
    try {
      return _results.firstWhere(
        (result) => result['type'] == type && result['id'] == id,
      );
    } catch (e) {
      return null;
    }
  }
  
  List<Map<String, dynamic>> getResultsByType(String type) {
    return _results.where((result) => result['type'] == type).toList();
  }
  
  int getResultsCountByType(String type) {
    return _results.where((result) => result['type'] == type).length;
  }
  
  Map<String, int> getResultsCountByTypes() {
    final counts = <String, int>{};
    for (final result in _results) {
      final type = result['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
