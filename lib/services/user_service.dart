import 'dart:convert';

import 'api_client.dart';
import 'api_exception.dart';

class UserService {
  final ApiClient client;

  UserService(this.client);

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final resp = await client.postJson('/users/create', userData);
    final status = resp.statusCode;
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (status >= 200 && status < 300) return body;

    final message = (body['message'] ?? body['error'] ?? 'Erreur lors de la création de l\'agent').toString();
    final details = (body['errors'] is Map<String, dynamic>) ? body['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (body.isEmpty ? null : body));
  }

  Future<Map<String, dynamic>> getUsers() async {
    final resp = await client.get('/users');
    final status = resp.statusCode;
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (status >= 200 && status < 300) return body;

    final message = (body['message'] ?? body['error'] ?? 'Erreur lors de la récupération des utilisateurs').toString();
    final details = (body['errors'] is Map<String, dynamic>) ? body['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (body.isEmpty ? null : body));
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final resp = await client.postJson('/users/$id/update', data);
    final status = resp.statusCode;
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (status >= 200 && status < 300) return body;

    final message = (body['message'] ?? body['error'] ?? 'Erreur lors de la mise à jour de l\'utilisateur').toString();
    final details = (body['errors'] is Map<String, dynamic>) ? body['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (body.isEmpty ? null : body));
  }
}
