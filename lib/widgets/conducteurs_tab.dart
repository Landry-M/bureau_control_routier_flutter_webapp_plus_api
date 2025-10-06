import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/conducteur_provider.dart';

class ConducteursTab extends StatefulWidget {
  const ConducteursTab({super.key});

  @override
  State<ConducteursTab> createState() => _ConducteursTabState();
}

class _ConducteursTabState extends State<ConducteursTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConducteurProvider>().fetchConducteurs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête avec recherche et actions
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.badge, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Conducteurs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              // Barre de recherche
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, téléphone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ConducteurProvider>().clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (value) {
                    context.read<ConducteurProvider>().searchConducteurs(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                onPressed: () => context.read<ConducteurProvider>().refresh(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tableau des conducteurs
        Expanded(
          child: Consumer<ConducteurProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.conducteurs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Erreur: ${provider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.refresh(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.conducteurs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun conducteur trouvé'),
                    ],
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // En-tête du tableau avec pagination
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Total: ${provider.totalItems} conducteur(s)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          if (provider.totalPages > 1) ...[
                            IconButton(
                              onPressed: provider.currentPage > 1
                                  ? () => provider.previousPage()
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Page précédente',
                            ),
                            Text(
                                '${provider.currentPage} / ${provider.totalPages}'),
                            IconButton(
                              onPressed:
                                  provider.currentPage < provider.totalPages
                                      ? () => provider.nextPage()
                                      : null,
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Page suivante',
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Tableau
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Téléphone')),
                            DataColumn(label: Text('Date de naissance')),
                            DataColumn(label: Text('Adresse')),
                            DataColumn(label: Text('Créé le')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.conducteurs.map((conducteur) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                    conducteur['id']?.toString() ?? 'N/A')),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      conducteur['nom']?.toString() ?? 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                    conducteur['gsm']?.toString() ?? 'N/A')),
                                DataCell(Text(
                                    _formatDate(conducteur['date_naissance']))),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      conducteur['adresse']?.toString() ??
                                          'N/A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                    _formatDate(conducteur['created_at']))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: Colors.white),
                                    tooltip: 'Voir les détails',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Modal simple pour les détails du conducteur
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Détails du Conducteur'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('ID: ${conducteur['id']}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Nom: ${conducteur['nom'] ?? 'N/A'}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Téléphone: ${conducteur['gsm'] ?? 'N/A'}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Naissance: ${_formatDate(conducteur['date_naissance'])}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Adresse: ${conducteur['adresse'] ?? 'N/A'}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Observations: ${conducteur['observations'] ?? 'Aucune'}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Créé le: ${_formatDate(conducteur['created_at'])}'),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
