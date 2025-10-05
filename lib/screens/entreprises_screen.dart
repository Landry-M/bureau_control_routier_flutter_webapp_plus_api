import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entreprise_provider.dart';
import '../widgets/create_entreprise_modal.dart';

class EntreprisesScreen extends StatefulWidget {
  const EntreprisesScreen({super.key});

  @override
  State<EntreprisesScreen> createState() => _EntreprisesScreenState();
}

class _EntreprisesScreenState extends State<EntreprisesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntrepriseProvider>().fetchEntreprises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entreprises'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => _showCreateModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EntrepriseProvider>().refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, RCCM, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<EntrepriseProvider>().fetchEntreprises();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) {
                context.read<EntrepriseProvider>().searchEntreprises(value);
              },
            ),
          ),
          
          // Tableau des données
          Expanded(
            child: Consumer<EntrepriseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${provider.error}',
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refresh(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.entreprises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune entreprise trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_business),
                          label: const Text('Enregistrer une entreprise'),
                          onPressed: () => _showCreateModal(context),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Informations sur les résultats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${provider.totalCount} entreprise(s) trouvée(s)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Page ${provider.currentPage} sur ${provider.totalPages}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tableau
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Désignation')),
                              DataColumn(label: Text('Téléphone')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('RCCM')),
                              DataColumn(label: Text('Secteur')),
                              DataColumn(label: Text('Date Création')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: provider.entreprises.map((entreprise) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(entreprise['id']?.toString() ?? '')),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        entreprise['designation']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(entreprise['gsm']?.toString() ?? '')),
                                  DataCell(Text(entreprise['email']?.toString() ?? '')),
                                  DataCell(Text(entreprise['rccm']?.toString() ?? '')),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        entreprise['secteur']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(entreprise['created_at']))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 20),
                                          onPressed: () => _showDetailsDialog(context, entreprise),
                                          tooltip: 'Voir détails',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _editEntreprise(context, entreprise),
                                          tooltip: 'Modifier',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    
                    // Pagination
                    if (provider.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: provider.currentPage > 1 ? provider.loadPreviousPage : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${provider.currentPage} / ${provider.totalPages}'),
                            IconButton(
                              onPressed: provider.currentPage < provider.totalPages ? provider.loadNextPage : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
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

  void _showCreateModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateEntrepriseModal(),
    ).then((created) {
      if (created == true) {
        // Rafraîchir les données après création
        context.read<EntrepriseProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entreprise enregistrée')),
        );
      }
    });
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> entreprise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${entreprise['designation']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', entreprise['id']),
              _buildDetailRow('Désignation', entreprise['designation']),
              _buildDetailRow('Siège social', entreprise['siege_social']),
              _buildDetailRow('Téléphone', entreprise['gsm']),
              _buildDetailRow('Email', entreprise['email']),
              _buildDetailRow('RCCM', entreprise['rccm']),
              _buildDetailRow('Secteur', entreprise['secteur']),
              _buildDetailRow('Personne contact', entreprise['personne_contact']),
              _buildDetailRow('Fonction contact', entreprise['fonction_contact']),
              _buildDetailRow('Téléphone contact', entreprise['telephone_contact']),
              _buildDetailRow('Observations', entreprise['observations']),
              _buildDetailRow('Date création', _formatDate(entreprise['created_at'])),
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _editEntreprise(BuildContext context, Map<String, dynamic> entreprise) {
    // TODO: Implémenter la modification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de modification à implémenter')),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return date.toString();
    }
  }
}
