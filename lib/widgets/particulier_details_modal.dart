import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contravention_map_viewer.dart';
import 'edit_contravention_modal.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class ParticulierDetailsModal extends StatefulWidget {
  final Map<String, dynamic> particulier;

  const ParticulierDetailsModal({
    super.key,
    required this.particulier,
  });

  @override
  State<ParticulierDetailsModal> createState() =>
      _ParticulierDetailsModalState();
}

class _ParticulierDetailsModalState extends State<ParticulierDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _contraventions = [];
  List<Map<String, dynamic>> _arrestations = [];
  List<Map<String, dynamic>> _permisTemporaires = [];
  List<Map<String, dynamic>> _avisRecherche = [];
  List<Map<String, dynamic>> _vehicules = [];
  bool _isLoadingContraventions = false;
  bool _isLoadingArrestations = false;
  bool _isLoadingPermisTemporaires = false;
  bool _isLoadingAvisRecherche = false;
  bool _isLoadingVehicules = false;
  String? _contraventionsError;
  String? _arrestationsError;
  String? _permisTemporairesError;
  String? _avisRechercheError;
  String? _vehiculesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Charger les véhicules au démarrage
    _loadVehicules();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 &&
        _contraventions.isEmpty &&
        !_isLoadingContraventions) {
      _loadContraventions();
    } else if (_tabController.index == 2 &&
        _arrestations.isEmpty &&
        !_isLoadingArrestations) {
      _loadArrestations();
    } else if (_tabController.index == 3 &&
        _permisTemporaires.isEmpty &&
        !_isLoadingPermisTemporaires) {
      _loadPermisTemporaires();
    } else if (_tabController.index == 4 &&
        _avisRecherche.isEmpty &&
        !_isLoadingAvisRecherche) {
      _loadAvisRecherche();
    }
  }

  Future<void> _loadContraventions() async {
    setState(() {
      _isLoadingContraventions = true;
      _contraventionsError = null;
    });

    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/contraventions/particulier/${widget.particulier['id']}',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _contraventions =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          setState(() {
            _contraventionsError = data['message'] ??
                'Erreur lors du chargement des contraventions';
          });
        }
      } else {
        setState(() {
          _contraventionsError = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _contraventionsError = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoadingContraventions = false;
      });
    }
  }

  Future<void> _loadArrestations() async {
    setState(() {
      _isLoadingArrestations = true;
      _arrestationsError = null;
    });

    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/arrestations/particulier/${widget.particulier['id']}',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _arrestations = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          setState(() {
            _arrestationsError =
                data['message'] ?? 'Erreur lors du chargement des arrestations';
          });
        }
      } else {
        setState(() {
          _arrestationsError = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _arrestationsError = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoadingArrestations = false;
      });
    }
  }

  Future<void> _loadAvisRecherche() async {
    setState(() {
      _isLoadingAvisRecherche = true;
      _avisRechercheError = null;
    });

    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/avis-recherche/particulier/${widget.particulier['id']}',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _avisRecherche =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          setState(() {
            _avisRechercheError = data['message'] ??
                'Erreur lors du chargement des avis de recherche';
          });
        }
      } else {
        setState(() {
          _avisRechercheError = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _avisRechercheError = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoadingAvisRecherche = false;
      });
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
                    Icons.person,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails du particulier',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.particulier['nom']} ${widget.particulier['prenom']}',
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
                    text: 'Arrestations',
                  ),
                  Tab(
                    icon: Icon(Icons.credit_card),
                    text: 'Permis temp.',
                  ),
                  Tab(
                    icon: Icon(Icons.search),
                    text: 'Avis recherche',
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
                  _buildArrestationsTab(),
                  _buildPermisTemporairesTab(),
                  _buildAvisRechercheTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotosSection(),
          const SizedBox(height: 24),
          _buildPersonalInfoSection(),
          const SizedBox(height: 16),
          _buildLicenseSection(),
          const SizedBox(height: 16),
          _buildAdditionalInfoSection(),
          const SizedBox(height: 24),
          ..._buildVehiculesSection(),
        ],
      ),
    );
  }

  Future<void> _loadVehicules() async {
    setState(() {
      _isLoadingVehicules = true;
      _vehiculesError = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/particulier/${widget.particulier['id']}/vehicules',
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
            _vehiculesError = data['message'] ??
                'Erreur lors du chargement des véhicules';
          });
        }
      } else {
        setState(() {
          _vehiculesError = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _vehiculesError = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoadingVehicules = false;
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
      if (_isLoadingVehicules)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_vehiculesError != null)
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
                  _vehiculesError!,
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
                    'Rôle',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vehicule['role']?.toString() ?? 'Propriétaire',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
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
    ];
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPhotoCard('Photo', widget.particulier['photo']),
              const SizedBox(width: 16),
              _buildPhotoCard(
                  'Permis Recto', widget.particulier['permis_recto']),
              const SizedBox(width: 16),
              _buildPhotoCard(
                  'Permis Verso', widget.particulier['permis_verso']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(String title, String? imagePath) {
    return GestureDetector(
      onTap: () {
        if (imagePath != null && imagePath.isNotEmpty) {
          _showFullScreenImage(imagePath, title);
        }
      },
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imagePath != null && imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${ApiConfig.imageBaseUrl}/$imagePath',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 40),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      title == 'Photo' ? Icons.person : Icons.credit_card,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                '${ApiConfig.imageBaseUrl}/$imagePath',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Erreur de chargement de l\'image',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informations personnelles', style: tt.titleMedium),
              const SizedBox(height: 8),
              _buildFormField('ID', widget.particulier['id']?.toString()),
              const SizedBox(height: 12),
              _buildFormField('Nom', widget.particulier['nom'], isTitle: true),
              const SizedBox(height: 12),
              _buildFormField('Prénom', widget.particulier['prenom'],
                  isTitle: true),
              const SizedBox(height: 12),
              _buildFormField('Âge', widget.particulier['age']?.toString()),
              const SizedBox(height: 12),
              _buildFormField('Sexe', widget.particulier['sexe']),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coordonnées', style: tt.titleMedium),
              const SizedBox(height: 8),
              _buildFormField('Téléphone', widget.particulier['telephone']),
              const SizedBox(height: 12),
              _buildFormField('Adresse', widget.particulier['adresse']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseSection() {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Permis de conduire', style: tt.titleMedium),
        const SizedBox(height: 8),
        _buildFormField(
            'Numéro de permis', widget.particulier['numero_permis']),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormField('Date de délivrance',
                  _formatDate(widget.particulier['date_delivrance'])),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField('Date d\'expiration',
                  _formatDate(widget.particulier['date_expiration'])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations supplémentaires', style: tt.titleMedium),
        const SizedBox(height: 8),
        _buildFormField('Observations', widget.particulier['observations'],
            isMultiline: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormField('Date de création',
                  _formatDate(widget.particulier['created_at'])),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField('Dernière modification',
                  _formatDate(widget.particulier['updated_at'])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField(String label, String? value,
      {bool isTitle = false, bool isMultiline = false}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '',
            style: TextStyle(
              fontSize: isTitle ? 16 : 14,
              fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildContraventionsTab() {
    if (_isLoadingContraventions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contraventionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_contraventionsError!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContraventions,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_contraventions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune contravention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Ce particulier n\'a aucune contravention enregistrée.'),
          ],
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
                dataRowMaxHeight: 60,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withOpacity(0.5),
                ),
                columns: const [
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('ID',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Date',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 3,
                          child: Text('Type',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Lieu',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Amende',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('Payé',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('PDF',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('Carte',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('Modifier',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
                rows: _contraventions.map((contravention) {
                  return DataRow(
                    cells: [
                      DataCell(Container(
                          width: double.infinity,
                          child: Text('#${contravention['id']}',
                              style: const TextStyle(fontSize: 12)))),
                      DataCell(Container(
                          width: double.infinity,
                          child: Text(
                              _formatDate(contravention['date_infraction']),
                              style: const TextStyle(fontSize: 12)))),
                      DataCell(Container(
                          width: double.infinity,
                          child: Text(contravention['type_infraction'] ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis))),
                      DataCell(Container(
                          width: double.infinity,
                          child: Text(contravention['lieu'] ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis))),
                      DataCell(Container(
                          width: double.infinity,
                          child: Text('${contravention['amende']} FC',
                              style: const TextStyle(fontSize: 12)))),
                      DataCell(
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: contravention['payed'] == 'oui',
                            onChanged: (value) => _updatePaymentStatus(
                                contravention['id'], value),
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () => _viewPdf(contravention),
                          icon: const Icon(Icons.visibility, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(32, 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          tooltip: 'Voir le PDF',
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () => _viewOnMap(contravention),
                          icon: const Icon(Icons.map, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(32, 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          tooltip: 'Voir sur la carte',
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () => _editContravention(contravention),
                          icon: const Icon(Icons.edit, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(32, 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          tooltip: 'Modifier (Superadmin)',
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

  Widget _buildArrestationsTab() {
    if (_isLoadingArrestations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_arrestationsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_arrestationsError!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArrestations,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_arrestations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune arrestation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Ce particulier n\'a aucune arrestation enregistrée.'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arrestations (${_arrestations.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
                  dataRowMaxHeight: 60,
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withOpacity(0.5),
                  ),
                  columns: const [
                    DataColumn(
                        label: Expanded(
                            flex: 1,
                            child: Text('ID',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(
                        label: Expanded(
                            flex: 2,
                            child: Text('Date',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(
                        label: Expanded(
                            flex: 3,
                            child: Text('Motif',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(
                        label: Expanded(
                            flex: 2,
                            child: Text('Lieu',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(
                        label: Expanded(
                            flex: 2,
                            child: Text('Statut',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(
                        label: Expanded(
                            flex: 1,
                            child: Text('Action',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                  rows: _arrestations.map((arrestation) {
                    final estLibere = arrestation['date_sortie_prison'] != null;
                    return DataRow(
                      cells: [
                        DataCell(Container(
                            width: double.infinity,
                            child: Text('#${arrestation['id']}',
                                style: const TextStyle(fontSize: 12)))),
                        DataCell(Container(
                            width: double.infinity,
                            child: Text(
                                _formatDate(arrestation['date_arrestation']),
                                style: const TextStyle(fontSize: 12)))),
                        DataCell(Container(
                            width: double.infinity,
                            child: Text(arrestation['motif'] ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis))),
                        DataCell(Container(
                            width: double.infinity,
                            child: Text(arrestation['lieu'] ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis))),
                        DataCell(
                          Container(
                            width: double.infinity,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: estLibere
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      estLibere ? Colors.green : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                estLibere ? 'Libéré' : 'En détention',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      estLibere ? Colors.green : Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: estLibere,
                              onChanged: (value) => _updateArrestationStatus(
                                  arrestation['id'], value),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePaymentStatus(int contraventionId, bool isPaid) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/contravention/$contraventionId/update-payment',
        },
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'payed': isPaid ? 'oui' : 'non'}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            final index =
                _contraventions.indexWhere((c) => c['id'] == contraventionId);
            if (index != -1) {
              _contraventions[index]['payed'] = isPaid ? 'oui' : 'non';
            }
          });

          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Statut mis à jour'),
            description: Text(
                'Le statut de paiement a été ${isPaid ? 'marqué comme payé' : 'marqué comme non payé'}'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
        } else {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Erreur'),
            description:
                Text(data['message'] ?? 'Erreur lors de la mise à jour'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } else {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur serveur'),
          description: Text('Code d\'erreur: ${response.statusCode}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur de connexion'),
        description: Text('Impossible de mettre à jour le statut: $e'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
      );
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
      final displayUrl = '${ApiConfig.baseUrl}/contravention/$contraventionId/display';

      // Ouvrir avec url_launcher
      final uri = Uri.parse(displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Contravention ouverte'),
          description: const Text('La contravention a été ouverte dans votre navigateur'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL: $displayUrl');
      }
    } catch (e) {
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
        context, 
        'Aucune localisation disponible pour cette contravention'
      );
    }
  }

  void _editContravention(Map<String, dynamic> contravention) {
    // Vérifier les permissions superadmin
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated || authProvider.role != 'superadmin') {
      NotificationService.error(
        context,
        'Accès refusé. Action réservée aux super-administrateurs.'
      );
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

  Future<void> _updateArrestationStatus(
      int arrestationId, bool estLibere) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {
            'route': '/arrestation/$arrestationId/update-status'
          },
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'est_libere': estLibere,
          'date_sortie': estLibere ? DateTime.now().toIso8601String() : null,
          'username': authProvider.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            final index =
                _arrestations.indexWhere((a) => a['id'] == arrestationId);
            if (index != -1) {
              _arrestations[index]['date_sortie_prison'] =
                  estLibere ? DateTime.now().toIso8601String() : null;
            }
          });

          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Statut mis à jour'),
            description: Text(estLibere
                ? 'La personne a été marquée comme libérée'
                : 'La personne a été marquée comme en détention'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
        } else {
          _showArrestationError(
              data['message'] ?? 'Erreur lors de la mise à jour du statut');
        }
      } else {
        _showArrestationError('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _showArrestationError('Erreur de connexion: $e');
    }
  }

  void _showArrestationError(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Erreur'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
    );
  }

  Future<void> _loadPermisTemporaires() async {
    setState(() {
      _isLoadingPermisTemporaires = true;
      _permisTemporairesError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route':
              '/permis-temporaires/particulier/${widget.particulier['id']}',
          'username': authProvider.username,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _permisTemporaires =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
            _isLoadingPermisTemporaires = false;
          });
        } else {
          setState(() {
            _permisTemporairesError = data['message'] ??
                'Erreur lors du chargement des permis temporaires';
            _isLoadingPermisTemporaires = false;
          });
        }
      } else {
        setState(() {
          _permisTemporairesError = 'Erreur serveur: ${response.statusCode}';
          _isLoadingPermisTemporaires = false;
        });
      }
    } catch (e) {
      setState(() {
        _permisTemporairesError = 'Erreur de connexion: $e';
        _isLoadingPermisTemporaires = false;
      });
    }
  }

  Widget _buildPermisTemporairesTab() {
    if (_isLoadingPermisTemporaires) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_permisTemporairesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _permisTemporairesError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadPermisTemporaires();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_permisTemporaires.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun permis temporaire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette personne n\'a pas de permis temporaire enregistré.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
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
                  Icons.credit_card,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Permis temporaires (${_permisTemporaires.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                dataRowMaxHeight: 60,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withOpacity(0.5),
                ),
                columns: const [
                  DataColumn(
                    label: Expanded(
                      flex: 2,
                      child: Text('Numéro',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      flex: 2,
                      child: Text('Dates validité',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      flex: 3,
                      child: Text('Motif',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      flex: 1,
                      child: Text('Statut',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      flex: 1,
                      child: Text('PDF',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                rows: _permisTemporaires.map((permis) {
                  final dateDebut = _formatDate(permis['date_debut']);
                  final dateFin = _formatDate(permis['date_fin']);
                  final isExpired = _isPermisExpired(permis['date_fin']);
                  final statut = permis['statut'] ?? 'actif';

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            permis['numero'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Du: $dateDebut',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Au: $dateFin',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            permis['motif'] ?? '',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statut == 'actif'
                                      ? Colors.green.shade100
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statut == 'actif' ? 'Actif' : 'Clos',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statut == 'actif'
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (isExpired) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Expiré',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: IconButton(
                            onPressed: () => _viewPermisTemporairePdf(permis),
                            icon: const Icon(Icons.visibility, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.all(4),
                            ),
                            tooltip: 'Voir le PDF',
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

  Widget _buildAvisRechercheTab() {
    if (_isLoadingAvisRecherche) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_avisRechercheError != null) {
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
                _avisRechercheError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAvisRecherche,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_avisRecherche.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun avis de recherche',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cette personne n\'a aucun avis de recherche enregistré.',
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
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avis de recherche (${_avisRecherche.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 3,
                          child: Text('Motif',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Niveau',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Date émission',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('Actif',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
                rows: _avisRecherche.map((avis) {
                  final niveau = avis['niveau'] ?? 'moyen';
                  final statut = avis['statut'] ?? 'actif';
                  final dateEmission = _formatDate(avis['created_at']);
                  final isActif = statut.toLowerCase() == 'actif';

                  Color niveauColor;
                  switch (niveau.toLowerCase()) {
                    case 'faible':
                      niveauColor = Colors.green;
                      break;
                    case 'élevé':
                    case 'eleve':
                      niveauColor = Colors.red;
                      break;
                    default:
                      niveauColor = Colors.orange;
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text('#${avis['id']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            avis['motif'] ?? 'N/A',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: niveauColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: niveauColor),
                            ),
                            child: Text(
                              niveau.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: niveauColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(dateEmission,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Switch(
                            value: isActif,
                            onChanged: (value) {
                              _updateAvisRechercheStatus(
                                  avis['id'], value ? 'actif' : 'inactif');
                            },
                            activeColor: Colors.red,
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

  Future<void> _updateAvisRechercheStatus(int avisId, String statut) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/avis-recherche/$avisId/update-status'},
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'statut': statut,
          'username': authProvider.username,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          final index = _avisRecherche.indexWhere((a) => a['id'] == avisId);
          if (index != -1) {
            _avisRecherche[index]['statut'] = statut;
          }
        });

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Statut mis à jour'),
            description: Text('L\'avis de recherche est maintenant ${statut}'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
            showProgressBar: true,
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur'),
          description:
              Text('Impossible de mettre à jour le statut: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: true,
        );
      }
    }
  }

  bool _isPermisExpired(String? dateFin) {
    if (dateFin == null) return false;
    try {
      final date = DateTime.parse(dateFin);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _viewPermisTemporairePdf(Map<String, dynamic> permis) async {
    final permisId = permis['id'];
    final previewUrl =
        "${ApiConfig.imageBaseUrl}/permis_temporaire_display.php?id=$permisId";

    try {
      final uri = Uri.parse(previewUrl);

      // Essayer plusieurs modes de lancement
      bool launched = false;

      // 1. Essayer le mode externe (nouvelle fenêtre/onglet)
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // 2. Essayer le mode par défaut de la plateforme
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          // 3. Essayer avec WebView intégrée
          try {
            launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } catch (e3) {
            launched = false;
          }
        }
      }

      if (launched) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Prévisualisation ouverte'),
          description: Text(
              'Permis ${permis['numero']} ouvert dans une nouvelle fenêtre'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: true,
        );
      } else {
        // Si toutes les tentatives échouent, afficher l'URL
        _showPermisUrlFallback(previewUrl);
      }
    } catch (e) {
      // En cas d'erreur générale, afficher l'URL
      _showPermisUrlFallback(previewUrl);
    }
  }

  void _showPermisUrlFallback(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévisualisation du permis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Copiez cette URL dans votre navigateur pour voir le permis temporaire:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Essayer encore une fois d'ouvrir l'URL
              try {
                await launchUrl(Uri.parse(url));
              } catch (e) {
                // Ignorer l'erreur, l'utilisateur a l'URL
              }
            },
            child: const Text('Essayer d\'ouvrir'),
          ),
        ],
      ),
    );
  }
}
