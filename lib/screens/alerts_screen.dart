import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/particulier_details_modal.dart';
import '../widgets/vehicule_details_modal.dart';
import '../widgets/entreprise_details_modal.dart';
import '../services/particulier_service.dart';
import '../services/entreprise_service.dart';
import '../services/vehicule_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Variables pour les filtres
  final Set<String> _activeFilters = <String>{};
  bool _showFilters = false;

  // Types d'alertes disponibles
  final Map<String, Map<String, dynamic>> _filterTypes = {
    'avis_recherche': {
      'label': 'Avis de recherche',
      'icon': Icons.search,
      'color': Colors.red,
    },
    'assurances_expirees': {
      'label': 'Assurances expirées',
      'icon': Icons.shield_outlined,
      'color': Colors.orange,
    },
    'permis_temporaires_expires': {
      'label': 'Permis temporaires expirés',
      'icon': Icons.card_membership_outlined,
      'color': Colors.purple,
    },
    'plaques_expirees': {
      'label': 'Plaques expirées',
      'icon': Icons.directions_car_outlined,
      'color': Colors.blue,
    },
    'permis_conduire_expires': {
      'label': 'Permis de conduire expirés',
      'icon': Icons.credit_card_outlined,
      'color': Colors.indigo,
    },
    'contraventions_non_payees': {
      'label': 'Contraventions non payées',
      'icon': Icons.receipt_long_outlined,
      'color': Colors.deepOrange,
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
  }

  void _loadAlerts() {
    final authProvider = context.read<AuthProvider>();
    final alertProvider = context.read<AlertProvider>();
    alertProvider.loadAlerts(authProvider.username);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return dateStr;
    }
  }

  // Méthodes de filtrage
  bool _shouldShowSection(String filterKey, List<dynamic> items) {
    if (_activeFilters.isEmpty) return items.isNotEmpty;
    return _activeFilters.contains(filterKey) && items.isNotEmpty;
  }

  void _toggleFilter(String filterKey) {
    setState(() {
      if (_activeFilters.contains(filterKey)) {
        _activeFilters.remove(filterKey);
      } else {
        _activeFilters.add(filterKey);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
    });
  }

  // Méthode pour ouvrir les modals de détails
  Future<void> _showParticulierDetails(int particulierId) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
      final service = ParticulierService(apiClient);
      final particulier = await service.getParticulierById(particulierId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader

      if (particulier != null) {
        showDialog(
          context: context,
          builder: (context) =>
              ParticulierDetailsModal(particulier: particulier),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Particulier introuvable')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showVehiculeDetails(int vehiculeId) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('🚗 Recherche véhicule avec ID: $vehiculeId'); // Debug
      final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
      final service = VehiculeService(apiClient: apiClient);
      final vehicule = await service.getVehiculeById(vehiculeId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader

      if (vehicule != null) {
        print('✅ Véhicule trouvé: ${vehicule['plaque']}'); // Debug
        showDialog(
          context: context,
          builder: (context) => VehiculeDetailsModal(vehicule: vehicule),
        );
      } else {
        print('❌ Véhicule non trouvé pour ID: $vehiculeId'); // Debug
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Véhicule introuvable (ID: $vehiculeId)')),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du véhicule: $e'); // Debug
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showEntrepriseDetails(int entrepriseId) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
      final service = EntrepriseService(apiClient);
      final entreprise = await service.getEntrepriseById(entrepriseId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader

      if (entreprise != null) {
        showDialog(
          context: context,
          builder: (context) => EntrepriseDetailsModal(entreprise: entreprise),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entreprise introuvable')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  int _getFilteredAlertsCount(AlertProvider alertProvider) {
    if (_activeFilters.isEmpty) return alertProvider.totalAlerts;

    int count = 0;
    if (_activeFilters.contains('avis_recherche')) {
      count += alertProvider.avisRechercheActifs.length;
    }
    if (_activeFilters.contains('assurances_expirees')) {
      count += alertProvider.assurancesExpirees.length;
    }
    if (_activeFilters.contains('permis_temporaires_expires')) {
      count += alertProvider.permisTemporairesExpires.length;
    }
    if (_activeFilters.contains('plaques_expirees')) {
      count += alertProvider.plaquesExpirees.length;
    }
    if (_activeFilters.contains('permis_conduire_expires')) {
      count += alertProvider.permisConduireExpires.length;
    }
    if (_activeFilters.contains('contraventions_non_payees')) {
      count += alertProvider.contraventionsNonPayees.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip:
                _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          if (alertProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (alertProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    alertProvider.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadAlerts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (alertProvider.totalAlerts == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte active',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tout est en ordre !',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                alertProvider.refresh(context.read<AuthProvider>().username),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec compteur total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 24, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_getFilteredAlertsCount(alertProvider)} alerte(s) active(s)' +
                                (_activeFilters.isNotEmpty
                                    ? ' (filtrées)'
                                    : ''),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section des filtres
                  if (_showFilters) ...[
                    _buildFiltersSection(alertProvider),
                    const SizedBox(height: 16),
                  ],

                  // 1. Avis de recherche actifs
                  if (_shouldShowSection(
                      'avis_recherche', alertProvider.avisRechercheActifs)) ...[
                    _buildSectionHeader(
                      context,
                      'Avis de recherche actifs',
                      alertProvider.avisRechercheActifs.length,
                      Icons.search,
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.avisRechercheActifs
                        .map((avis) => _buildAvisRechercheCard(context, avis)),
                    const SizedBox(height: 24),
                  ],

                  // 2. Assurances expirées
                  if (_shouldShowSection('assurances_expirees',
                      alertProvider.assurancesExpirees)) ...[
                    _buildSectionHeader(
                      context,
                      'Assurances expirées',
                      alertProvider.assurancesExpirees.length,
                      Icons.shield_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.assurancesExpirees.map(
                        (assurance) => _buildAssuranceCard(context, assurance)),
                    const SizedBox(height: 24),
                  ],

                  // 3. Permis temporaires expirés
                  if (_shouldShowSection('permis_temporaires_expires',
                      alertProvider.permisTemporairesExpires)) ...[
                    _buildSectionHeader(
                      context,
                      'Permis temporaires expirés',
                      alertProvider.permisTemporairesExpires.length,
                      Icons.card_membership_outlined,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.permisTemporairesExpires.map((permis) =>
                        _buildPermisTemporaireCard(context, permis)),
                    const SizedBox(height: 24),
                  ],

                  // 4. Plaques expirées
                  if (_shouldShowSection(
                      'plaques_expirees', alertProvider.plaquesExpirees)) ...[
                    _buildSectionHeader(
                      context,
                      'Plaques d\'immatriculation expirées',
                      alertProvider.plaquesExpirees.length,
                      Icons.directions_car_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.plaquesExpirees
                        .map((plaque) => _buildPlaqueCard(context, plaque)),
                    const SizedBox(height: 24),
                  ],

                  // 5. Permis de conduire expirés
                  if (_shouldShowSection('permis_conduire_expires',
                      alertProvider.permisConduireExpires)) ...[
                    _buildSectionHeader(
                      context,
                      'Permis de conduire expirés',
                      alertProvider.permisConduireExpires.length,
                      Icons.badge_outlined,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.permisConduireExpires.map(
                        (permis) => _buildPermisConduireCard(context, permis)),
                    const SizedBox(height: 24),
                  ],

                  // 6. Contraventions non payées
                  if (_shouldShowSection('contraventions_non_payees',
                      alertProvider.contraventionsNonPayees)) ...[
                    _buildSectionHeader(
                      context,
                      'Contraventions non payées',
                      alertProvider.contraventionsNonPayees.length,
                      Icons.receipt_long_outlined,
                      Colors.deepOrange,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.contraventionsNonPayees.map(
                        (contravention) =>
                            _buildContraventionCard(context, contravention)),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisRechercheCard(
      BuildContext context, Map<String, dynamic> avis) {
    final theme = Theme.of(context);
    final cibleDetails = avis['cible_details'];
    final isVehicule = avis['cible_type'] == 'vehicule_plaque';

    // Vérifier que cibleDetails est bien un Map
    final Map<String, dynamic>? safeDetails =
        (cibleDetails is Map<String, dynamic>) ? cibleDetails : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVehicule
                    ? Icons.directions_car_outlined
                    : Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVehicule
                          ? 'Véhicule: ${safeDetails?['plaque'] ?? 'N/A'}'
                          : 'Particulier: ${safeDetails?['nom'] ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (isVehicule && safeDetails != null)
                      Text(
                        '${safeDetails['marque']} ${safeDetails['modele'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    if (!isVehicule && safeDetails != null)
                      Text(
                        'Tél: ${safeDetails['gsm'] ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                avis['niveau'] ?? 'Moyen',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            avis['motif'] ?? 'Aucun motif spécifié',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Émis le: ${_formatDate(avis['created_at'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final cibleId = avis['cible_id'];
                  if (cibleId != null) {
                    final id = cibleId is int
                        ? cibleId
                        : int.tryParse(cibleId.toString());
                    if (id != null) {
                      if (isVehicule) {
                        _showVehiculeDetails(id);
                      } else {
                        _showParticulierDetails(id);
                      }
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceCard(
      BuildContext context, Map<String, dynamic> assurance) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assurance['plaque'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${assurance['marque']} ${assurance['modele'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${assurance['societe_assurance'] ?? 'N/A'} - ${assurance['nume_assurance'] ?? 'N/A'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expirée le: ${_formatDate(assurance['date_expire_assurance'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Essayer d'abord vehicule_id, puis vehicule_plaque_id comme fallback
                  final vehiculeId = assurance['vehicule_id'] ??
                      assurance['vehicule_plaque_id'];
                  if (vehiculeId != null) {
                    final id = vehiculeId is int
                        ? vehiculeId
                        : int.tryParse(vehiculeId.toString());
                    if (id != null) {
                      _showVehiculeDetails(id);
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermisTemporaireCard(
      BuildContext context, Map<String, dynamic> permis) {
    final theme = Theme.of(context);
    final isVehicule = permis['cible_type'] == 'vehicule_plaque';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVehicule
                    ? Icons.directions_car_outlined
                    : Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (permis['numero'] is String) ? permis['numero'] : 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      (permis['cible_nom'] is String)
                          ? permis['cible_nom']
                          : 'N/A',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (permis['motif'] is String) ? permis['motif'] : 'N/A',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiré le: ${_formatDate(permis['date_fin'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final cibleId = permis['cible_id'];
                  if (cibleId != null) {
                    final id = cibleId is int
                        ? cibleId
                        : int.tryParse(cibleId.toString());
                    if (id != null) {
                      if (isVehicule) {
                        _showVehiculeDetails(id);
                      } else {
                        _showParticulierDetails(id);
                      }
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaqueCard(BuildContext context, Map<String, dynamic> plaque) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plaque['plaque'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${plaque['marque']} ${plaque['modele'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plaque['couleur'] ?? 'N/A'} • ${plaque['annee'] ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expirée le: ${_formatDate(plaque['plaque_expire_le'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final vehiculeId = plaque['id'];
                  if (vehiculeId != null) {
                    final id = vehiculeId is int
                        ? vehiculeId
                        : int.tryParse(vehiculeId.toString());
                    if (id != null) {
                      _showVehiculeDetails(id);
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermisConduireCard(
      BuildContext context, Map<String, dynamic> permis) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (permis['nom'] is String) ? permis['nom'] : 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tél: ${(permis['gsm'] is String) ? permis['gsm'] : 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (permis['adresse'] is String &&
              permis['adresse'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              permis['adresse'].toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiré le: ${_formatDate(permis['permis_date_expiration'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final particulierId = permis['id'];
                  if (particulierId != null) {
                    final id = particulierId is int
                        ? particulierId
                        : int.tryParse(particulierId.toString());
                    if (id != null) {
                      _showParticulierDetails(id);
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContraventionCard(
      BuildContext context, Map<String, dynamic> contravention) {
    final theme = Theme.of(context);
    final typeDossier = contravention['type_dossier'];
    final isEntreprise = typeDossier == 'entreprise';
    final isVehicule = typeDossier == 'vehicule_plaque';

    // Déterminer l'icône appropriée
    IconData icon;
    if (isVehicule) {
      icon = Icons.directions_car_outlined;
    } else if (isEntreprise) {
      icon = Icons.business_outlined;
    } else {
      icon = Icons.person_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (contravention['nom_contrevenant'] is String)
                          ? contravention['nom_contrevenant']
                          : 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (contravention['telephone_contrevenant'] is String)
                      Text(
                        'Tél: ${contravention['telephone_contrevenant']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              if (contravention['amende'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${contravention['amende']} FC',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[300],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (contravention['type_infraction'] != null) ...[
            Text(
              contravention['type_infraction'],
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (contravention['lieu'] != null) ...[
            Text(
              'Lieu: ${contravention['lieu']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Infraction du: ${_formatDate(contravention['date_infraction'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Pour les véhicules, utiliser vehicule_id puis dossier_id comme fallback
                  final dossierId = isVehicule 
                      ? (contravention['vehicule_id'] ?? contravention['dossier_id'])
                      : contravention['dossier_id'];
                  
                  print('🔍 Contravention type: ${contravention['type_dossier']}, dossier_id: ${contravention['dossier_id']}, vehicule_id: ${contravention['vehicule_id']}, utilisé: $dossierId'); // Debug
                  
                  if (dossierId != null) {
                    final id = dossierId is int
                        ? dossierId
                        : int.tryParse(dossierId.toString());
                    if (id != null) {
                      if (isEntreprise) {
                        _showEntrepriseDetails(id);
                      } else if (contravention['type_dossier'] ==
                          'particulier') {
                        _showParticulierDetails(id);
                      } else if (isVehicule) {
                        _showVehiculeDetails(id);
                      }
                    }
                  }
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section des filtres
  Widget _buildFiltersSection(AlertProvider alertProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filtrer les alertes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_activeFilters.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all,
                      size: 16, color: Colors.white70),
                  label: const Text(
                    'Tout effacer',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filterTypes.entries.map((entry) {
              final filterKey = entry.key;
              final filterData = entry.value;
              final isActive = _activeFilters.contains(filterKey);
              final count = _getAlertCountForFilter(alertProvider, filterKey);

              return FilterChip(
                selected: isActive,
                onSelected:
                    count > 0 ? (selected) => _toggleFilter(filterKey) : null,
                avatar: Icon(
                  filterData['icon'] as IconData,
                  size: 16,
                  color: count > 0
                      ? (isActive ? Colors.white : filterData['color'] as Color)
                      : Colors.grey,
                ),
                label: Text(
                  '${filterData['label']} ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    color: count > 0
                        ? (isActive ? Colors.white : Colors.white70)
                        : Colors.grey,
                  ),
                ),
                backgroundColor: count > 0
                    ? (filterData['color'] as Color).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                selectedColor: filterData['color'] as Color,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: count > 0
                      ? (filterData['color'] as Color).withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
                disabledColor: Colors.grey.withOpacity(0.1),
              );
            }).toList(),
          ),
          if (_activeFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_activeFilters.length} filtre(s) actif(s) - ${_getFilteredAlertsCount(alertProvider)} alerte(s) affichée(s)',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getAlertCountForFilter(AlertProvider alertProvider, String filterKey) {
    switch (filterKey) {
      case 'avis_recherche':
        return alertProvider.avisRechercheActifs.length;
      case 'assurances_expirees':
        return alertProvider.assurancesExpirees.length;
      case 'permis_temporaires_expires':
        return alertProvider.permisTemporairesExpires.length;
      case 'plaques_expirees':
        return alertProvider.plaquesExpirees.length;
      case 'permis_conduire_expires':
        return alertProvider.permisConduireExpires.length;
      case 'contraventions_non_payees':
        return alertProvider.contraventionsNonPayees.length;
      default:
        return 0;
    }
  }
}
