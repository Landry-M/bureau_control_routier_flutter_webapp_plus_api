import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/global_search_provider.dart';
import '../widgets/top_bar.dart';
import 'search_details_screen.dart';

class GlobalSearchResultsScreen extends StatelessWidget {
  const GlobalSearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: Consumer<GlobalSearchProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // En-tête avec titre et statistiques
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.search, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Résultats de recherche',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    if (provider.query.isNotEmpty)
                                      Text(
                                        'Recherche: "${provider.query}"',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (provider.hasResults) ...[
                            const SizedBox(height: 16),
                            _buildResultsStats(context, provider),
                          ],
                        ],
                      ),
                    ),
                    
                    // Contenu principal
                    Expanded(
                      child: _buildContent(context, provider),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsStats(BuildContext context, GlobalSearchProvider provider) {
    final theme = Theme.of(context);
    final counts = provider.getResultsCountByTypes();
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: counts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForType(entry.key),
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${_getTypeLabel(entry.key)}: ${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildContent(BuildContext context, GlobalSearchProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }
    
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Erreur: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.search(provider.query),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (!provider.hasResults) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun résultat trouvé'),
            SizedBox(height: 8),
            Text(
              'Essayez avec des termes différents',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return _buildResultsList(context, provider);
  }
  
  Widget _buildResultsList(BuildContext context, GlobalSearchProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = provider.results[index];
        return _buildResultItem(context, result);
      },
    );
  }
  
  Widget _buildResultItem(BuildContext context, Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final type = result['type'] as String;
    final typeLabel = result['type_label'] as String;
    final title = result['title'] as String;
    final subtitle = result['subtitle'] as String;
    final createdAt = result['created_at'] as String?;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(type),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                typeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Créé le: ${_formatDate(createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Actions supplémentaires',
          onSelected: (value) => _handleAction(context, value, type, result),
          itemBuilder: (context) => _buildActionItems(type),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SearchDetailsScreen(
                type: type,
                id: result['id'] as int,
                title: title,
              ),
            ),
          );
        },
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
        return Icons.receipt_long;
      case 'accident':
        return Icons.warning;
      case 'arrestation':
        return Icons.security;
      case 'user':
        return Icons.badge;
      case 'avis_recherche':
        return Icons.search;
      case 'permis_temporaire':
        return Icons.card_membership;
      case 'temoin':
        return Icons.visibility;
      case 'assurance':
        return Icons.shield;
      default:
        return Icons.help_outline;
    }
  }
  
  String _getTypeLabel(String type) {
    switch (type) {
      case 'vehicule':
        return 'Véhicules';
      case 'particulier':
        return 'Particuliers';
      case 'entreprise':
        return 'Entreprises';
      case 'contravention':
        return 'Contraventions';
      case 'accident':
        return 'Accidents';
      case 'arrestation':
        return 'Arrestations';
      case 'user':
        return 'Utilisateurs';
      case 'avis_recherche':
        return 'Avis de recherche';
      case 'permis_temporaire':
        return 'Permis temporaires';
      case 'temoin':
        return 'Témoins';
      case 'assurance':
        return 'Assurances';
      default:
        return 'Autres';
    }
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  List<PopupMenuEntry<String>> _buildActionItems(String type) {
    switch (type) {
      case 'vehicule':
        return const [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 12),
                Text('Voir détails'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'assigner_contravention',
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 20),
                SizedBox(width: 12),
                Text('Assigner contravention'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'retirer_circulation',
            child: Row(
              children: [
                Icon(Icons.block, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Retirer de la circulation'),
              ],
            ),
          ),
        ];
      case 'particulier':
        return const [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 12),
                Text('Voir détails'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'assigner_contravention',
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 20),
                SizedBox(width: 12),
                Text('Assigner contravention'),
              ],
            ),
          ),
        ];
      case 'entreprise':
        return const [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 12),
                Text('Voir détails'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'assigner_contravention',
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 20),
                SizedBox(width: 12),
                Text('Assigner contravention'),
              ],
            ),
          ),
        ];
      default:
        return const [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 12),
                Text('Voir détails'),
              ],
            ),
          ),
        ];
    }
  }

  void _handleAction(BuildContext context, String action, String type, Map<String, dynamic> result) {
    switch (action) {
      case 'details':
        // Ouvrir l'écran de détails (comportement existant)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchDetailsScreen(
              type: type,
              id: result['id'] as int,
              title: result['title'] as String,
            ),
          ),
        );
        break;
      case 'assigner_contravention':
        // TODO: Implémenter assignation contravention
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité à implémenter')),
        );
        break;
      case 'retirer_circulation':
        // TODO: Implémenter retrait de circulation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité à implémenter')),
        );
        break;
    }
  }
}
