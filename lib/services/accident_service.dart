import 'dart:convert';
import 'api_client.dart';

class AccidentService {
  final ApiClient _apiClient;

  AccidentService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Récupérer tous les accidents avec pagination
  Future<List<Map<String, dynamic>>> getAccidents({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    String path = '/accidents?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await _apiClient.get(path);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur lors du chargement des accidents: ${response.statusCode}');
    }
  }

  /// Récupérer un accident par ID avec ses témoins
  Future<Map<String, dynamic>> getAccidentById(int id) async {
    final response = await _apiClient.get('/accidents/$id');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erreur lors du chargement de l\'accident: ${response.statusCode}');
    }
  }

  /// Récupérer les témoins d'un accident
  Future<List<Map<String, dynamic>>> getAccidentWitnesses(int accidentId) async {
    final response = await _apiClient.get('/accidents/$accidentId/temoins');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur lors du chargement des témoins: ${response.statusCode}');
    }
  }

  /// Créer un nouvel accident
  Future<Map<String, dynamic>> createAccident(Map<String, dynamic> accidentData) async {
    final response = await _apiClient.postJson('/accidents', accidentData);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de la création de l\'accident: ${response.statusCode}');
    }
  }

  /// Mettre à jour un accident
  Future<Map<String, dynamic>> updateAccident(int id, Map<String, dynamic> accidentData) async {
    final response = await _apiClient.postJson('/accidents/$id', accidentData);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de la mise à jour de l\'accident: ${response.statusCode}');
    }
  }
}
