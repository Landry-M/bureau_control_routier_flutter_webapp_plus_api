import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

/// Widget qui surveille les horaires de connexion
/// et déconnecte automatiquement l'utilisateur si nécessaire
class ScheduleGuard extends StatefulWidget {
  final Widget child;

  const ScheduleGuard({super.key, required this.child});

  @override
  State<ScheduleGuard> createState() => _ScheduleGuardState();
}

class _ScheduleGuardState extends State<ScheduleGuard> {
  @override
  void initState() {
    super.initState();
    _setupScheduleViolationHandler();
  }

  void _setupScheduleViolationHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        // Définir UNIQUEMENT le callback de violation des horaires
        // (InactivityGuard gère onInactivityTimeout pour éviter l'écrasement)
        authProvider.onScheduleViolation = () {
          if (mounted) {
            _handleScheduleViolation();
          }
        };
      }
    });
  }

  void _handleScheduleViolation() {
    final authProvider = context.read<AuthProvider>();

    // Afficher une notification
    NotificationService.warning(
      context,
      'Vous avez été déconnecté car vous êtes en dehors de vos heures de travail autorisées.',
      title: 'Session expirée',
      duration: const Duration(seconds: 6),
    );

    // Déconnexion
    authProvider.logout().then((_) {
      if (mounted) {
        // Rediriger vers la page de connexion
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
