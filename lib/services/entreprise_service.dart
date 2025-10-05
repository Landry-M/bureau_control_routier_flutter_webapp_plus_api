import 'dart:convert';
import 'api_client.dart';

class EntrepriseService {
  final ApiClient _apiClient;

  EntrepriseService(this._apiClient);

  /// Récupère la liste des entreprises avec pagination
  Future<Map<String, dynamic>> getEntreprises({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _apiClient.get('/entreprises?$queryString');
      final data = json.decode(response.body);

      if (data['success'] == true || data['ok'] == true) {
        return {
          'success': true,
          'data': data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des entreprises',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la récupération des entreprises: $e',
      };
    }
  }
}
