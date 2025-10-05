import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/particulier_provider.dart';
import '../widgets/create_particulier_modal.dart';

class ParticuliersScreen extends StatefulWidget {
  const ParticuliersScreen({super.key});

  @override
  State<ParticuliersScreen> createState() => _ParticuliersScreenState();
}

class _ParticuliersScreenState extends State<ParticuliersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParticulierProvider>().fetchParticuliers();
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
        title: const Text('Particuliers'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ParticulierProvider>().refresh(),
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
                hintText: 'Rechercher par nom, téléphone, numéro de permis...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ParticulierProvider>().fetchParticuliers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) {
                context.read<ParticulierProvider>().searchParticuliers(value);
              },
            ),
          ),
          
          // Tableau des données
          Expanded(
            child: Consumer<ParticulierProvider>(
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

                if (provider.particuliers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun particulier trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
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
                            '${provider.totalCount} particulier(s) trouvé(s)',
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
                              DataColumn(label: Text('Nom')),
                              DataColumn(label: Text('Téléphone')),
                              DataColumn(label: Text('Adresse')),
                              DataColumn(label: Text('Numéro Permis')),
                              DataColumn(label: Text('Date Création')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: provider.particuliers.map((particulier) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(particulier['id']?.toString() ?? '')),
                                  DataCell(Text(particulier['nom']?.toString() ?? '')),
                                  DataCell(Text(particulier['telephone']?.toString() ?? '')),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        particulier['adresse']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(particulier['numero_permis']?.toString() ?? '')),
                                  DataCell(Text(_formatDate(particulier['created_at']))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 20),
                                          onPressed: () => _showDetailsDialog(context, particulier),
                                          tooltip: 'Voir détails',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _editParticulier(context, particulier),
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
      builder: (context) => const CreateParticulierModal(),
    ).then((_) {
      // Rafraîchir les données après création
      context.read<ParticulierProvider>().refresh();
    });
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> particulier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${particulier['nom']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', particulier['id']),
              _buildDetailRow('Nom', particulier['nom']),
              _buildDetailRow('Téléphone', particulier['telephone']),
              _buildDetailRow('Adresse', particulier['adresse']),
              _buildDetailRow('Profession', particulier['profession']),
              _buildDetailRow('Date de naissance', particulier['date_naissance']),
              _buildDetailRow('Genre', particulier['genre']),
              _buildDetailRow('Numéro national', particulier['numero_national']),
              _buildDetailRow('Email', particulier['email']),
              _buildDetailRow('Lieu de naissance', particulier['lieu_naissance']),
              _buildDetailRow('Nationalité', particulier['nationalite']),
              _buildDetailRow('État civil', particulier['etat_civil']),
              _buildDetailRow('Numéro de permis', particulier['numero_permis']),
              _buildDetailRow('Date création', _formatDate(particulier['created_at'])),
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

  void _editParticulier(BuildContext context, Map<String, dynamic> particulier) {
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
