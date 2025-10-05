import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
class VehiculeDetailsModal extends StatefulWidget {
  final Map<String, dynamic> vehicule;

  const VehiculeDetailsModal({
    super.key,
    required this.vehicule,
  });

  @override
  State<VehiculeDetailsModal> createState() => _VehiculeDetailsModalState();
}

class _VehiculeDetailsModalState extends State<VehiculeDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _contraventions = [];
  List<Map<String, dynamic>> _assurances = [];
  bool _loadingContraventions = false;
  bool _loadingAssurances = false;
  String? _errorContraventions;
  String? _errorAssurances;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContraventions();
    _loadAssurances();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContraventions() async {
    setState(() {
      _loadingContraventions = true;
      _errorContraventions = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api
          .get('/contraventions/vehicule/${widget.vehicule['id']}?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _contraventions = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      } else {
        setState(() {
          _errorContraventions = 'Erreur lors du chargement des contraventions';
        });
      }
    } catch (e) {
      setState(() {
        _errorContraventions = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loadingContraventions = false;
      });
    }
  }

  Future<void> _loadAssurances() async {
    setState(() {
      _loadingAssurances = true;
      _errorAssurances = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api
          .get('/assurances/vehicule/${widget.vehicule['id']}?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _assurances = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      } else {
        setState(() {
          _errorAssurances = 'Erreur lors du chargement des assurances';
        });
      }
    } catch (e) {
      setState(() {
        _errorAssurances = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loadingAssurances = false;
      });
    }
  }

  Future<void> _updatePaymentStatus(int contraventionId, bool isPaid) async {
    try {
      final username = context.read<AuthProvider>().username;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/contravention/$contraventionId/update-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payed': isPaid ? 'oui' : 'non',
          'username': username,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour localement
        setState(() {
          final index = _contraventions.indexWhere((c) => c['id'] == contraventionId);
          if (index != -1) {
            _contraventions[index]['payed'] = isPaid ? 'oui' : 'non';
          }
        });

        // Notification de succès
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Statut mis à jour'),
            description: Text(
              isPaid 
                ? 'La contravention a été marquée comme payée'
                : 'La contravention a été marquée comme non payée'
            ),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      // Notification d'erreur
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur'),
          description: Text('Impossible de mettre à jour le statut: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: true,
        );
      }
    }
  }

  Future<void> _showAssuranceModal({bool isRenewal = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AssuranceModal(
        vehiculeId: widget.vehicule['id'],
        isRenewal: isRenewal,
        lastAssurance: isRenewal && _assurances.isNotEmpty ? _assurances.first : null,
      ),
    );

    if (result == true) {
      // Recharger les assurances après ajout/renouvellement
      _loadAssurances();
    }
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

  Widget _buildFormField(String label, dynamic value, {bool isTitle = false}) {
    final displayValue = value?.toString() ?? 'N/A';
    final isMultiline = label.toLowerCase().contains('observation');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isTitle
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: isTitle ? 16 : 14,
              fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: isMultiline ? null : 1,
            overflow:
                isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section photos véhicule
          if (widget.vehicule['images'] != null && widget.vehicule['images'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos du véhicule', style: tt.titleMedium),
                const SizedBox(height: 8),
                _buildVehiclePhotos(),
                const SizedBox(height: 16),
              ],
            ),

          // Informations principales - Colonne 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations principales', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    _buildFormField('ID', widget.vehicule['id']),
                    const SizedBox(height: 12),
                    _buildFormField('Plaque', widget.vehicule['plaque'], isTitle: true),
                    const SizedBox(height: 12),
                    _buildFormField('Marque', widget.vehicule['marque']),
                    const SizedBox(height: 12),
                    _buildFormField('Modèle', widget.vehicule['modele']),
                    const SizedBox(height: 12),
                    _buildFormField('Couleur', widget.vehicule['couleur']),
                    const SizedBox(height: 12),
                    _buildFormField('Année', widget.vehicule['annee']),
                    const SizedBox(height: 12),
                    _buildFormField('Numéro chassis', widget.vehicule['numero_chassis']),
                    const SizedBox(height: 12),
                    _buildFormField('Genre', widget.vehicule['genre']),
                    const SizedBox(height: 12),
                    _buildFormField('Usage', widget.vehicule['usage']),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Colonne 2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations techniques', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    _buildFormField('Numéro moteur', widget.vehicule['num_moteur']),
                    const SizedBox(height: 12),
                    _buildFormField('Origine', widget.vehicule['origine']),
                    const SizedBox(height: 12),
                    _buildFormField('Source', widget.vehicule['source']),
                    const SizedBox(height: 12),
                    _buildFormField('Année fabrication', widget.vehicule['annee_fab']),
                    const SizedBox(height: 12),
                    _buildFormField('Année circulation', widget.vehicule['annee_circ']),
                    const SizedBox(height: 12),
                    _buildFormField('Type EM', widget.vehicule['type_em']),
                    const SizedBox(height: 12),
                    _buildFormField('Frontière entrée', widget.vehicule['frontiere_entree']),
                    const SizedBox(height: 12),
                    _buildFormField('Date importation', _formatDate(widget.vehicule['date_importation'])),
                    const SizedBox(height: 12),
                    _buildFormField('Numéro déclaration', widget.vehicule['numero_declaration']),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations plaque
          Text('Informations plaque', style: tt.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Plaque valide le', _formatDate(widget.vehicule['plaque_valide_le'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Plaque expire le', _formatDate(widget.vehicule['plaque_expire_le'])),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dates système
          Text('Informations système', style: tt.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Date de création', _formatDate(widget.vehicule['created_at'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Dernière modification', _formatDate(widget.vehicule['updated_at'])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotos() {
    try {
      final imagesString = widget.vehicule['images']?.toString() ?? '[]';
      final List<dynamic> imagesList = jsonDecode(imagesString);
      
      if (imagesList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Text('Aucune photo disponible'),
        );
      }

      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: imagesList.length,
          itemBuilder: (context, index) {
            final imagePath = imagesList[index].toString();
            final imageUrl = '${ApiConfig.baseUrl}$imagePath';
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.car_rental, color: Colors.grey),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text('Erreur lors du chargement des photos'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails du véhicule',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.vehicule['marque']} ${widget.vehicule['modele']} - ${widget.vehicule['plaque']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),

            // Onglets
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.info_outline),
                    text: 'Informations',
                  ),
                  Tab(
                    icon: Icon(Icons.assignment),
                    text: 'Contraventions',
                  ),
                  Tab(
                    icon: Icon(Icons.security),
                    text: 'Assurances',
                  ),
                ],
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildContraventionsTab(),
                  _buildAssurancesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContraventionsTab() {
    if (_loadingContraventions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorContraventions != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorContraventions!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadContraventions,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contraventions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune contravention',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce véhicule n\'a aucune contravention enregistrée.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contraventions (${_contraventions.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tableau des contraventions
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 12,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withOpacity(0.5),
                ),
                dataRowMaxHeight: 60,
                columns: const [
                  DataColumn(
                      label: Expanded(
                    flex: 1,
                    child: Text('ID',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 3,
                    child: Text('Type',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Lieu',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Amende',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 1,
                    child: Text('Payé',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ],
                rows: _contraventions.map((contravention) {
                  final isPaid = contravention['payed'] == 'oui';
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            '#${contravention['id']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            _formatDate(contravention['date_infraction']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            contravention['type_infraction']?.toString() ??
                                'N/A',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            contravention['lieu']?.toString() ?? 'N/A',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            '${contravention['amende']} FC',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isPaid,
                              onChanged: (value) {
                                _updatePaymentStatus(
                                  contravention['id'],
                                  value,
                                );
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
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
  }

  Widget _buildAssurancesTab() {
    if (_loadingAssurances) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorAssurances != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorAssurances!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAssurances,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assurances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune assurance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce véhicule n\'a aucun historique d\'assurance enregistré.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAssuranceModal(isRenewal: false),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une assurance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historique des assurances (${_assurances.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAssuranceModal(isRenewal: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renouveler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tableau des assurances
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 12,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withOpacity(0.5),
                ),
                dataRowMaxHeight: 60,
                columns: const [
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Compagnie',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('N° Police',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Début',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Fin',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Prime',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 2,
                    child: Text('Type',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ],
                rows: _assurances.map((assurance) {
                  final isExpired = assurance['date_expire_assurance'] != null &&
                      DateTime.parse(assurance['date_expire_assurance']).isBefore(DateTime.now());
                  
                  return DataRow(
                    color: MaterialStateProperty.all(
                      isExpired ? Colors.red.withOpacity(0.1) : null,
                    ),
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            assurance['societe_assurance']?.toString() ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            assurance['nume_assurance']?.toString() ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            _formatDate(assurance['date_valide_assurance']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            _formatDate(assurance['date_expire_assurance']),
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.red : null,
                              fontWeight: isExpired ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            assurance['montant_prime'] != null 
                                ? '${assurance['montant_prime']} FC'
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            assurance['type_couverture']?.toString() ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
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
  }
}

class _AssuranceModal extends StatefulWidget {
  final int vehiculeId;
  final bool isRenewal;
  final Map<String, dynamic>? lastAssurance;

  const _AssuranceModal({
    required this.vehiculeId,
    required this.isRenewal,
    this.lastAssurance,
  });

  @override
  State<_AssuranceModal> createState() => _AssuranceModalState();
}

class _AssuranceModalState extends State<_AssuranceModal> {
  final _formKey = GlobalKey<FormState>();
  final _societeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _primeController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRenewal && widget.lastAssurance != null) {
      // Pré-remplir avec les données de la dernière assurance
      _societeController.text = widget.lastAssurance!['societe_assurance']?.toString() ?? '';
      _typeController.text = widget.lastAssurance!['type_couverture']?.toString() ?? '';
      _primeController.text = widget.lastAssurance!['montant_prime']?.toString() ?? '';
      _notesController.text = widget.lastAssurance!['notes']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _societeController.dispose();
    _numeroController.dispose();
    _primeController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = date;
        } else {
          _dateFin = date;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveAssurance() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Dates requises'),
        description: const Text('Veuillez sélectionner les dates de début et de fin'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assurance/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicule_plaque_id': widget.vehiculeId,
          'societe_assurance': _societeController.text,
          'nume_assurance': _numeroController.text,
          'date_valide_assurance': '${_dateDebut!.year}-${_dateDebut!.month.toString().padLeft(2, '0')}-${_dateDebut!.day.toString().padLeft(2, '0')}',
          'date_expire_assurance': '${_dateFin!.year}-${_dateFin!.month.toString().padLeft(2, '0')}-${_dateFin!.day.toString().padLeft(2, '0')}',
          'montant_prime': _primeController.text.isNotEmpty ? _primeController.text : null,
          'type_couverture': _typeController.text,
          'notes': _notesController.text,
          'username': username,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text(widget.isRenewal ? 'Assurance renouvelée' : 'Assurance ajoutée'),
            description: Text(
              widget.isRenewal 
                ? 'L\'assurance a été renouvelée avec succès'
                : 'L\'assurance a été ajoutée avec succès'
            ),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la sauvegarde');
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur'),
          description: Text('Impossible de sauvegarder: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: true,
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // En-tête
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
                  Icon(
                    widget.isRenewal ? Icons.refresh : Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isRenewal ? 'Renouveler l\'assurance' : 'Ajouter une assurance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations de base
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _societeController,
                              decoration: const InputDecoration(
                                labelText: 'Compagnie d\'assurance *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _numeroController,
                              decoration: const InputDecoration(
                                labelText: 'Numéro de police *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date de début *',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(_formatDate(_dateDebut)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date de fin *',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(_formatDate(_dateFin)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prime et type
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _primeController,
                              decoration: const InputDecoration(
                                labelText: 'Montant de la prime (FC)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _typeController,
                              decoration: const InputDecoration(
                                labelText: 'Type de couverture',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _saveAssurance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.isRenewal ? 'Renouveler' : 'Ajouter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
