import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/accident_models.dart';
import '../config/api_config.dart';

class AccidentApiService {
  final String baseUrl;

  AccidentApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Créer un accident
  Future<Map<String, dynamic>> createAccident({
    required Accident accident,
    required List<XFile> images,
    List<Map<String, dynamic>>? partiesPhotos,
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

      // Ajouter les images principales de l'accident (compatible Flutter Web)
      for (var i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[]',
            bytes,
            filename: images[i].name,
          ),
        );
      }

      // Ajouter les photos de chaque partie impliquée
      if (partiesPhotos != null) {
        for (var i = 0; i < partiesPhotos.length; i++) {
          final photos = partiesPhotos[i]['photos'] as List<XFile>;
          for (var photo in photos) {
            final bytes = await photo.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes(
                'partie_${i}_photos[]',
                bytes,
                filename: photo.name,
              ),
            );
          }
        }
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
      final response = await http.get(
        Uri.parse('$baseUrl/vehicules/search?q=${Uri.encodeComponent(plaque)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['data'] != null) {
          return (data['data'] as List)
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
    String? username,
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
      if (username != null && username.isNotEmpty) request.fields['username'] = username;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (data['success'] == true) {
        // Convertir l'ID en entier au cas où il serait retourné comme string
        final id = data['id'] ?? data['vehicule_id'] ?? 0;
        return id is String ? int.parse(id) : id;
      }
      throw Exception(data['error'] ?? data['message'] ?? 'Création impossible');
    } catch (e) {
      throw Exception('Erreur création véhicule: $e');
    }
  }
}
