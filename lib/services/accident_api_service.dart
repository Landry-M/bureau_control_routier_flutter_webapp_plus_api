import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/accident_models.dart';
import '../config/api_config.dart';

class AccidentApiService {
  final String baseUrl;

  AccidentApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Créer un accident
  Future<Map<String, dynamic>> createAccident({
    required Accident accident,
    required List<File> images,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/create-accident'),
      );

      // Ajouter les champs de base
      final jsonData = accident.toJson();
      jsonData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Ajouter les images
      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath('images[]', image.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      return data;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'accident: $e');
    }
  }

  /// Rechercher un véhicule par plaque
  Future<List<VehiculeImplique>> searchVehicle(String plaque) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accident/search-vehicle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plaque': plaque}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['vehicles'] != null) {
          return (data['vehicles'] as List)
              .map((v) => VehiculeImplique.fromJson(v))
              .toList();
        }
        return [];
      }
      throw Exception('Erreur de recherche: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur recherche véhicule: $e');
    }
  }

  /// Créer rapidement un véhicule
  Future<int> quickCreateVehicle({
    required String plaque,
    String? marque,
    String? modele,
    String? couleur,
    String? annee,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/vehicule/quick-create'),
      );

      request.fields['plaque'] = plaque;
      if (marque != null && marque.isNotEmpty) request.fields['marque'] = marque;
      if (modele != null && modele.isNotEmpty) request.fields['modele'] = modele;
      if (couleur != null && couleur.isNotEmpty) request.fields['couleur'] = couleur;
      if (annee != null && annee.isNotEmpty) request.fields['annee'] = annee;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (data['ok'] == true || data['success'] == true) {
        return data['id'] ?? data['vehicule_id'] ?? 0;
      }
      throw Exception(data['error'] ?? data['message'] ?? 'Création impossible');
    } catch (e) {
      throw Exception('Erreur création véhicule: $e');
    }
  }
}
