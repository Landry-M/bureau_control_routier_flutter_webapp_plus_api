import 'dart:convert';

import 'api_client.dart';
import 'api_exception.dart';

class LogService {
  final ApiClient client;
  LogService(this.client);

  Future<Map<String, dynamic>> getLogs({
    int limit = 100,
    int offset = 0,
    String? username,
    String? action,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    // Construire les paramètres de requête
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (username != null && username.isNotEmpty) {
      queryParams['username'] = username;
    }
    
    if (action != null && action.isNotEmpty) {
      queryParams['action'] = action;
    }
    
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['date_to'] = dateTo;
    }
    
    // Construire l'URL avec les paramètres
    String url = '/logs';
    if (queryParams.isNotEmpty) {
      final params = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$params';
    }
    
    final resp = await client.get(url);
    final status = resp.statusCode;
    Map<String, dynamic> data = {};
    
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    
    if (status >= 200 && status < 300) {
      return data;
    }
    
    final message = (data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des logs').toString();
    final details = (data['errors'] is Map<String, dynamic>) ? data['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (data.isEmpty ? null : data));
  }

  Future<Map<String, dynamic>> getStats({int days = 30}) async {
    final resp = await client.get('/logs/stats?days=$days');
    final status = resp.statusCode;
    Map<String, dynamic> data = {};
    
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    
    if (status >= 200 && status < 300) {
      return data;
    }
    
    final message = (data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des statistiques').toString();
    final details = (data['errors'] is Map<String, dynamic>) ? data['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (data.isEmpty ? null : data));
  }
}
