import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    if (role != 'superadmin') {
      return const Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: const Center(child: Text('LogsScreen (stub)')),
    );
  }
}
