import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// Widget qui surveille l'inactivité de l'utilisateur et affiche des avertissements
/// Déconnecte automatiquement l'utilisateur après 30 minutes d'inactivité
class InactivityGuard extends StatefulWidget {
  final Widget child;

  const InactivityGuard({super.key, required this.child});

  @override
  State<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends State<InactivityGuard> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _setupInactivityCallbacks();
  }

  void _setupInactivityCallbacks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      // Callback pour l'avertissement (5 minutes avant déconnexion)
      authProvider.onInactivityWarning = (minutesRemaining) {
        if (!mounted || _dialogShown) return;
        _showInactivityWarning(minutesRemaining);
      };

      // Callback pour la déconnexion automatique
      authProvider.onInactivityTimeout = () {
        if (!mounted) return;
        _handleInactivityTimeout();
      };
    });
  }

  void _showInactivityWarning(int minutesRemaining) {
    if (!mounted || _dialogShown) return;

    setState(() {
      _dialogShown = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Inactivité détectée',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous serez déconnecté dans $minutesRemaining minute${minutesRemaining > 1 ? 's' : ''} en raison d\'une inactivité prolongée.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bougez votre souris ou cliquez pour rester connecté.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _dialogShown = false;
                });
              },
              child: const Text('J\'ai compris'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                authProvider.recordActivity(); // Enregistrer l'activité
                Navigator.of(dialogContext).pop();
                setState(() {
                  _dialogShown = false;
                });
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Rester connecté'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _dialogShown = false;
        });
      }
    });
  }

  void _handleInactivityTimeout() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Afficher un dialogue de déconnexion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Session expirée',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre session a expiré en raison d\'une inactivité de 30 minutes.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Par mesure de sécurité, vous allez être déconnecté.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authProvider.logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Se reconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.onInactivityWarning = null;
    authProvider.onInactivityTimeout = null;
    super.dispose();
  }
}
