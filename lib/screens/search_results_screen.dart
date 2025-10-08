import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../widgets/top_bar.dart';
import '../services/vehicule_service.dart';
import '../services/global_search_service.dart';
import '../widgets/vehicule_details_modal.dart';
import '../widgets/particulier_details_modal.dart';
import '../widgets/particulier_actions_modal.dart';
import '../widgets/assign_contravention_particulier_modal.dart';
import '../widgets/generer_permis_temporaire_modal.dart';
import '../widgets/consigner_arrestation_modal.dart';
import '../widgets/emettre_avis_recherche_modal.dart';
import '../widgets/associer_vehicule_modal.dart';
import '../widgets/entreprise_details_modal.dart';
import '../widgets/assign_contravention_entreprise_modal.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.query = '', this.type = 'general'});

  final String query; // from query params
  final String type;  // 'general' | 'plate'

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _vehiculeService = VehiculeService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  // pagination (client-side)
  int _page = 1;
  final int _perPage = 10;

  List<Map<String, dynamic>> get _pageItems {
    final start = (_page - 1) * _perPage;
    final end = start + _perPage;
    return _all.sublist(start, end.clamp(0, _all.length));
  }

  int get _totalPages => (_all.length / _perPage).ceil().clamp(1, 1000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    if (widget.query.isEmpty) return;
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.type == 'plate') {
        final results = await _vehiculeService.searchByPlaque(widget.query);
        setState(() {
          _all = List<Map<String, dynamic>>.from(results);
          _loading = false;
        });
      } else {
        final results = await GlobalSearchService.search(widget.query);
        setState(() {
          if (results['success'] == true && results['data'] is List) {
            _all = List<Map<String, dynamic>>.from(results['data']);
          } else {
            _all = [];
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Widget _buildGlobalSearchItem(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? 'unknown';
    final typeLabel = item['type_label'] as String? ?? 'Inconnu';
    final title = item['title'] as String? ?? 'Sans titre';
    final subtitle = item['subtitle'] as String? ?? '';
    final createdAt = item['created_at'] as String?;
    final itemData = item['data'] as Map<String, dynamic>? ?? {};
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icône et informations principales
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(type),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Contenu principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Créé le: ${_formatDate(createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Boutons d'actions
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Détails
              IconButton(
                onPressed: () => _showEntityDetails(type, itemData.isNotEmpty ? itemData : item),
                icon: const Icon(Icons.visibility),
                tooltip: 'Voir détails',
              ),
              // Bouton Actions supplémentaires (selon le type)
              if (_shouldShowActionsButton(type))
                _buildActionsButton(type, itemData),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(Map<String, dynamic> item) {
    final plaque = (item['plaque'] ?? item['plate'] ?? '').toString();
    final marque = (item['marque'] ?? '').toString();
    final modele = (item['modele'] ?? '').toString();
    final couleur = (item['couleur'] ?? '').toString();
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.directions_car, color: Colors.orange),
      ),
      title: Text('$plaque - $marque $modele'),
      subtitle: Text('Couleur: $couleur'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showEntityDetails('vehicule', item),
            icon: const Icon(Icons.visibility),
            tooltip: 'Voir détails',
          ),
          _buildActionsButton('vehicule', item),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'vehicule':
        return Icons.directions_car;
      case 'particulier':
        return Icons.person;
      case 'entreprise':
        return Icons.business;
      case 'contravention':
        return Icons.receipt;
      case 'accident':
        return Icons.warning;
      case 'arrestation':
        return Icons.security;
      case 'avis_recherche':
        return Icons.search;
      case 'permis_temporaire':
        return Icons.card_membership;
      default:
        return Icons.help_outline;
    }
  }

  // Méthodes pour gérer les actions selon le type d'entité
  bool _shouldShowActionsButton(String type) {
    return ['vehicule', 'particulier', 'entreprise'].contains(type);
  }

  Widget _buildActionsButton(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'vehicule':
        return IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.orange),
          tooltip: 'Actions véhicule',
          onPressed: () => _showActionsMenu(type, data),
        );
      case 'particulier':
        return IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.green),
          tooltip: 'Actions particulier',
          onPressed: () => _showActionsMenu(type, data),
        );
      case 'entreprise':
        return IconButton(
          icon: const Icon(Icons.assignment, color: Colors.indigo),
          tooltip: 'Assigner contravention',
          onPressed: () => _showEntrepriseActions(data),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showEntityDetails(String type, Map<String, dynamic> data) {
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: const Text('ID manquant pour afficher les détails'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    switch (type) {
      case 'vehicule':
        showDialog(
          context: context,
          builder: (context) => VehiculeDetailsModal(vehicule: data),
        );
        break;
      case 'particulier':
        showDialog(
          context: context,
          builder: (context) => ParticulierDetailsModal(particulier: data),
        );
        break;
      case 'entreprise':
        showDialog(
          context: context,
          builder: (context) => EntrepriseDetailsModal(entreprise: data),
        );
        break;
      default:
        _showDetails({'data': data});
    }
  }

  void _showActionsMenu(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'particulier':
        showDialog(
          context: context,
          builder: (context) => ParticulierActionsModal(
            particulier: data,
            onEmettrePermis: () => _showEmettrePermisModal(data),
            onAssocierVehicule: () => _showAssocierVehiculeModal(data),
            onCreerContravention: () => _showCreerContraventionModal(data),
            onConsignerArrestation: () => _showConsignerArrestationModal(data),
            onEmettreAvisRecherche: () => _showEmettreAvisRechercheModal(data),
          ),
        );
        break;
      case 'vehicule':
        // Actions véhicule à implémenter
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          title: const Text('Information'),
          description: const Text('Actions véhicule à implémenter'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
        break;
      default:
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          title: const Text('Information'),
          description: Text('Actions pour $type à implémenter'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
    }
  }

  void _showEntrepriseActions(Map<String, dynamic> entreprise) {
    showDialog(
      context: context,
      builder: (context) => AssignContraventionEntrepriseModal(
        dossier: entreprise,
      ),
    ).then((result) {
      if (result == true) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Succès'),
          description: const Text('Contravention assignée avec succès'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    });
  }

  // Méthodes pour les actions particulier
  void _showEmettrePermisModal(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => GenererPermisTemporaireModal(
        particulier: particulier,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: const Text('Permis temporaire généré avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  void _showAssocierVehiculeModal(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => AssocierVehiculeModal(
        particulier: particulier,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: const Text('Véhicule associé avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  void _showCreerContraventionModal(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => AssignContraventionParticulierModal(
        particulier: particulier,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: const Text('Contravention créée avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  void _showConsignerArrestationModal(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => ConsignerArrestationModal(
        particulier: particulier,
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: const Text('Arrestation consignée avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  void _showEmettreAvisRechercheModal(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => EmettreAvisRechercheModal(
        cible: particulier,
        cibleType: 'particuliers',
        onSuccess: () {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: const Text('Avis de recherche émis avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  void _showDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in item.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text('${entry.value}'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec titre et query
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.type == 'plate' 
                                ? 'Recherche de plaque'
                                : 'Recherche globale',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.query.isNotEmpty)
                              Text(
                                'Résultats pour: "${widget.query}"',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Résultats
                  Expanded(
                    child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _all.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error != null 
                                    ? 'Erreur: $_error'
                                    : 'Aucun résultat trouvé',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Compteur de résultats
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_all.length} résultat${_all.length > 1 ? 's' : ''} trouvé${_all.length > 1 ? 's' : ''}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Liste des résultats
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _pageItems.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      return widget.type == 'general'
                                          ? _buildGlobalSearchItem(_pageItems[index])
                                          : _buildVehicleItem(_pageItems[index]);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_totalPages > 1)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _page > 1 ? () => setState(() => _page--) : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text('Page $_page sur $_totalPages'),
                                    IconButton(
                                      onPressed: _page < _totalPages ? () => setState(() => _page++) : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
