import 'package:flutter/material.dart';

import '../widgets/top_bar.dart';
import '../utils/responsive.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/create_agent_modal.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  // Pagination (client-side)
  int _page = 1;
  final int _perPage = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client =
          ApiClient(baseUrl: 'http://localhost/api/routes/index.php');
      final service = UserService(client);
      final result = await service.getUsers();
      final data = (result['data'] is List)
          ? List<Map<String, dynamic>>.from(result['data'])
          : <Map<String, dynamic>>[];
      setState(() {
        _all = data;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _pageItems {
    final start = (_page - 1) * _perPage;
    final end = start + _perPage;
    if (start >= _all.length) return [];
    return _all.sublist(start, end > _all.length ? _all.length : end);
  }

  int get _totalPages => (_all.length / _perPage).ceil().clamp(1, 1000000);

  void _showUserDialog(Map<String, dynamic> u) {
    final role = context.read<AuthProvider>().role;
    final isSuper = role == 'superadmin';
    showDialog(
      context: context,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        bool editing = false;
        final ctrlUsername = TextEditingController(text: (u['username'] ?? u['nom'] ?? '').toString());
        final ctrlMatricule = TextEditingController(text: (u['matricule'] ?? '').toString());
        final ctrlRole = TextEditingController(text: (u['role'] ?? '').toString());
        final ctrlTelephone = TextEditingController(text: (u['telephone'] ?? '').toString());
        String statut = (u['statut'] ?? '').toString();

        Future<void> submitUpdate() async {
          if (!isSuper) return;
          final client = ApiClient(baseUrl: 'http://localhost/api/routes/index.php');
          final svc = UserService(client);
          final id = int.tryParse((u['id'] ?? '').toString());
          if (id == null) {
            NotificationService.error(context, 'ID utilisateur invalide');
            return;
          }
          final payload = {
            'username': ctrlUsername.text,
            'matricule': ctrlMatricule.text,
            'role': ctrlRole.text,
            'telephone': ctrlTelephone.text,
            'statut': statut,
          };
          try {
            await svc.updateUser(id: id, data: payload);
            // update in-memory list
            final idx = _all.indexWhere((e) => (e['id'] ?? '').toString() == id.toString());
            if (idx >= 0) {
              setState(() {
                _all[idx] = {
                  ..._all[idx],
                  ...payload,
                };
              });
            }
            if (mounted) {
              NotificationService.success(context, 'Utilisateur mis à jour');
              Navigator.of(ctx).pop();
            }
          } catch (e) {
            if (mounted) NotificationService.error(context, e.toString());
          }
        }

        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text('Utilisateur ${(u['username'] ?? u['nom'] ?? '').toString()}'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Activer la modification'),
                          const SizedBox(width: 8),
                          Switch(
                            value: editing,
                            onChanged: isSuper ? (v) => setLocal(() => editing = v) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: ctrlUsername,
                        enabled: editing,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: ctrlMatricule,
                        enabled: editing,
                        decoration: const InputDecoration(labelText: 'Matricule'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: ctrlRole,
                        enabled: editing,
                        decoration: const InputDecoration(labelText: 'Rôle'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: ctrlTelephone,
                        enabled: editing,
                        decoration: const InputDecoration(labelText: 'Téléphone'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: statut.isEmpty ? null : statut,
                        items: const [
                          DropdownMenuItem(value: 'actif', child: Text('actif')),
                          DropdownMenuItem(value: 'inactif', child: Text('inactif')),
                        ],
                        onChanged: editing ? (v) => setLocal(() => statut = v ?? statut) : null,
                        decoration: const InputDecoration(labelText: 'Statut'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer'),
              ),
              if (isSuper)
                FilledButton.icon(
                  onPressed: editing ? submitUpdate : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Mettre à jour'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePassword(Map<String, dynamic> u) async {
    final id = int.tryParse((u['id'] ?? '').toString());
    if (id == null) {
      NotificationService.error(context, 'ID utilisateur invalide');
      return;
    }
    final ctrlNew = TextEditingController();
    final ctrlConf = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, controller: ctrlNew, decoration: const InputDecoration(labelText: 'Nouveau mot de passe')),
            const SizedBox(height: 8),
            TextField(obscureText: true, controller: ctrlConf, decoration: const InputDecoration(labelText: 'Confirmer le mot de passe')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mettre à jour')),
        ],
      ),
    );
    if (res != true) return;
    if (ctrlNew.text != ctrlConf.text || ctrlNew.text.isEmpty) {
      NotificationService.error(context, 'Les mots de passe ne correspondent pas');
      return;
    }
    try {
      final client = ApiClient(baseUrl: 'http://localhost/api/routes/index.php');
      final svc = UserService(client);
      await svc.updateUser(id: id, data: {'password': ctrlNew.text});
      NotificationService.success(context, 'Mot de passe mis à jour, première connexion requise');
    } catch (e) {
      NotificationService.error(context, e.toString());
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> u) async {
    final id = int.tryParse((u['id'] ?? '').toString());
    if (id == null) {
      NotificationService.error(context, 'ID utilisateur invalide');
      return;
    }
    final current = (u['statut'] ?? 'actif').toString();
    final next = current == 'actif' ? 'inactif' : 'actif';
    try {
      final client = ApiClient(baseUrl: 'http://localhost/api/routes/index.php');
      final svc = UserService(client);
      await svc.updateUser(id: id, data: {'statut': next});
      setState(() {
        final idx = _all.indexWhere((e) => (e['id'] ?? '').toString() == id.toString());
        if (idx >= 0) {
          _all[idx] = {..._all[idx], 'statut': next};
        }
      });
      NotificationService.success(context, 'Statut mis à jour: $next');
    } catch (e) {
      NotificationService.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
                vertical: Responsive.value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
              ),
              children: [
                const TopBar(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Utilisateurs', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (!_loading) Text('${_all.length} résultat(s)', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Actualiser',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(child: Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)))
                else if (_all.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: [
                        const Icon(Icons.inbox),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Aucun utilisateur trouvé.', style: tt.bodyMedium)),
                      ]),
                    ),
                  )
                else ...[
                  Card(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Matricule')),
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text('Rôle')),
                        DataColumn(label: Text('Téléphone')),
                        DataColumn(label: Text('Statut')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _pageItems.map((u) {
                        return DataRow(cells: [
                          DataCell(Text((u['id'] ?? '').toString())),
                          DataCell(Text((u['matricule'] ?? '').toString())),
                          DataCell(Text((u['username'] ?? u['nom'] ?? '').toString())),
                          DataCell(Text((u['role'] ?? '').toString())),
                          DataCell(Text((u['telephone'] ?? '').toString())),
                          DataCell(Text((u['statut'] ?? '').toString())),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Voir / Modifier',
                                icon: const Icon(Icons.remove_red_eye),
                                onPressed: () => _showUserDialog(u),
                              ),
                              IconButton(
                                tooltip: 'Modifier mot de passe',
                                icon: const Icon(Icons.key),
                                onPressed: () => _changePassword(u),
                              ),
                              IconButton(
                                tooltip: (u['statut'] ?? 'actif') == 'actif' ? 'Bloquer' : 'Débloquer',
                                icon: Icon((u['statut'] ?? 'actif') == 'actif' ? Icons.lock : Icons.lock_open),
                                onPressed: () => _toggleBlock(u),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed:
                              _page > 1 ? () => setState(() => _page--) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('$_page / $_totalPages'),
                        IconButton(
                          onPressed: _page < _totalPages
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading
            ? null
            : () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const CreateAgentModal(),
                );
                if (result != null && mounted) {
                  NotificationService.success(
                    context,
                    'Agent ${result['nom'] ?? ''} créé avec succès !',
                  );
                  await _load();
                }
              },
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel agent'),
      ),
    );
  }
}
