import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/global_search_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/top_bar.dart';

class SearchDetailsScreen extends StatefulWidget {
  final String type;
  final int id;
  final String title;

  const SearchDetailsScreen({
    super.key,
    required this.type,
    required this.id,
    required this.title,
  });

  @override
  State<SearchDetailsScreen> createState() => _SearchDetailsScreenState();
}

class _SearchDetailsScreenState extends State<SearchDetailsScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final response = await GlobalSearchService.getDetails(
        widget.type,
        widget.id,
        username: username,
      );

      if (response['success'] == true) {
        setState(() {
          _details = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: Column(
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Icon(_getIconForType(widget.type), color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              _getTypeLabel(widget.type),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu
                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des détails...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_details == null) {
      return const Center(
        child: Text('Aucun détail disponible'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Données principales
          _buildMainDataSection(context),
          
          const SizedBox(height: 24),
          
          // Données liées
          _buildRelatedDataSection(context),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMainDataSection(BuildContext context) {
    final theme = Theme.of(context);
    final mainData = _details!['main_data'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations principales',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDataTable(context, mainData),
        ],
      ),
    );
  }

  Widget _buildRelatedDataSection(BuildContext context) {
    final theme = Theme.of(context);
    final relatedData = _details!['related_data'] as Map<String, dynamic>;

    if (relatedData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Données liées',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...relatedData.entries.map((entry) {
          return _buildRelatedDataTable(context, entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildRelatedDataTable(BuildContext context, String key, dynamic value) {
    final theme = Theme.of(context);

    if (value == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForRelatedData(key),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getRelatedDataTitle(key),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (value is List)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${value.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tableau
          if (value is List) ...[
            if (value.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune donnée',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildDataTableForList(context, key, value),
          ] else if (value is Map<String, dynamic>) ...[
            _buildDataTableForMap(context, value),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data.entries.where((entry) => entry.value != null).map((entry) {
        return SizedBox(
          width: _getFieldWidth(entry.key),
          child: _buildDataField(context, entry.key, entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildDataTableForList(BuildContext context, String key, List items) {
    final theme = Theme.of(context);
    
    // Déterminer les colonnes selon le type de données
    final columns = _getColumnsForType(key);
    
    // Largeur de base pour chaque unité de flex
    final baseWidth = 80.0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowHeight: 56,
              headingRowColor: MaterialStateProperty.all(
                theme.colorScheme.surfaceContainer.withOpacity(0.5),
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 80,
              columns: columns.map((col) {
                final flex = col['flex'] as int;
                final columnWidth = baseWidth * flex;
                
                return DataColumn(
                  label: SizedBox(
                    width: columnWidth,
                    child: Text(
                      col['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                );
              }).toList(),
              rows: items.map((item) {
                return _buildDataRowForType(context, key, item as Map<String, dynamic>, columns, baseWidth);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableForMap(BuildContext context, Map<String, dynamic> data) {
    return _buildDataTable(context, data);
  }

  Widget _buildDataField(BuildContext context, String key, dynamic value) {
    final theme = Theme.of(context);
    final label = _getFieldLabel(key);
    final displayValue = _formatFieldValue(key, value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  double _getFieldWidth(String key) {
    switch (key) {
      case 'id':
        return 100;
      case 'plaque':
      case 'rccm':
      case 'telephone':
      case 'gsm':
        return 180;
      case 'nom':
      case 'designation':
      case 'marque':
      case 'modele':
        return 200;
      case 'adresse':
      case 'siege_social':
      case 'type_infraction':
      case 'lieu':
        return 300;
      case 'description':
      case 'observations':
        return 400;
      default:
        return 180;
    }
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'id':
        return 'ID';
      case 'plaque':
        return 'Plaque';
      case 'marque':
        return 'Marque';
      case 'modele':
        return 'Modèle';
      case 'couleur':
        return 'Couleur';
      case 'proprietaire':
        return 'Propriétaire';
      case 'nom':
        return 'Nom';
      case 'adresse':
        return 'Adresse';
      case 'gsm':
        return 'Téléphone';
      case 'email':
        return 'Email';
      case 'designation':
        return 'Désignation';
      case 'rccm':
        return 'RCCM';
      case 'siege_social':
        return 'Siège social';
      case 'telephone':
        return 'Téléphone';
      case 'type_infraction':
        return 'Type d\'infraction';
      case 'lieu':
        return 'Lieu';
      case 'description':
        return 'Description';
      case 'amende':
        return 'Amende';
      case 'payed':
        return 'Payé';
      case 'gravite':
        return 'Gravité';
      case 'date_accident':
        return 'Date accident';
      case 'date_infraction':
        return 'Date infraction';
      case 'created_at':
        return 'Créé le';
      case 'updated_at':
        return 'Modifié le';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    if (value == null) return 'N/A';
    
    if (key.contains('date') || key.contains('created_at') || key.contains('updated_at')) {
      try {
        final date = DateTime.parse(value.toString());
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        return value.toString();
      }
    }
    
    if (key == 'payed') {
      return value.toString() == 'oui' ? 'Oui' : 'Non';
    }
    
    if (key == 'amende') {
      return '${value} FC';
    }
    
    return value.toString();
  }

  String _getRelatedDataTitle(String key) {
    switch (key) {
      case 'conducteur':
        return 'Conducteur';
      case 'vehicules':
        return 'Véhicules';
      case 'contraventions':
        return 'Contraventions';
      case 'assurances':
        return 'Assurances';
      case 'arrestations':
        return 'Arrestations';
      case 'temoins':
        return 'Témoins';
      case 'plaques_temporaires':
        return 'Plaques temporaires';
      case 'avis_recherche':
        return 'Avis de recherche';
      case 'vehicule':
        return 'Véhicule concerné';
      case 'particulier':
        return 'Particulier concerné';
      case 'entreprise':
        return 'Entreprise concernée';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getIconForRelatedData(String key) {
    switch (key) {
      case 'conducteur':
        return Icons.person_outline;
      case 'vehicules':
        return Icons.directions_car;
      case 'contraventions':
        return Icons.receipt_long;
      case 'assurances':
        return Icons.security;
      case 'arrestations':
        return Icons.local_police;
      case 'temoins':
        return Icons.people_outline;
      case 'plaques_temporaires':
        return Icons.access_time;
      case 'avis_recherche':
        return Icons.search;
      default:
        return Icons.table_chart;
    }
  }

  List<Map<String, dynamic>> _getColumnsForType(String key) {
    switch (key) {
      case 'contraventions':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Date', 'flex': 2, 'field': 'date_infraction'},
          {'label': 'Type', 'flex': 3, 'field': 'type_infraction'},
          {'label': 'Lieu', 'flex': 2, 'field': 'lieu'},
          {'label': 'Amende', 'flex': 2, 'field': 'amende'},
          {'label': 'Payé', 'flex': 1, 'field': 'payed'},
        ];
      case 'assurances':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Compagnie', 'flex': 3, 'field': 'societe_assurance'},
          {'label': 'Police', 'flex': 2, 'field': 'nume_assurance'},
          {'label': 'Début', 'flex': 2, 'field': 'date_valide_assurance'},
          {'label': 'Fin', 'flex': 2, 'field': 'date_expire_assurance'},
          {'label': 'Prime', 'flex': 2, 'field': 'montant_prime'},
        ];
      case 'arrestations':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Date', 'flex': 2, 'field': 'date_arrestation'},
          {'label': 'Motif', 'flex': 3, 'field': 'motif'},
          {'label': 'Lieu', 'flex': 2, 'field': 'lieu'},
          {'label': 'Statut', 'flex': 2, 'field': 'statut'},
        ];
      case 'plaques_temporaires':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Numéro', 'flex': 2, 'field': 'numero'},
          {'label': 'Début', 'flex': 2, 'field': 'date_debut'},
          {'label': 'Fin', 'flex': 2, 'field': 'date_fin'},
          {'label': 'Statut', 'flex': 2, 'field': 'statut'},
        ];
      case 'temoins':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Nom', 'flex': 3, 'field': 'nom'},
          {'label': 'Téléphone', 'flex': 2, 'field': 'telephone'},
          {'label': 'Âge', 'flex': 1, 'field': 'age'},
          {'label': 'Lien', 'flex': 2, 'field': 'lien_avec_accident'},
        ];
      case 'avis_recherche':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Motif', 'flex': 3, 'field': 'motif'},
          {'label': 'Niveau', 'flex': 2, 'field': 'niveau'},
          {'label': 'Statut', 'flex': 2, 'field': 'statut'},
          {'label': 'Date', 'flex': 2, 'field': 'created_at'},
        ];
      case 'vehicules':
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Plaque', 'flex': 2, 'field': 'plaque'},
          {'label': 'Marque', 'flex': 2, 'field': 'marque'},
          {'label': 'Modèle', 'flex': 2, 'field': 'modele'},
          {'label': 'Couleur', 'flex': 2, 'field': 'couleur'},
        ];
      default:
        return [
          {'label': 'ID', 'flex': 1, 'field': 'id'},
          {'label': 'Données', 'flex': 5, 'field': 'data'},
        ];
    }
  }

  DataRow _buildDataRowForType(BuildContext context, String key, Map<String, dynamic> item, List<Map<String, dynamic>> columns, double baseWidth) {
    return DataRow(
      cells: columns.map((col) {
        final field = col['field'] as String;
        final value = item[field];
        final flex = col['flex'] as int;
        final columnWidth = baseWidth * flex;
        
        return DataCell(
          SizedBox(
            width: columnWidth,
            child: Text(
              _formatFieldValue(field, value),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
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
        return Icons.receipt_long;
      case 'accident':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vehicule':
        return 'Véhicule';
      case 'particulier':
        return 'Particulier';
      case 'entreprise':
        return 'Entreprise';
      case 'contravention':
        return 'Contravention';
      case 'accident':
        return 'Accident';
      default:
        return 'Inconnu';
    }
  }
}
