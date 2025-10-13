import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AlertService {
  /// Récupère toutes les alertes
  Future<Map<String, dynamic>> getAllAlerts(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alerts?username=$username'),
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }
      
      // Extraire uniquement le message d'erreur du JSON
      final errorMessage = data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des alertes';
      throw Exception(errorMessage);
    } catch (e) {
      // Si c'est déjà une exception, la relancer telle quelle
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion');
    }
  }
}
