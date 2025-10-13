import 'dart:convert';
import 'package:http/http.dart' as http;
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

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    
    // Extraire uniquement le message d'erreur du JSON
    final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des accidents';
    throw Exception(errorMessage);
  }

  /// Récupérer un accident par ID avec ses témoins
  Future<Map<String, dynamic>> getAccidentById(int id) async {
    final response = await _apiClient.get('/accidents/$id');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'] ?? {};
    }
    
    // Extraire uniquement le message d'erreur du JSON
    final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors du chargement de l\'accident';
    throw Exception(errorMessage);
  }

  /// Récupérer les témoins d'un accident
  Future<List<Map<String, dynamic>>> getAccidentWitnesses(
      int accidentId) async {
    final response = await _apiClient.get('/accidents/$accidentId/temoins');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    
    // Extraire uniquement le message d'erreur du JSON
    final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors du chargement des témoins';
    throw Exception(errorMessage);
  }

  /// Créer un nouvel accident
  Future<Map<String, dynamic>> createAccident(
      Map<String, dynamic> accidentData) async {
    final response = await _apiClient.postJson('/accidents', accidentData);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }
    
    // Extraire uniquement le message d'erreur du JSON
    final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors de la création de l\'accident';
    throw Exception(errorMessage);
  }

  /// Récupérer les parties impliquées d'un accident
  Future<List<Map<String, dynamic>>> getAccidentParties(int accidentId) async {
    final response = await _apiClient.get('/accidents/$accidentId/parties');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    
    // Extraire uniquement le message d'erreur du JSON
    final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors du chargement des parties impliquées';
    throw Exception(errorMessage);
  }

  /// Mettre à jour un accident
  Future<bool> updateAccident(int id, Map<String, dynamic> accidentData) async {
    final response =
        await _apiClient.postJson('/accidents/$id/update', accidentData);
    return response.statusCode == 200;
  }

  /// Tester la connectivité aux images
  Future<bool> testImageConnectivity(String imageUrl) async {
    try {
      // Utiliser http directement pour tester l'image
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);
      print(
          'DEBUG - Test connectivité image: $imageUrl -> ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG - Erreur test connectivité: $e');
      return false;
    }
  }
}
