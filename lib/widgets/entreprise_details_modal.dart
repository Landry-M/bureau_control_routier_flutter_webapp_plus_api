import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'contravention_map_viewer.dart';
import 'edit_contravention_modal.dart';

class EntrepriseDetailsModal extends StatefulWidget {
  final Map<String, dynamic> entreprise;

  const EntrepriseDetailsModal({
    super.key,
    required this.entreprise,
  });

  @override
  State<EntrepriseDetailsModal> createState() => _EntrepriseDetailsModalState();
}

class _EntrepriseDetailsModalState extends State<EntrepriseDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _contraventions = [];
  List<Map<String, dynamic>> _vehicules = [];
  bool _loadingContraventions = false;
  bool _loadingVehicules = false;
  String? _errorContraventions;
  String? _errorVehicules;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContraventions();
    _loadVehicules();
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
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api
          .get('/contraventions/entreprise/${widget.entreprise['id']}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse the response - assuming it returns a list of contraventions
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

  Future<void> _viewPdf(Map<String, dynamic> contravention) async {
    try {
      final contraventionId = contravention['id'];
      if (contraventionId == null) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur'),
          description: const Text('ID de contravention manquant'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }

      // Utiliser display_contravention pour un affichage cohérent
      final displayUrl = ApiConfig.getContraventionDisplayUrl(contraventionId);

      // Ouvrir avec url_launcher
      final uri = Uri.parse(displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Contravention ouverte'),
            description: const Text(
                'La contravention a été ouverte dans votre navigateur'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL: $displayUrl');
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur d\'affichage'),
          description: Text('Erreur: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    }
  }

  void _viewOnMap(Map<String, dynamic> contravention) {
    final latitude = contravention['latitude'];
    final longitude = contravention['longitude'];

    if (latitude != null && longitude != null) {
      showDialog(
        context: context,
        builder: (context) => ContraventionMapViewer(
          contravention: contravention,
        ),
      );
    } else {
      NotificationService.error(
          context, 'Aucune localisation disponible pour cette contravention');
    }
  }

  void _editContravention(Map<String, dynamic> contravention) {
    // Vérifier les permissions superadmin
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated || authProvider.role != 'superadmin') {
      NotificationService.error(
          context, 'Accès refusé. Action réservée aux super-administrateurs.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EditContraventionModal(
        contravention: contravention,
        onSuccess: () {
          // Recharger les contraventions
          _loadContraventions();
        },
      ),
    );
  }

  Future<void> _updatePaymentStatus(String contraventionId, bool isPaid) async {
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response =
          await api.postJson('/contravention/$contraventionId/update-payment', {
        'payed': isPaid ? 'oui' : 'non',
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Recharger les contraventions pour mettre à jour l'affichage
        await _loadContraventions();

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text(
                isPaid ? 'Contravention payée' : 'Contravention non payée'),
            description: Text(isPaid
                ? 'La contravention a été marquée comme payée'
                : 'La contravention a été marquée comme non payée'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
        }
      } else {
        throw Exception('Erreur lors de la mise à jour du statut');
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur de mise à jour'),
          description: Text('Erreur: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
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
          // Informations principales - Colonne 1 et 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations principales', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    _buildFormField('ID', widget.entreprise['id']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Désignation', widget.entreprise['designation'],
                        isTitle: true),
                    const SizedBox(height: 12),
                    _buildFormField('RCCM', widget.entreprise['rccm']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Siège social', widget.entreprise['siege_social']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Secteur d\'activité', widget.entreprise['secteur']),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Colonne 2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coordonnées & Contact', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    _buildFormField('Téléphone', widget.entreprise['gsm']),
                    const SizedBox(height: 12),
                    _buildFormField('Email', widget.entreprise['email']),
                    const SizedBox(height: 12),
                    _buildFormField('Personne à contacter',
                        widget.entreprise['personne_contact']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Fonction', widget.entreprise['fonction_contact']),
                    const SizedBox(height: 12),
                    _buildFormField('Téléphone contact',
                        widget.entreprise['telephone_contact']),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Observations (pleine largeur)
          Text('Informations supplémentaires', style: tt.titleMedium),
          const SizedBox(height: 8),
          _buildFormField('Observations', widget.entreprise['observations']),

          const SizedBox(height: 16),

          // Dates système
          Text('Informations système', style: tt.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Date de création',
                    _formatDate(widget.entreprise['created_at'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Dernière modification',
                    _formatDate(widget.entreprise['updated_at'])),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ..._buildVehiculesSection(),
        ],
      ),
    );
  }

  Future<void> _loadVehicules() async {
    setState(() {
      _loadingVehicules = true;
      _errorVehicules = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/entreprise/${widget.entreprise['id']}/vehicules',
          'username': username,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _vehicules = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          setState(() {
            _errorVehicules =
                data['message'] ?? 'Erreur lors du chargement des véhicules';
          });
        }
      } else {
        setState(() {
          _errorVehicules = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorVehicules = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _loadingVehicules = false;
      });
    }
  }

  List<Widget> _buildVehiculesSection() {
    return [
      const Divider(thickness: 2),
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Véhicules associés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loadingVehicules)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_errorVehicules != null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorVehicules!,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        )
      else if (_vehicules.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Aucun véhicule associé',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        )
      else
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DataTable(
              columnSpacing: 12,
              horizontalMargin: 12,
              headingRowColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
              ),
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(
                  label: Text(
                    'Plaque',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Marque',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Modèle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Couleur',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'N° Chassis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Date association',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
              rows: _vehicules.map((vehicule) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        vehicule['plaque']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        vehicule['marque']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        vehicule['modele']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        vehicule['couleur']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        vehicule['numero_chassis']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDate(vehicule['date_assoc']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
    ];
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
                'Cette entreprise n\'a aucune contravention enregistrée.',
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

          // Tableau des contraventions - Prend toute la largeur
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
                  DataColumn(
                      label: Expanded(
                    flex: 1,
                    child: Text('PDF',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 1,
                    child: Text('Carte',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  DataColumn(
                      label: Expanded(
                    flex: 1,
                    child: Text('Modifier',
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
                                  contravention['id'].toString(),
                                  value,
                                );
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () => _viewPdf(contravention),
                            icon: const Icon(Icons.visibility, size: 18),
                            tooltip: 'Voir le PDF',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () => _viewOnMap(contravention),
                            icon: const Icon(Icons.map, size: 18),
                            tooltip: 'Voir sur la carte',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () => _editContravention(contravention),
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Modifier (Superadmin)',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête avec titre et bouton fermer
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
                    Icons.business,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails de l\'entreprise',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.entreprise['designation']?.toString() ?? 'N/A',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
