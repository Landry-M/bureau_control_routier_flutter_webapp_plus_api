import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service pour vérifier les horaires de connexion en cours de session
class SessionScheduleService {
  /// Vérifie si l'utilisateur est toujours autorisé selon ses horaires
  static Future<SessionScheduleCheck> checkSchedule({
    String? userId,
    String? matricule,
  }) async {
    if (userId == null && matricule == null) {
      return SessionScheduleCheck(
        success: false,
        authorized: false,
        message: 'user_id ou matricule requis',
      );
    }

    try {
      final params = <String, String>{};
      if (userId != null) params['user_id'] = userId;
      if (matricule != null) params['matricule'] = matricule;

      final uri = Uri.parse('${ApiConfig.baseUrl}/check_session_schedule.php')
          .replace(queryParameters: params);

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return http.Response(
            json.encode({'success': false, 'authorized': true, 'message': 'Timeout'}),
            408,
          );
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SessionScheduleCheck.fromJson(data);
      } else {
        // En cas d'erreur serveur, autoriser par défaut pour ne pas bloquer l'utilisateur
        return SessionScheduleCheck(
          success: false,
          authorized: true,
          message: 'Erreur serveur: ${response.statusCode}',
        );
      }
    } catch (e) {
      // En cas d'erreur réseau, autoriser par défaut
      return SessionScheduleCheck(
        success: false,
        authorized: true,
        message: 'Erreur de connexion: $e',
      );
    }
  }
}

/// Résultat de la vérification des horaires
class SessionScheduleCheck {
  final bool success;
  final bool authorized;
  final String message;
  final String? reason;
  final String? currentTime;
  final int? currentDay;

  SessionScheduleCheck({
    required this.success,
    required this.authorized,
    required this.message,
    this.reason,
    this.currentTime,
    this.currentDay,
  });

  factory SessionScheduleCheck.fromJson(Map<String, dynamic> json) {
    return SessionScheduleCheck(
      success: json['success'] == true,
      authorized: json['authorized'] == true,
      message: json['message'] ?? '',
      reason: json['reason'],
      currentTime: json['current_time'],
      currentDay: json['current_day'],
    );
  }
}
