import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'api_client.dart';

class ContraventionService {
  final ApiClient client;
  ContraventionService(this.client);

  Future<Map<String, dynamic>> createJson(Map<String, dynamic> payload) async {
    final resp = await client.postJson('/contravention/create', payload);
    final status = resp.statusCode;
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (status >= 200 && status < 300) return data;
    throw Exception(data['message'] ?? 'Erreur lors de la création de la contravention');
  }

  Future<Map<String, dynamic>> createWithPhotos({
    required Map<String, String> fields,
    List<PlatformFile> photos = const [],
  }) async {
    final files = <http.MultipartFile>[];
    for (final f in photos) {
      if (f.bytes != null) {
        files.add(http.MultipartFile.fromBytes(
          'photos[]',
          f.bytes!,
          filename: f.name,
          contentType: _guessContentType(f.name),
        ));
      }
    }
    final resp = await client.postMultipart(
      '/contravention/create',
      fields: fields,
      files: files,
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      return {'state': true};
    }
    throw Exception('Erreur HTTP ${resp.statusCode}: ${resp.body}');
  }
}

MediaType? _guessContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return MediaType('image', 'jpeg');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  return null;
}
