import 'lib/config/api_config.dart';
import 'lib/services/api_client.dart';
import 'lib/services/log_service.dart';

void main() async {
  try {
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    final logService = LogService(apiClient);
    
    final result = await logService.getLogs(limit: 5, offset: 0);
    
    if (result['success'] == true) {
      final logs = result['data'] as List;
      
      for (int i = 0; i < logs.length && i < 3; i++) {
        final log = logs[i];
        print('  - Log ${i + 1}: ${log['action']} par ${log['username']} le ${log['created_at']}');
      }
    } else {
      print('❌ Échec: ${result['message'] ?? 'Erreur inconnue'}');
    }
    
  } catch (e) {
    print('❌ Exception: $e');
  }
}
