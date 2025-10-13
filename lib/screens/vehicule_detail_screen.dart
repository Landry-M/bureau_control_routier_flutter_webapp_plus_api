import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/top_bar.dart';
import '../utils/responsive.dart';
import '../services/vehicule_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/vehicule_actions_modal.dart';
import '../widgets/vehicule_details_modal.dart';
import '../widgets/edit_vehicule_modal.dart';
import '../widgets/retirer_plaque_modal.dart';
import '../widgets/plaque_temporaire_modal.dart';
import '../widgets/transfert_proprietaire_modal.dart';
import '../widgets/emettre_avis_recherche_modal.dart';
import '../config/api_config.dart';
import 'package:toastification/toastification.dart';

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
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() { _error = errorMessage; _loading = false; });
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
                    if (_veh != null) ...[
                      // Bouton voir détails complets
                      IconButton(
                        tooltip: 'Voir détails complets',
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showVehiculeDetails(_veh!),
                      ),
                      // Bouton modifier (superadmin uniquement)
                      if (isSuper)
                        IconButton(
                          tooltip: 'Modifier',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditModal(_veh!),
                        ),
                      // Bouton actions
                      ElevatedButton.icon(
                        onPressed: () => _showActionsModal(_veh!),
                        icon: const Icon(Icons.more_vert),
                        label: const Text('Actions'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ]
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

  // Afficher la modal de détails complets
  void _showVehiculeDetails(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) => VehiculeDetailsModal(vehicule: vehicule),
    );
  }

  // Afficher la modal de modification
  void _showEditModal(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) => EditVehiculeModal(vehicule: vehicule),
    ).then((_) => _load()); // Recharger après modification
  }

  // Afficher la modal d'actions
  void _showActionsModal(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) => VehiculeActionsModal(
        vehicule: vehicule,
        onSanctionner: () {
          Navigator.of(context).pop();
          NotificationService.info(context, 'Assigner une contravention (à implémenter)');
        },
        onChangerProprietaire: () async {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            builder: (context) => TransfertProprietaireModal(vehicule: vehicule),
          );
          _load();
        },
        onRetirerVehicule: () async {
          Navigator.of(context).pop();
          await _retirerVehiculeCirculation(vehicule);
        },
        onRetirerPlaque: () async {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            builder: (context) => RetirerPlaqueModal(vehicule: vehicule),
          );
          _load();
        },
        onPlaqueTemporaire: () async {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            builder: (context) => PlaqueTemporaireModal(vehicule: vehicule),
          );
        },
        onEmettreAvis: () async {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            builder: (context) => EmettreAvisRechercheModal(
              cible: vehicule,
              cibleType: 'vehicule_plaque',
            ),
          );
        },
      ),
    );
  }

  // Retirer le véhicule de la circulation
  Future<void> _retirerVehiculeCirculation(Map<String, dynamic> vehicule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le retrait'),
        content: Text(
          'Voulez-vous vraiment retirer le véhicule ${vehicule['plaque']} de la circulation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final username = context.read<AuthProvider>().username;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/vehicule/${vehicule['id']}/retirer-circulation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Véhicule retiré'),
          description: const Text('Le véhicule a été retiré de la circulation avec succès'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: true,
        );
        _load();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text('Impossible de retirer le véhicule: $e'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
      );
    }
  }
}
