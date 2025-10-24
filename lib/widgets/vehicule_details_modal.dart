import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../utils/date_time_picker_theme.dart';
import '../services/notification_service.dart';
import 'contravention_map_viewer.dart';
import 'edit_contravention_modal.dart';
import 'particulier_details_modal.dart';
import 'assign_contravention_particulier_modal.dart';
import 'entreprise_details_modal.dart';
import 'assign_contravention_entreprise_modal.dart';

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
  List<Map<String, dynamic>> _plaquesTemporaires = [];
  List<Map<String, dynamic>> _avisRecherche = [];
  List<Map<String, dynamic>> _historiqueRetraits = [];
  Map<String, dynamic>? _proprietaire;
  Map<String, dynamic>? _proprietaireEntreprise;
  bool _loadingContraventions = false;
  bool _loadingAssurances = false;
  bool _loadingPlaquesTemporaires = false;
  bool _loadingAvisRecherche = false;
  bool _loadingHistoriqueRetraits = false;
  bool _loadingProprietaire = false;
  bool _loadingProprietaireEntreprise = false;
  String? _errorContraventions;
  String? _errorAssurances;
  String? _errorPlaquesTemporaires;
  String? _errorAvisRecherche;
  String? _errorHistoriqueRetraits;
  String? _errorProprietaire;
  String? _errorProprietaireEntreprise;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadContraventions();
    _loadAssurances();
    _loadPlaquesTemporaires();
    _loadAvisRecherche();
    _loadHistoriqueRetraits();
    _loadProprietaire();
    _loadProprietaireEntreprise();
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
      final response = await api.get(
          '/contraventions/vehicule/${widget.vehicule['id']}?username=$username');

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
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _errorContraventions = errorMessage;
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
      final response = await api.get(
          '/assurances/vehicule/${widget.vehicule['id']}?username=$username');

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
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _errorAssurances = errorMessage;
      });
    } finally {
      setState(() {
        _loadingAssurances = false;
      });
    }
  }

  Future<void> _loadPlaquesTemporaires() async {
    setState(() {
      _loadingPlaquesTemporaires = true;
      _errorPlaquesTemporaires = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api.get(
          '/plaques-temporaires/vehicule/${widget.vehicule['id']}?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _plaquesTemporaires =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      } else {
        setState(() {
          _errorPlaquesTemporaires =
              'Erreur lors du chargement des plaques temporaires';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _errorPlaquesTemporaires = errorMessage;
      });
    } finally {
      setState(() {
        _loadingPlaquesTemporaires = false;
      });
    }
  }

  Future<void> _loadAvisRecherche() async {
    setState(() {
      _loadingAvisRecherche = true;
      _errorAvisRecherche = null;
    });

    try {
      final url = Uri.parse(ApiConfig.baseUrl).replace(
        queryParameters: {
          'route': '/avis-recherche/vehicule/${widget.vehicule['id']}',
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
            _errorAvisRecherche = data['message'] ??
                'Erreur lors du chargement des avis de recherche';
          });
        }
      } else {
        setState(() {
          _errorAvisRecherche = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorAvisRecherche = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _loadingAvisRecherche = false;
      });
    }
  }

  Future<void> _loadHistoriqueRetraits() async {
    setState(() {
      _loadingHistoriqueRetraits = true;
      _errorHistoriqueRetraits = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api.get(
          '/vehicule/${widget.vehicule['id']}/historique-retraits?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historiqueRetraits =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      } else {
        setState(() {
          _errorHistoriqueRetraits =
              'Erreur lors du chargement de l\'historique';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _errorHistoriqueRetraits = errorMessage;
      });
    } finally {
      setState(() {
        _loadingHistoriqueRetraits = false;
      });
    }
  }

  Future<void> _loadProprietaire() async {
    setState(() {
      _loadingProprietaire = true;
      _errorProprietaire = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api.get(
          '/vehicule/${widget.vehicule['id']}/proprietaire?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _proprietaire = data['data'];
          });
        } else {
          setState(() {
            _proprietaire = null;
          });
        }
      } else {
        setState(() {
          _errorProprietaire = null; // Pas d'erreur si pas de propriétaire
          _proprietaire = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorProprietaire = null; // Ignorer l'erreur si pas de propriétaire
        _proprietaire = null;
      });
    } finally {
      setState(() {
        _loadingProprietaire = false;
      });
    }
  }

  Future<void> _loadProprietaireEntreprise() async {
    setState(() {
      _loadingProprietaireEntreprise = true;
      _errorProprietaireEntreprise = null;
    });

    try {
      final username = context.read<AuthProvider>().username;
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api.get(
          '/vehicule/${widget.vehicule['id']}/proprietaire-entreprise?username=$username');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _proprietaireEntreprise = data['data'];
        });
      } else {
        setState(() {
          _errorProprietaireEntreprise =
              null; // Pas d'entreprise propriétaire, ce n'est pas une erreur
        });
      }
    } catch (e) {
      setState(() {
        _errorProprietaireEntreprise =
            null; // Ignorer l'erreur si pas d'entreprise
      });
    } finally {
      setState(() {
        _loadingProprietaireEntreprise = false;
      });
    }
  }

  Future<void> _updatePaymentStatus(int contraventionId, bool isPaid) async {
    try {
      final username = context.read<AuthProvider>().username;
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/contravention/$contraventionId/update-payment'),
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
          final index =
              _contraventions.indexWhere((c) => c['id'] == contraventionId);
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
            description: Text(isPaid
                ? 'La contravention a été marquée comme payée'
                : 'La contravention a été marquée comme non payée'),
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
          description:
              Text('Impossible de mettre à jour le statut: ${e.toString()}'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: true,
        );
      }
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

  Future<void> _showAssuranceModal({bool isRenewal = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AssuranceModal(
        vehiculeId: widget.vehicule['id'],
        isRenewal: isRenewal,
        lastAssurance:
            isRenewal && _assurances.isNotEmpty ? _assurances.first : null,
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
    final valueStr = value?.toString() ?? '';
    final displayValue = (valueStr.isEmpty) ? 'N/A' : valueStr;
    final isNA = valueStr.isEmpty;
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
              color: isNA
                  ? Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5)
                  : Theme.of(context).colorScheme.onSurface,
              fontStyle: isNA ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: isMultiline ? null : 1,
            overflow:
                isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatutCirculation() {
    final enCirculation = widget.vehicule['en_circulation'];
    final isEnCirculation =
        enCirculation == 1 || enCirculation == '1' || enCirculation == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnCirculation
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnCirculation
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnCirculation ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEnCirculation ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut de circulation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnCirculation
                      ? 'En circulation'
                      : 'Retiré de la circulation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isEnCirculation
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photos du véhicule',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildVehiclePhotos(),
              const SizedBox(height: 24),
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
                    _buildFormField('Plaque', widget.vehicule['plaque'],
                        isTitle: true),
                    const SizedBox(height: 12),
                    _buildFormField('Marque', widget.vehicule['marque']),
                    const SizedBox(height: 12),
                    _buildFormField('Modèle', widget.vehicule['modele']),
                    const SizedBox(height: 12),
                    _buildFormField('Couleur', widget.vehicule['couleur']),
                    const SizedBox(height: 12),
                    _buildFormField('Année', widget.vehicule['annee']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Numéro chassis', widget.vehicule['numero_chassis']),
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
                    _buildFormField(
                        'Numéro moteur', widget.vehicule['num_moteur']),
                    const SizedBox(height: 12),
                    _buildFormField('Origine', widget.vehicule['origine']),
                    const SizedBox(height: 12),
                    _buildFormField('Source', widget.vehicule['source']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Année fabrication', widget.vehicule['annee_fab']),
                    const SizedBox(height: 12),
                    _buildFormField(
                        'Année circulation', widget.vehicule['annee_circ']),
                    const SizedBox(height: 12),
                    _buildFormField('Type EM', widget.vehicule['type_em']),
                    const SizedBox(height: 12),
                    _buildFormField('Frontière entrée',
                        widget.vehicule['frontiere_entree']),
                    const SizedBox(height: 12),
                    _buildFormField('Date importation',
                        _formatDate(widget.vehicule['date_importation'])),
                    const SizedBox(height: 12),
                    _buildFormField('Numéro déclaration',
                        widget.vehicule['numero_declaration']),
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
                child: _buildFormField('Plaque valide le',
                    _formatDate(widget.vehicule['plaque_valide_le'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Plaque expire le',
                    _formatDate(widget.vehicule['plaque_expire_le'])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatutCirculation(),

          const SizedBox(height: 16),

          // Dates système
          Text('Informations système', style: tt.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField('Date de création',
                    _formatDate(widget.vehicule['created_at'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField('Dernière modification',
                    _formatDate(widget.vehicule['updated_at'])),
              ),
            ],
          ),

          // Informations du propriétaire si disponible
          ..._buildProprietaireSection(),

          // Informations de l'entreprise propriétaire si disponible
          ..._buildProprietaireEntrepriseSection(),
        ],
      ),
    );
  }

  List<Widget> _buildProprietaireSection() {
    // N'afficher la section que si loading ou si propriétaire trouvé
    if (!_loadingProprietaire && _proprietaire == null) {
      return [];
    }

    return [
      const SizedBox(height: 24),
      const Divider(thickness: 2),
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Informations sur le propriétaire',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loadingProprietaire)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_proprietaire != null)
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
                    'Nom',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Téléphone',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Adresse',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        _proprietaire!['nom']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaire!['gsm']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaire!['email']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaire!['adresse']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showProprietaireDetails(_proprietaire!),
                            icon: const Icon(Icons.info_outline, size: 18),
                            tooltip: 'Voir détails',
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
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _assignContraventionToProprietaire(
                                _proprietaire!),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            tooltip: 'Assigner contravention',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  void _showProprietaireDetails(Map<String, dynamic> proprietaire) {
    showDialog(
      context: context,
      builder: (context) => ParticulierDetailsModal(
        particulier: proprietaire,
      ),
    );
  }

  void _assignContraventionToProprietaire(Map<String, dynamic> proprietaire) {
    showDialog(
      context: context,
      builder: (context) => AssignContraventionParticulierModal(
        particulier: proprietaire,
        onSuccess: () {
          // Recharger le propriétaire si nécessaire
          _loadProprietaire();
        },
      ),
    );
  }

  void _showEntrepriseDetails(Map<String, dynamic> entreprise) {
    showDialog(
      context: context,
      builder: (context) => EntrepriseDetailsModal(
        entreprise: entreprise,
      ),
    );
  }

  void _assignContraventionToEntreprise(Map<String, dynamic> entreprise) {
    showDialog(
      context: context,
      builder: (context) => AssignContraventionEntrepriseModal(
        dossier: entreprise,
        typeDossier: 'entreprise',
      ),
    );
  }

  List<Widget> _buildProprietaireEntrepriseSection() {
    // N'afficher que s'il y a une entreprise propriétaire
    if (!_loadingProprietaireEntreprise && _proprietaireEntreprise == null) {
      return [];
    }

    return [
      const SizedBox(height: 24),
      const Divider(thickness: 2),
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(
            Icons.business,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Informations sur le propriétaire',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loadingProprietaireEntreprise)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_proprietaireEntreprise != null)
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
                    'Désignation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Téléphone',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Siège social',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        _proprietaireEntreprise!['designation']?.toString() ??
                            'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaireEntreprise!['telephone']?.toString() ??
                            'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaireEntreprise!['email']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _proprietaireEntreprise!['siege_social']?.toString() ??
                            'N/A',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEntrepriseDetails(
                                _proprietaireEntreprise!),
                            icon: const Icon(Icons.info_outline, size: 18),
                            tooltip: 'Voir détails',
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
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _assignContraventionToEntreprise(
                                _proprietaireEntreprise!),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            tooltip: 'Assigner contravention',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildVehiclePhotos() {
    try {
      final imagesString = widget.vehicule['images']?.toString() ?? '[]';
      final List<dynamic> imagesList = jsonDecode(imagesString);

      if (imagesList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Aucune photo disponible',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: imagesList.length,
          itemBuilder: (context, index) {
            final imagePath = imagesList[index].toString();
            final imageUrl = '${ApiConfig.imageBaseUrl}$imagePath';

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(
                    imageUrl, 'Photo véhicule ${index + 1}'),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.car_rental,
                                    color: Colors.grey.shade500,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image\nindisponible',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Overlay pour indiquer que l'image est cliquable
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
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
            Text(
              'Erreur lors du chargement des photos',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      );
    }
  }

  void _showFullScreenImage(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Image en plein écran
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.car_rental,
                              color: Colors.grey.shade500,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Image indisponible',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Bouton fermer
            Positioned(
              top: 40,
              right: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Titre de l'image
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
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
                  Tab(
                    icon: Icon(Icons.access_time),
                    text: 'Plaques temp.',
                  ),
                  Tab(
                    icon: Icon(Icons.search),
                    text: 'Avis recherche',
                  ),
                  Tab(
                    icon: Icon(Icons.history),
                    text: 'Historique retraits',
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
                  _buildPlaquesTemporairesTab(),
                  _buildAvisRechercheTab(),
                  _buildHistoriqueRetraitsTab(),
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
                                  contravention['id'],
                                  value,
                                );
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  final isExpired =
                      assurance['date_expire_assurance'] != null &&
                          DateTime.parse(assurance['date_expire_assurance'])
                              .isBefore(DateTime.now());

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

  Widget _buildPlaquesTemporairesTab() {
    if (_loadingPlaquesTemporaires) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorPlaquesTemporaires != null) {
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
                _errorPlaquesTemporaires!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPlaquesTemporaires,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_plaquesTemporaires.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune plaque temporaire',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce véhicule n\'a aucune plaque temporaire enregistrée.',
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
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historique des plaques temporaires (${_plaquesTemporaires.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tableau des plaques temporaires
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
                headingRowColor: WidgetStateProperty.all(
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
                rows: _plaquesTemporaires.map((plaque) {
                  final dateDebut = _formatDate(plaque['date_debut']);
                  final dateFin = _formatDate(plaque['date_fin']);
                  final isExpired = _isPlaqueExpired(plaque['date_fin']);
                  final statut = plaque['statut'] ?? 'actif';

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            plaque['numero'] ?? '',
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
                            plaque['motif'] ?? '',
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
                            onPressed: () => _viewPlaqueTemporairePdf(plaque),
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

  bool _isPlaqueExpired(String? dateFin) {
    if (dateFin == null) return false;
    try {
      final date = DateTime.parse(dateFin);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _viewPlaqueTemporairePdf(Map<String, dynamic> plaque) async {
    final plaqueId = plaque['id'];
    final previewUrl =
        "${ApiConfig.imageBaseUrl}/api/plaque_temporaire_display.php?id=$plaqueId";

    try {
      final uri = Uri.parse(previewUrl);

      // Essayer d'abord avec le mode externe
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // Si ça échoue, essayer avec le mode par défaut
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e2) {
          // En dernier recours, essayer avec webViewOrSafari
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        }
      }

      if (launched) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Prévisualisation ouverte'),
          description: Text(
              'Plaque ${plaque['numero']} ouverte dans une nouvelle fenêtre'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: true,
        );
      } else {
        // Si toutes les tentatives échouent, afficher l'URL
        _showUrlFallback(previewUrl);
      }
    } catch (e) {
      // En cas d'erreur générale, afficher l'URL
      _showUrlFallback(previewUrl);
    }
  }

  void _showUrlFallback(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévisualisation de la plaque'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Copiez cette URL dans votre navigateur pour voir la plaque temporaire:'),
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

  Widget _buildAvisRechercheTab() {
    if (_loadingAvisRecherche) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorAvisRecherche != null) {
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
                _errorAvisRecherche!,
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
                'Ce véhicule n\'a aucun avis de recherche enregistré.',
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

  Widget _buildHistoriqueRetraitsTab() {
    if (_loadingHistoriqueRetraits) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorHistoriqueRetraits != null) {
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
                _errorHistoriqueRetraits!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadHistoriqueRetraits,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historiqueRetraits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun retrait de plaque',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aucune plaque n\'a été retirée pour ce véhicule.',
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
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historique des retraits (${_historiqueRetraits.length})',
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
                dataRowMaxHeight: 70,
                columns: const [
                  DataColumn(
                      label: Expanded(
                          flex: 1,
                          child: Text('ID',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Plaque retirée',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Date retrait',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)))),
                  DataColumn(
                      label: Expanded(
                          flex: 2,
                          child: Text('Motif',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)))),
                  DataColumn(
                      label: Expanded(
                          flex: 3,
                          child: Text('Observations',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)))),
                ],
                rows: _historiqueRetraits.map((historique) {
                  final dateRetrait = _formatDate(historique['date_retrait']);
                  final plaque = historique['ancienne_plaque'] ?? 'N/A';
                  final motif = historique['motif'] ?? '-';
                  final observations = historique['observations'] ?? '-';

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text('#${historique['id']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 12)),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            plaque,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            dateRetrait,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            motif,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          child: Text(
                            observations,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
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
      _societeController.text =
          widget.lastAssurance!['societe_assurance']?.toString() ?? '';
      _typeController.text =
          widget.lastAssurance!['type_couverture']?.toString() ?? '';
      _primeController.text =
          widget.lastAssurance!['montant_prime']?.toString() ?? '';
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
      builder: buildThemedPicker,
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
        description:
            const Text('Veuillez sélectionner les dates de début et de fin'),
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
          'date_valide_assurance':
              '${_dateDebut!.year}-${_dateDebut!.month.toString().padLeft(2, '0')}-${_dateDebut!.day.toString().padLeft(2, '0')}',
          'date_expire_assurance':
              '${_dateFin!.year}-${_dateFin!.month.toString().padLeft(2, '0')}-${_dateFin!.day.toString().padLeft(2, '0')}',
          'montant_prime':
              _primeController.text.isNotEmpty ? _primeController.text : null,
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
            title: Text(widget.isRenewal
                ? 'Assurance renouvelée'
                : 'Assurance ajoutée'),
            description: Text(widget.isRenewal
                ? 'L\'assurance a été renouvelée avec succès'
                : 'L\'assurance a été ajoutée avec succès'),
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
                      widget.isRenewal
                          ? 'Renouveler l\'assurance'
                          : 'Ajouter une assurance',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
