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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception(
            'API Error: ${data['error'] ?? data['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Récupérer un accident par ID avec ses témoins
  Future<Map<String, dynamic>> getAccidentById(int id) async {
    final response = await _apiClient.get('/accidents/$id');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception(
          'Erreur lors du chargement de l\'accident: ${response.statusCode}');
    }
  }

  /// Récupérer les témoins d'un accident
  Future<List<Map<String, dynamic>>> getAccidentWitnesses(
      int accidentId) async {
    final response = await _apiClient.get('/accidents/$accidentId/temoins');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception(
          'Erreur lors du chargement des témoins: ${response.statusCode}');
    }
  }

  /// Créer un nouvel accident
  Future<Map<String, dynamic>> createAccident(
      Map<String, dynamic> accidentData) async {
    final response = await _apiClient.postJson('/accidents', accidentData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception(
          'Erreur lors de la création de l\'accident: ${response.statusCode}');
    }
  }

  /// Récupérer les parties impliquées d'un accident
  Future<List<Map<String, dynamic>>> getAccidentParties(int accidentId) async {
    final response = await _apiClient.get('/accidents/$accidentId/parties');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception(
          'Erreur lors du chargement des parties impliquées: ${response.statusCode}');
    }
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
