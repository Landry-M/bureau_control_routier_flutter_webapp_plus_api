import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ParticulierDetailsModal extends StatefulWidget {
  final Map<String, dynamic> particulier;

  const ParticulierDetailsModal({
    super.key,
    required this.particulier,
  });

  @override
  State<ParticulierDetailsModal> createState() => _ParticulierDetailsModalState();
}

class _ParticulierDetailsModalState extends State<ParticulierDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _contraventions = [];
  List<Map<String, dynamic>> _arrestations = [];
  bool _isLoadingContraventions = false;
  bool _isLoadingArrestations = false;
  String? _contraventionsError;
  String? _arrestationsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _contraventions.isEmpty && !_isLoadingContraventions) {
      _loadContraventions();
    } else if (_tabController.index == 2 && _arrestations.isEmpty && !_isLoadingArrestations) {
      _loadArrestations();
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
            _contraventions = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          setState(() {
            _contraventionsError = data['message'] ?? 'Erreur lors du chargement des contraventions';
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
            _arrestationsError = data['message'] ?? 'Erreur lors du chargement des arrestations';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Détails - ${widget.particulier['nom']} ${widget.particulier['prenom']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            // Onglets
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Informations', icon: Icon(Icons.info_outline)),
                  Tab(text: 'Contraventions', icon: Icon(Icons.receipt_long)),
                  Tab(text: 'Arrestations', icon: Icon(Icons.security)),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
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
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 24),
          _buildLicenseSection(),
          const SizedBox(height: 24),
          _buildAdditionalInfoSection(),
        ],
      ),
    );
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
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPhotoCard('Photo', widget.particulier['photo']),
            const SizedBox(width: 12),
            _buildPhotoCard('Permis Recto', widget.particulier['permis_recto']),
            const SizedBox(width: 12),
            _buildPhotoCard('Permis Verso', widget.particulier['permis_verso']),
          ],
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
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              child: imagePath != null && imagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        '${ApiConfig.baseUrl}/$imagePath',
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
                            child: const Center(child: CircularProgressIndicator()),
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
            Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
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
                '${ApiConfig.baseUrl}/$imagePath',
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 100, child: _buildFormField('ID', widget.particulier['id']?.toString())),
            SizedBox(width: 200, child: _buildFormField('Nom', widget.particulier['nom'], isTitle: true)),
            SizedBox(width: 200, child: _buildFormField('Prénom', widget.particulier['prenom'], isTitle: true)),
            SizedBox(width: 100, child: _buildFormField('Âge', widget.particulier['age']?.toString())),
            SizedBox(width: 120, child: _buildFormField('Sexe', widget.particulier['sexe'])),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordonnées',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 200, child: _buildFormField('Téléphone', widget.particulier['telephone'])),
            SizedBox(width: 400, child: _buildFormField('Adresse', widget.particulier['adresse'])),
          ],
        ),
      ],
    );
  }

  Widget _buildLicenseSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permis de conduire',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 200, child: _buildFormField('Numéro de permis', widget.particulier['numero_permis'])),
            SizedBox(width: 150, child: _buildFormField('Catégorie', widget.particulier['categorie_permis'])),
            SizedBox(width: 150, child: _buildFormField('Date de délivrance', _formatDate(widget.particulier['date_delivrance']))),
            SizedBox(width: 150, child: _buildFormField('Date d\'expiration', _formatDate(widget.particulier['date_expiration']))),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations supplémentaires',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 640, child: _buildFormField('Observations', widget.particulier['observations'], isMultiline: true)),
            SizedBox(width: 200, child: _buildFormField('Date de création', _formatDate(widget.particulier['created_at']))),
            SizedBox(width: 200, child: _buildFormField('Dernière modification', _formatDate(widget.particulier['updated_at']))),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField(String label, String? value, {bool isTitle = false, bool isMultiline = false}) {
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
              color: isTitle ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contraventions (${_contraventions.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 12,
                dataRowMaxHeight: 60,
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
                ),
                columns: const [
                  DataColumn(label: Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 3, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 2, child: Text('Lieu', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 2, child: Text('Amende', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 1, child: Text('Payé', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: Expanded(flex: 1, child: Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
                rows: _contraventions.map((contravention) {
                  return DataRow(
                    cells: [
                      DataCell(Container(width: double.infinity, child: Text('#${contravention['id']}', style: const TextStyle(fontSize: 12)))),
                      DataCell(Container(width: double.infinity, child: Text(_formatDate(contravention['date_infraction']), style: const TextStyle(fontSize: 12)))),
                      DataCell(Container(width: double.infinity, child: Text(contravention['type_infraction'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis))),
                      DataCell(Container(width: double.infinity, child: Text(contravention['lieu'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis))),
                      DataCell(Container(width: double.infinity, child: Text('${contravention['amende']} FC', style: const TextStyle(fontSize: 12)))),
                      DataCell(
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: contravention['payed'] == 'oui',
                            onChanged: (value) => _updatePaymentStatus(contravention['id'], value),
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
            Icon(Icons.security_outlined, size: 64, color: Colors.grey.shade400),
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
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Motif', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Lieu', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _arrestations.map((arrestation) {
                return DataRow(
                  cells: [
                    DataCell(Text('#${arrestation['id']}')),
                    DataCell(Text(_formatDate(arrestation['date_arrestation']))),
                    DataCell(Text(arrestation['motif'] ?? '')),
                    DataCell(Text(arrestation['lieu'] ?? '')),
                    DataCell(Text(arrestation['statut'] ?? '')),
                  ],
                );
              }).toList(),
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
            final index = _contraventions.indexWhere((c) => c['id'] == contraventionId);
            if (index != -1) {
              _contraventions[index]['payed'] = isPaid ? 'oui' : 'non';
            }
          });

          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Statut mis à jour'),
            description: Text('Le statut de paiement a été ${isPaid ? 'marqué comme payé' : 'marqué comme non payé'}'),
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
            description: Text(data['message'] ?? 'Erreur lors de la mise à jour'),
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

  void _viewPdf(Map<String, dynamic> contravention) {
    final pdfPath = contravention['pdf_path'];
    
    if (pdfPath != null && pdfPath.toString().isNotEmpty) {
      final pdfUrl = '${ApiConfig.baseUrl}/$pdfPath';
      
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        title: const Text('PDF disponible'),
        description: Text('URL du PDF: $pdfUrl'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 5),
        showProgressBar: true,
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('PDF indisponible'),
        description: const Text('Aucun PDF n\'est disponible pour cette contravention'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }
}
