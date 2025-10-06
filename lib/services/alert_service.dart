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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des alertes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
