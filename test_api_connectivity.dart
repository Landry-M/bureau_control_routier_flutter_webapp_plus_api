import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Test de connectivité API ===');
  
  // URLs à tester
  final urls = [
    'http://localhost:8000/api/routes/index.php?route=/logs&limit=5&offset=0',
    'http://10.0.2.2:8000/api/routes/index.php?route=/logs&limit=5&offset=0',
  ];
  
  for (final url in urls) {
    print('\n--- Test de: $url ---');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        print('✅ Connexion réussie!');
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Erreur de connexion: $e');
    }
  }
  
  print('\n=== Fin du test ===');
}
