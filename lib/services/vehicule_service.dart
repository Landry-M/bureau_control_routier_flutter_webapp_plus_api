import 'dart:convert';
import 'api_client.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

class VehiculeService {
  final ApiClient _apiClient;

  VehiculeService({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(baseUrl: 'http://localhost:8000/api/routes/index.php');
  

  /// Crée un nouveau véhicule avec ou sans contravention
  Future<Map<String, dynamic>> createVehicule(
    Map<String, dynamic> data,
    List<PlatformFile> images,
    List<PlatformFile> contraventionPhotos,
  ) async {
    try {
      // Prepare fields as strings for multipart
      final fields = <String, String>{};
      data.forEach((key, value) {
        if (value != null) fields[key] = value.toString();
      });

      final files = <http.MultipartFile>[];
      for (final f in images) {
        if (f.bytes != null) {
          files.add(http.MultipartFile.fromBytes(
            'vehicle_images[]',
            f.bytes!,
            filename: f.name,
            contentType: _guessContentType(f.name),
          ));
        }
      }
      for (final f in contraventionPhotos) {
        if (f.bytes != null) {
          files.add(http.MultipartFile.fromBytes(
            'contravention_images[]',
            f.bytes!,
            filename: f.name,
            contentType: _guessContentType(f.name),
          ));
        }
      }

      final response = await _apiClient.postMultipart(
        '/vehicule/create',
        fields: fields,
        files: files,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du véhicule: $e');
    }
  }

  /// Récupère la liste des véhicules
  Future<List<Map<String, dynamic>>> getVehicules({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      // Construire l'URL avec les paramètres de requête
      final uri = Uri.parse(_apiClient.baseUrl).replace(
        queryParameters: {
          'route': '/vehicules',
          'page': page.toString(),
          'limit': limit.toString(),
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final response = await http.get(uri);
      final data = json.decode(response.body);

      // Gérer les deux formats de réponse API
      if (data['ok'] == true || data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        // Debug: afficher la réponse complète pour diagnostiquer
        print('DEBUG VehiculeService - Réponse API: $data');
        throw Exception(
            data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des véhicules');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }

  /// Recherche locale renvoyant toutes les correspondances pour une plaque/texte
  Future<List<Map<String, dynamic>>> searchLocal(String query) async {
    final resp = await _apiClient
        .get('/vehicules/search?q=${Uri.encodeComponent(query)}');
    final data = json.decode(resp.body);
    if (data is Map<String, dynamic>) {
      final items = (data['items'] ?? data['data']) as dynamic;
      if (items is List) {
        return List<Map<String, dynamic>>.from(
            items.map((e) => Map<String, dynamic>.from(e)));
      }
    }
    return <Map<String, dynamic>>[];
  }

  /// Recherche spécifique par plaque dans la table vehicule_plaque
  Future<List<Map<String, dynamic>>> searchByPlaque(String plaque) async {
    try {
      final response = await _apiClient.get('/vehicules?search=${Uri.encodeComponent(plaque)}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true || data['ok'] == true) {
          final items = data['data'] ?? data['items'] ?? [];
          return List<Map<String, dynamic>>.from(items);
        }
      }
      
      return [];
    } catch (e) {
      throw Exception('Erreur lors de la recherche par plaque: $e');
    }
  }

  /// Recherche une plaque d'immatriculation (locale puis DGI)
  Future<Map<String, dynamic>?> searchPlaque(String plate) async {
    try {
      // 1. Recherche locale
      final localResponse = await _apiClient
          .get('/vehicules/search?q=${Uri.encodeComponent(plate)}');
      final localData = json.decode(localResponse.body);

      if (localData is Map<String, dynamic> &&
          localData['ok'] == true &&
          localData['items']?.isNotEmpty == true) {
        return Map<String, dynamic>.from(localData['items'][0]);
      }

      // 2. Recherche externe DGI si non trouvé localement
      final externalResponse = await _apiClient.get(
          '/api/vehicules/fetch-externe?plate=${Uri.encodeComponent(plate)}');
      final externalData = json.decode(externalResponse.body);

      if (externalData is Map<String, dynamic> &&
          externalData['ok'] == true &&
          externalData['data'] != null) {
        return Map<String, dynamic>.from(externalData['data']);
      }

      return null;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de plaque: $e');
    }
  }

  /// Récupère un véhicule par ID interne
  Future<Map<String, dynamic>?> getVehiculeById(int id) async {
    final resp = await _apiClient.get('/vehicule/$id');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body);
      if (data is Map<String, dynamic> && data['state'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    return null;
  }
}

/// Best-effort MIME type guess based on filename extension
MediaType? _guessContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
    return MediaType('image', 'jpeg');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  return null;
}
