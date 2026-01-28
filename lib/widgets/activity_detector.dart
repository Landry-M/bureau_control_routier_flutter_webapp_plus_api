import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Widget qui détecte l'activité utilisateur et enregistre chaque interaction
/// pour réinitialiser le timer d'inactivité.
/// Utilise un throttling pour éviter les appels trop fréquents (pointerMove/hover).
class ActivityDetector extends StatefulWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  State<ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector> {
  DateTime? _lastActivityTime;
  static const Duration _throttleDuration = Duration(seconds: 5);

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
        onPointerMove: (_) => _recordActivityThrottled(context),
        onPointerHover: (_) => _recordActivityThrottled(context),
        child: widget.child,
      ),
    );
  }

  void _recordActivity(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    authProvider.recordActivity();
    _lastActivityTime = DateTime.now();
  }

  void _recordActivityThrottled(BuildContext context) {
    final now = DateTime.now();
    if (_lastActivityTime == null ||
        now.difference(_lastActivityTime!) >= _throttleDuration) {
      _recordActivity(context);
    }
  }
}
