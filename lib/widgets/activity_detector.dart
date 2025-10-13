import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Widget qui détecte l'activité utilisateur et enregistre chaque interaction
/// pour réinitialiser le timer d'inactivité
class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _recordActivity(context),
      onPanDown: (_) => _recordActivity(context),
      onScaleStart: (_) => _recordActivity(context),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _recordActivity(context),
        onPointerMove: (_) => _recordActivity(context),
        onPointerHover: (_) => _recordActivity(context),
        child: child,
      ),
    );
  }

  void _recordActivity(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    authProvider.recordActivity();
  }
}
