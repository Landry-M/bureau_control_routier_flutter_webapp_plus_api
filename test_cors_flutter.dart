import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script de test CORS pour Flutter
/// Teste si l'API accepte les requêtes cross-origin depuis Flutter
class CorsTestService {
  static const String baseUrl = 'http://localhost:8000/api/routes/index.php';
  
  /// Test CORS basique
  static Future<void> testBasicCors() async {
    print('🧪 Test CORS Basique...');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test_cors.php'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ CORS Basique: SUCCÈS');
        print('📄 Réponse: ${data['message']}');
        print('🕒 Timestamp: ${data['timestamp']}');
      } else {
        print('❌ CORS Basique: ÉCHEC');
        print('📄 Status: ${response.statusCode}');
        print('📄 Body: ${response.body}');
      }
    } catch (e) {
      print('❌ CORS Basique: ERREUR');
      print('📄 Erreur: $e');
    }
    
    print('');
  }
  
  /// Test CORS avec headers d'authentification
  static Future<void> testCorsWithAuth() async {
    print('🧪 Test CORS avec Headers Auth...');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/test_cors.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-token',
          'X-Auth-Token': 'test-auth-token',
        },
        body: jsonEncode({'test': 'cors_with_auth'}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ CORS avec Auth: SUCCÈS');
        print('📄 Réponse: ${data['message']}');
      } else {
        print('❌ CORS avec Auth: ÉCHEC');
        print('📄 Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ CORS avec Auth: ERREUR');
      print('📄 Erreur: $e');
    }
    
    print('');
  }
  
  /// Test endpoint de login
  static Future<void> testLoginEndpoint() async {
    print('🧪 Test Endpoint Login...');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'matricule': 'test',
          'password': 'test',
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 400 || response.statusCode == 401) {
        print('✅ Login Endpoint: ACCESSIBLE (credentials invalides attendus)');
        print('📄 Message: ${data['message']}');
      } else if (response.statusCode == 200) {
        print('✅ Login Endpoint: SUCCÈS (credentials valides)');
        print('📄 Token: ${data['token']}');
      } else {
        print('❌ Login Endpoint: RÉPONSE INATTENDUE');
        print('📄 Status: ${response.statusCode}');
        print('📄 Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Login Endpoint: ERREUR CORS');
      print('📄 Erreur: $e');
    }
    
    print('');
  }
  
  /// Test requête OPTIONS (preflight)
  static Future<void> testOptionsRequest() async {
    print('🧪 Test Requête OPTIONS...');
    
    try {
      final client = HttpClient();
      final request = await client.openUrl('OPTIONS', Uri.parse('$baseUrl/test_cors.php'));
      request.headers.set('Content-Type', 'application/json');
      
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ OPTIONS Request: SUCCÈS');
        print('📄 Status: ${response.statusCode}');
        
        // Lire les headers CORS
        final corsOrigin = response.headers.value('access-control-allow-origin');
        final corsMethods = response.headers.value('access-control-allow-methods');
        final corsHeaders = response.headers.value('access-control-allow-headers');
        
        print('📄 CORS Origin: $corsOrigin');
        print('📄 CORS Methods: $corsMethods');
        print('📄 CORS Headers: $corsHeaders');
      } else {
        print('❌ OPTIONS Request: ÉCHEC');
        print('📄 Status: ${response.statusCode}');
      }
      
      client.close();
    } catch (e) {
      print('❌ OPTIONS Request: ERREUR');
      print('📄 Erreur: $e');
    }
    
    print('');
  }
  
  /// Exécute tous les tests
  static Future<void> runAllTests() async {
    print('🚀 Démarrage des tests CORS pour BCR API');
    print('🌐 URL de base: $baseUrl');
    print('=' * 50);
    print('');
    
    await testBasicCors();
    await testCorsWithAuth();
    await testOptionsRequest();
    await testLoginEndpoint();
    
    print('=' * 50);
    print('✨ Tests CORS terminés');
    print('');
    print('📋 Instructions:');
    print('1. Si tous les tests passent, CORS est correctement configuré');
    print('2. Si des erreurs apparaissent, vérifiez:');
    print('   - Que le serveur PHP est démarré (php -S localhost:8000)');
    print('   - Que l\'URL de base est correcte');
    print('   - Que les fichiers .htaccess et index.php sont à jour');
    print('');
  }
}

/// Point d'entrée pour exécuter les tests
void main() async {
  await CorsTestService.runAllTests();
}
