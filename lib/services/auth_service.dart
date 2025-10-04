import 'dart:convert';

import 'api_client.dart';
import 'api_exception.dart';

class AuthService {
  final ApiClient client;
  AuthService(this.client);

  Future<Map<String, dynamic>> login({required String matricule, required String password}) async {
    final resp = await client.postJson('/auth/login', {
      'matricule': matricule,
      'password': password,
    });
    final status = resp.statusCode;
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (status >= 200 && status < 300) {
      return data;
    }
    final message = (data['message'] ?? data['error'] ?? 'Échec de connexion').toString();
    final details = (data['errors'] is Map<String, dynamic>) ? data['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (data.isEmpty ? null : data));
  }

  Future<Map<String, dynamic>> completeFirstConnection({
    required String userId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final resp = await client.postJson('/auth/first-connection', {
      'user_id': userId,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    final status = resp.statusCode;
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (status >= 200 && status < 300) {
      return data;
    }
    final message = (data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour du mot de passe').toString();
    final details = (data['errors'] is Map<String, dynamic>) ? data['errors'] as Map<String, dynamic> : null;
    throw ApiException(statusCode: status, message: message, details: details ?? (data.isEmpty ? null : data));
  }
}
