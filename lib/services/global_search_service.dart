import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GlobalSearchService {
  static Future<Map<String, dynamic>> search(String query, {String? username}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/search/global?q=${Uri.encodeComponent(query)}&username=${username ?? 'system'}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> getDetails(String type, int id, {String? username}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/search/details/$type/$id?username=${username ?? 'system'}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }
}
