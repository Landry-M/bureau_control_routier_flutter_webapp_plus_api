import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({required this.baseUrl, this.defaultHeaders = const {}});

  bool get _isPhpEntry => baseUrl.trim().toLowerCase().endsWith('.php');

  Uri _uri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final normalized = path.startsWith('/') ? path : '/$path';
    if (_isPhpEntry) {
      final base = Uri.parse(baseUrl);
      final existing = Map<String, String>.from(base.queryParameters);
      return base.replace(
        queryParameters: {
          ...existing,
          'route': normalized,
        },
      );
    }
    return Uri.parse('$baseUrl$normalized');
  }

  Future<http.Response> postJson(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final uri = _uri(path);
    final allHeaders = {
      'Content-Type': 'application/json',
      ...defaultHeaders,
      if (headers != null) ...headers,
    };
    return await http.post(uri, headers: allHeaders, body: jsonEncode(body));
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final uri = _uri(path);
    final allHeaders = {
      ...defaultHeaders,
      if (headers != null) ...headers,
    };
    return await http.get(uri, headers: allHeaders);
  }

  /// Multipart POST for file uploads (e.g., images)
  Future<http.Response> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      ...defaultHeaders,
      if (headers != null) ...headers,
    });
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return response;
  }
}
