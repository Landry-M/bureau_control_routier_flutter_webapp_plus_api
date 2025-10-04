import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/top_bar.dart';
import '../utils/responsive.dart';
import '../services/vehicule_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

class VehiculeDetailScreen extends StatefulWidget {
  const VehiculeDetailScreen({super.key, required this.id});

  // For now, 'id' is interpreted as plaque (string)
  final String id;

  @override
  State<VehiculeDetailScreen> createState() => _VehiculeDetailScreenState();
}

class _VehiculeDetailScreenState extends State<VehiculeDetailScreen> {
  final _service = VehiculeService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _veh;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      Map<String, dynamic>? data;
      final numeric = int.tryParse(widget.id);
      if (numeric != null) {
        data = await _service.getVehiculeById(numeric);
      }
      data ??= await _service.searchPlaque(widget.id);
      setState(() { _veh = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final role = context.watch<AuthProvider>().role;
    final isSuper = role == 'superadmin';

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
                    IconButton(
                      tooltip: 'Retour',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('Détail véhicule', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            if (isSuper) {
                              NotificationService.info(context, 'Modifier véhicule (à implémenter)');
                            }
                            break;
                          case 'assign_cv':
                            NotificationService.info(context, 'Assigner une contravention (à implémenter)');
                            break;
                        }
                      },
                      itemBuilder: (_) {
                        final items = <PopupMenuEntry<String>>[];
                        if (isSuper) {
                          items.add(const PopupMenuItem(value: 'edit', child: Text('Modifier les informations')));
                          items.add(const PopupMenuDivider());
                        }
                        items.add(const PopupMenuItem(value: 'assign_cv', child: Text('Assigner une contravention')));
                        return items;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.more_vert),
                            SizedBox(width: 4),
                            Text('Actions'),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(child: Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)))
                else if (_veh == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: [
                        const Icon(Icons.error_outline),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Véhicule introuvable pour "${widget.id}".', style: tt.bodyMedium)),
                      ]),
                    ),
                  )
                else ...[
                  _buildOverviewCard(tt, cs, _veh!),
                  const SizedBox(height: 12),
                  _buildFieldsCard(tt, cs, _veh!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(TextTheme tt, ColorScheme cs, Map<String, dynamic> v) {
    final plaque = (v['plaque'] ?? v['plate'] ?? '').toString();
    final marque = (v['marque'] ?? '').toString();
    final modele = (v['modele'] ?? '').toString();
    final couleur = (v['couleur'] ?? '').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_car, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plaque.isNotEmpty ? plaque : 'Plaque inconnue', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text([
                    if (marque.isNotEmpty) marque,
                    if (modele.isNotEmpty) modele,
                    if (couleur.isNotEmpty) couleur,
                  ].join(' · ')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsCard(TextTheme tt, ColorScheme cs, Map<String, dynamic> v) {
    final entries = v.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 200, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value?.toString() ?? '')),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
