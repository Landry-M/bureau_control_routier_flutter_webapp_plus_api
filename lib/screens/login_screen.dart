import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(
      matricule: _matriculeController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      // Redirect handled by router guard; navigate explicitly as well for UX
      context.go('/dashboard');
    } else {
      final msg = auth.error ?? 'Échec de connexion';
      NotificationService.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background emblem/logo with dim overlay
          Opacity(
            opacity: 0.08,
            child: Image.asset(
              'lib/assets/images/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: cs.background.withOpacity(0.6)),

          // Centered login card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'lib/assets/images/logo.png',
                                height: 64,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "BUREAU DE CONTRÔLE ROUTIER",
                                style: tt.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Matricule
                        Text('Matricule', style: tt.labelLarge),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _matriculeController,
                          keyboardType: TextInputType.text,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le matricule est obligatoire'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Veuillez saisir votre matricule…',
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Password
                        Text('Mot de passe', style: tt.labelLarge),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Le mot de passe est obligatoire'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Veuillez saisir votre mot de passe…',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: loading ? null : () {},
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Mot de passe oublié ?'),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: loading ? null : _submit,
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('CONNEXION'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
