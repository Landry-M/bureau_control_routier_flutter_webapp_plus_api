import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/vehicule_provider.dart';
import '../providers/particulier_provider.dart';
import '../providers/entreprise_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../widgets/top_bar.dart';
import '../widgets/assign_contravention_entreprise_modal.dart';
import '../widgets/assign_contravention_particulier_modal.dart';
import '../widgets/consigner_arrestation_modal.dart';
import '../widgets/emettre_avis_recherche_modal.dart';
import '../widgets/generer_permis_temporaire_modal.dart';
import '../widgets/plaque_temporaire_modal.dart';
import '../widgets/edit_entreprise_modal.dart';
import '../widgets/edit_particulier_modal.dart';
import '../widgets/entreprise_details_modal.dart';
import '../widgets/particulier_details_modal.dart';
import '../widgets/particulier_actions_modal.dart';
import '../widgets/vehicule_actions_modal.dart';
import '../widgets/edit_vehicule_modal.dart';
import '../widgets/vehicule_details_modal.dart';
import '../widgets/retirer_plaque_modal.dart';
import '../widgets/transfert_proprietaire_modal.dart';
import '../widgets/recherche_proprietaire_modal.dart';

class AllRecordsScreen extends StatefulWidget {
  const AllRecordsScreen({super.key});

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.value(context,
                        mobile: 16.0, tablet: 24.0, desktop: 32.0),
                    vertical: Responsive.value(context,
                        mobile: 12.0, tablet: 16.0, desktop: 20.0),
                  ),
                  child: const TopBar(),
                ),

                // Titre avec flèche de retour
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                        tooltip: 'Retour',
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.folder_open, size: 28, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consulter tous les dossiers',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.directions_car),
                          text: 'Véhicules & Plaques'),
                      Tab(icon: Icon(Icons.person), text: 'Particuliers'),
                      Tab(icon: Icon(Icons.business), text: 'Entreprises'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      VehiclesTab(),
                      ParticuliersTab(),
                      EntreprisesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Onglet Véhicules
class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculeProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditVehicleModal(Map<String, dynamic> vehicle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditVehiculeModal(vehicule: vehicle),
    );

    if (result == true) {
      // Rafraîchir la liste des véhicules si la modification a réussi
      if (mounted) {
        context.read<VehiculeProvider>().refresh();
      }
    }
  }

  void _showVehicleActionsModal(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => VehiculeActionsModal(
        vehicule: vehicle,
        onSanctionner: () => _sanctionnerVehicule(vehicle),
        onChangerProprietaire: () => _changerProprietaire(vehicle),
        onRetirerVehicule: () => _retirerVehicule(vehicle),
        onRetirerPlaque: () => _retirerPlaque(vehicle),
        onPlaqueTemporaire: () => _plaqueTemporaire(vehicle),
        onEmettreAvis: () => _emettreAvisRechercheVehicule(vehicle),
      ),
    );
  }

  void _sanctionnerVehicule(Map<String, dynamic> vehicle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AssignContraventionEntrepriseModal.vehicule(vehicule: vehicle),
    );

    if (result == true) {
      // Rafraîchir la liste des véhicules après assignation réussie
      if (mounted) {
        context.read<VehiculeProvider>().refresh();
      }
    }
  }

  void _changerProprietaire(Map<String, dynamic> vehicle) async {
    // Étape 1: Rechercher et sélectionner un particulier ou une entreprise
    final proprietaireResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const RechercheProprietaireModal(),
    );
    
    if (proprietaireResult == null) return;
    
    final type = proprietaireResult['type']; // 'particulier' ou 'entreprise'
    final id = proprietaireResult['id'];
    final data = proprietaireResult['data'];
    
    // Étape 2: Afficher la modal de transfert (date et notes)
    final transfertResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TransfertProprietaireModal(
        vehicule: vehicle,
        isEntreprise: type == 'entreprise',
      ),
    );
    
    if (transfertResult == null) return;
    
    // Étape 3: Envoyer à l'API selon le type (avec gestion de confirmation)
    await _processAssociation(vehicle, type, id, data, transfertResult, false);
  }

  Future<void> _processAssociation(
    Map<String, dynamic> vehicle,
    String type,
    int id,
    Map<String, dynamic> data,
    Map<String, dynamic> transfertResult,
    bool force,
  ) async {
    try {
      final username = context.read<AuthProvider>().username;
      final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
      
      final endpoint = type == 'particulier' 
          ? '/particulier-vehicule/associer'
          : '/entreprise-vehicule/associer';
      
      final requestData = type == 'particulier'
          ? {
              'particulier_id': id,
              'vehicule_plaque_id': vehicle['id'],
              'role': transfertResult['role'],
              'date_assoc': transfertResult['date_assoc'],
              'notes': transfertResult['notes'],
              'username': username,
              'force': force,
            }
          : {
              'entreprise_id': id,
              'vehicule_plaque_id': vehicle['id'],
              'date_assoc': transfertResult['date_assoc'],
              'notes': transfertResult['notes'],
              'username': username,
              'force': force,
            };
      
      final response = await apiClient.postJson(endpoint, requestData);
      final responseData = json.decode(response.body);
      
      if (mounted) {
        // Si nécessite confirmation, afficher le dialogue
        if (responseData['requiresConfirmation'] == true) {
          final currentOwner = responseData['currentOwner'];
          final String ownerInfo;
          
          if (currentOwner != null) {
            if (currentOwner['owner_type'] == 'particulier') {
              ownerInfo = '${currentOwner['nom']} ${currentOwner['prenom'] ?? ''}';
            } else {
              ownerInfo = currentOwner['designation'] ?? 'Entreprise';
            }
          } else {
            ownerInfo = 'un propriétaire';
          }
          
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Véhicule déjà affecté'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ce véhicule est déjà affecté à $ownerInfo.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Historique des affectations: ${responseData['existingAssociations']['totalCount']} enregistrement(s)',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Particuliers: ${responseData['existingAssociations']['countParticulier']}',
                  ),
                  Text(
                    '• Entreprises: ${responseData['existingAssociations']['countEntreprise']}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Voulez-vous continuer et créer une nouvelle affectation ?',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L\'historique complet sera préservé.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmer l\'affectation'),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            // Réessayer avec force = true
            await _processAssociation(vehicle, type, id, data, transfertResult, true);
          }
        } else if (responseData['success'] == true) {
          final nom = type == 'particulier'
              ? '${data['nom']} ${data['prenom']}'
              : data['designation'];
          
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Association réussie'),
            description: Text('$nom a été associé(e) au véhicule ${vehicle['plaque']}'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );
          
          // Rafraîchir la liste
          context.read<VehiculeProvider>().refresh();
        } else {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Erreur'),
            description: Text(responseData['message'] ?? 'Erreur lors de l\'association'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur'),
          description: Text('Erreur de connexion: $e'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: true,
        );
      }
    }
  }

  void _retirerVehicule(Map<String, dynamic> vehicle) async {
    // Confirmation avant retrait
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le retrait de circulation'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer le véhicule "${vehicle['plaque'] ?? 'N/A'}" de la circulation ?\n\n'
          'Cette action marquera le véhicule comme non autorisé à circuler.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer de la circulation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Appel API pour retirer le véhicule de la circulation
      final response = await _retirerVehiculeCirculationAPI(vehicle['id']);

      if (response['success'] == true) {
        // Succès
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Véhicule retiré'),
            description: Text(response['message'] ??
                'Le véhicule a été retiré de la circulation avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );

          // Rafraîchir la liste des véhicules
          context.read<VehiculeProvider>().refresh();
        }
      } else {
        // Erreur
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Erreur'),
            description: Text(
                response['message'] ?? 'Erreur lors du retrait du véhicule'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: true,
          );
        }
      }
    } catch (e) {
      // Erreur de connexion
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur de connexion'),
          description: Text('Impossible de retirer le véhicule: $e'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: true,
        );
      }
    }
  }

  Future<Map<String, dynamic>> _retirerVehiculeCirculationAPI(
      int vehiculeId) async {
    final username = context.read<AuthProvider>().username;
    final response = await http.post(
      Uri.parse(
          '${ApiConfig.baseUrl}/vehicule/$vehiculeId/retirer-circulation'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
      }),
    );

    return json.decode(response.body);
  }

  void _retirerPlaque(Map<String, dynamic> vehicle) async {
    // Afficher la modal de retrait avec date et motif
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RetirerPlaqueModal(vehicule: vehicle),
    );

    if (result == null) return;

    try {
      // Appel API pour retirer la plaque avec les informations
      final response = await _retirerPlaqueAPI(
        vehicle['id'],
        result['dateRetrait'],
        result['motif'],
        result['observations'],
      );

      if (response['success'] == true) {
        // Succès
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Plaque retirée'),
            description: Text(
                response['message'] ?? 'La plaque a été retirée avec succès'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
          );

          // Rafraîchir la liste des véhicules
          context.read<VehiculeProvider>().refresh();
        }
      } else {
        // Erreur
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Erreur'),
            description: Text(
                response['message'] ?? 'Erreur lors du retrait de la plaque'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: true,
          );
        }
      }
    } catch (e) {
      // Erreur de connexion
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Erreur de connexion'),
          description: Text('Impossible de retirer la plaque: $e'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: true,
        );
      }
    }
  }

  Future<Map<String, dynamic>> _retirerPlaqueAPI(
    int vehiculeId,
    String dateRetrait,
    String motif,
    String observations,
  ) async {
    final username = context.read<AuthProvider>().username;
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    final response = await apiClient.postJson(
      '/vehicule/$vehiculeId/retirer-plaque',
      {
        'username': username,
        'date_retrait': dateRetrait,
        'motif': motif,
        'observations': observations,
      },
    );

    return json.decode(response.body);
  }

  void _plaqueTemporaire(Map<String, dynamic> vehicle) async {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PlaqueTemporaireModal(vehicule: vehicle),
    );

    if (result == true) {
      // Rafraîchir la liste des véhicules après génération réussie
      if (mounted) {
        context.read<VehiculeProvider>().refresh();
      }
    }
  }

  void _emettreAvisRechercheVehicule(Map<String, dynamic> vehicle) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => EmettreAvisRechercheModal(
        cible: vehicle,
        cibleType: 'vehicule_plaque',
        onSuccess: () {
          // Rafraîchir la liste des véhicules après succès
          context.read<VehiculeProvider>().refresh();
        },
      ),
    );
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => VehiculeDetailsModal(vehicule: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<VehiculeProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Erreur de chargement', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(provider.error!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (provider.all.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car,
                    size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('Aucun véhicule trouvé',
                    style: theme.textTheme.titleLarge),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(), // Espace vide à gauche
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Rechercher par plaque, marque, modèle, couleur...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<VehiculeProvider>()
                                      .clearSearch();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<VehiculeProvider>().search(value);
                        setState(() {}); // Pour mettre à jour l'icône clear
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(), // Espace vide à droite
                  ),
                ],
              ),
            ),

            // Tableau des données
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Column(
                        children: [
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_car,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Liste des véhicules (${provider.displayedItems.length})',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (provider.totalPages > 1)
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: provider.page > 1
                                            ? () => provider.previousPage()
                                            : null,
                                        icon: const Icon(Icons.chevron_left),
                                      ),
                                      Text(
                                          '${provider.page} / ${provider.totalPages}'),
                                      IconButton(
                                        onPressed:
                                            provider.page < provider.totalPages
                                                ? () => provider.nextPage()
                                                : null,
                                        icon: const Icon(Icons.chevron_right),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: WidgetStateProperty.all(
                                theme.colorScheme.surfaceContainer
                                    .withValues(alpha: 0.5),
                              ),
                              columns: const [
                                DataColumn(
                                    label: Text('Plaque',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Marque',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Modèle',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Couleur',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Actions',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: provider.pageItems.map((vehicle) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          vehicle['plaque'] ?? 'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(vehicle['marque'] ?? 'N/A')),
                                    DataCell(Text(vehicle['modele'] ?? 'N/A')),
                                    DataCell(Text(vehicle['couleur'] ?? 'N/A')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility,
                                                color: Colors.white),
                                            tooltip: 'Voir les détails',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.grey[700],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _showVehicleDetails(vehicle),
                                          ),
                                          const SizedBox(width: 8),
                                          if (context
                                                  .watch<AuthProvider>()
                                                  .role ==
                                              'superadmin')
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.white),
                                              tooltip: 'Modifier',
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[800],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _showEditVehicleModal(
                                                      vehicle),
                                            ),
                                          if (context
                                                  .watch<AuthProvider>()
                                                  .role ==
                                              'superadmin')
                                            const SizedBox(width: 8),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert,
                                                color: Colors.white),
                                            tooltip: 'Actions supplémentaires',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.grey[900],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _showVehicleActionsModal(
                                                    vehicle),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Onglet Particuliers
class ParticuliersTab extends StatefulWidget {
  const ParticuliersTab({super.key});

  @override
  State<ParticuliersTab> createState() => _ParticuliersTabState();
}

class _ParticuliersTabState extends State<ParticuliersTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParticulierProvider>().fetchParticuliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditParticulierModal(Map<String, dynamic> particulier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditParticulierModal(
        particulier: particulier,
        onSuccess: () {
          // Rafraîchir la liste des particuliers après modification
          context.read<ParticulierProvider>().refresh();
        },
      ),
    );
  }

  void _showParticulierActionsModal(Map<String, dynamic> particulier) {
    showDialog(
      context: context,
      builder: (context) => ParticulierActionsModal(
        particulier: particulier,
        onEmettrePermis: () => _emettrePermisTemporaire(particulier),
        onAssocierVehicule: () => _associerVehicule(particulier),
        onCreerContravention: () =>
            _createContraventionForParticulier(particulier),
        onConsignerArrestation: () => _consignerArrestation(particulier),
        onEmettreAvisRecherche: () => _emettreAvisRechercheParticulier(particulier),
      ),
    );
  }

  void _createContraventionForParticulier(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => AssignContraventionParticulierModal(
        particulier: particulier,
        onSuccess: () {
          // Rafraîchir la liste des particuliers après succès
          context.read<ParticulierProvider>().refresh();
        },
      ),
    );
  }

  void _emettrePermisTemporaire(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => GenererPermisTemporaireModal(
        particulier: particulier,
        onSuccess: () {
          // Rafraîchir la liste des particuliers après succès
          context.read<ParticulierProvider>().refresh();
        },
      ),
    );
  }

  void _associerVehicule(Map<String, dynamic> particulier) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: const Text('Fonctionnalité en développement'),
      description: const Text(
          'La fonctionnalité d\'association de véhicule est en cours de développement'),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
    );
  }

  void _consignerArrestation(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => ConsignerArrestationModal(
        particulier: particulier,
        onSuccess: () {
          // Rafraîchir la liste des particuliers après succès
          context.read<ParticulierProvider>().refresh();
        },
      ),
    );
  }

  void _emettreAvisRechercheParticulier(Map<String, dynamic> particulier) {
    Navigator.of(context).pop(); // Fermer la modal d'actions
    showDialog(
      context: context,
      builder: (context) => EmettreAvisRechercheModal(
        cible: particulier,
        cibleType: 'particuliers',
        onSuccess: () {
          // Rafraîchir la liste des particuliers après succès
          context.read<ParticulierProvider>().refresh();
        },
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> particulier) {
    showDialog(
      context: context,
      builder: (context) => ParticulierDetailsModal(particulier: particulier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(), // Espace vide à gauche
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, téléphone, permis...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<ParticulierProvider>()
                                  .fetchParticuliers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    context
                        .read<ParticulierProvider>()
                        .searchParticuliers(value);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(), // Espace vide à droite
              ),
            ],
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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[400]),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun particulier trouvé',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Utilisez le menu principal pour ajouter un particulier',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Liste des particuliers (${provider.totalCount})',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (provider.totalPages > 1)
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: provider.currentPage > 1
                                          ? provider.loadPreviousPage
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text(
                                        '${provider.currentPage} / ${provider.totalPages}'),
                                    IconButton(
                                      onPressed: provider.currentPage <
                                              provider.totalPages
                                          ? provider.loadNextPage
                                          : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainer
                                  .withValues(alpha: 0.5),
                            ),
                            columns: const [
                              DataColumn(
                                  label: Text('ID',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Nom',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Téléphone',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Adresse',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Profession',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: provider.particuliers.map((particulier) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      particulier['id']?.toString() ?? '')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        particulier['nom']?.toString() ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      particulier['gsm']?.toString() ?? 'N/A')),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        particulier['adresse']?.toString() ??
                                            'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      particulier['profession']?.toString() ??
                                          'N/A')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              color: Colors.white),
                                          tooltip: 'Voir les détails',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[700],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showDetailsDialog(particulier),
                                        ),
                                        const SizedBox(width: 8),
                                        if (context
                                                .watch<AuthProvider>()
                                                .role ==
                                            'superadmin')
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.white),
                                            tooltip: 'Modifier',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.grey[800],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _showEditParticulierModal(
                                                    particulier),
                                          ),
                                        if (context
                                                .watch<AuthProvider>()
                                                .role ==
                                            'superadmin')
                                          const SizedBox(width: 8),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert,
                                              color: Colors.white),
                                          tooltip: 'Actions supplémentaires',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[900],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showParticulierActionsModal(
                                                  particulier),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Onglet Entreprises
class EntreprisesTab extends StatefulWidget {
  const EntreprisesTab({super.key});

  @override
  State<EntreprisesTab> createState() => _EntreprisesTabState();
}

class _EntreprisesTabState extends State<EntreprisesTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntrepriseProvider>().fetchEntreprises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditEntrepriseModal(Map<String, dynamic> entreprise) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditEntrepriseModal(entreprise: entreprise),
    );

    if (result == true) {
      // Rafraîchir la liste des entreprises si la modification a réussi
      if (mounted) {
        context.read<EntrepriseProvider>().refresh();
      }
    }
  }

  void _assignContraventionToEntreprise(Map<String, dynamic> entreprise) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AssignContraventionEntrepriseModal.entreprise(entreprise: entreprise),
    );

    if (result == true) {
      // Rafraîchir la liste des entreprises si une contravention a été assignée
      if (mounted) {
        context.read<EntrepriseProvider>().refresh();
      }
    }
  }

  void _showDetailsDialog(Map<String, dynamic> entreprise) {
    showDialog(
      context: context,
      builder: (context) => EntrepriseDetailsModal(entreprise: entreprise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(), // Espace vide à gauche
              ),
              Expanded(
                flex: 3,
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
                              context
                                  .read<EntrepriseProvider>()
                                  .fetchEntreprises();
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
              Expanded(
                flex: 2,
                child: Container(), // Espace vide à droite
              ),
            ],
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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[400]),
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
                      const Icon(Icons.business_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune entreprise trouvée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Utilisez le menu principal pour ajouter une entreprise',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.business,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Liste des entreprises (${provider.totalCount})',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (provider.totalPages > 1)
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: provider.currentPage > 1
                                          ? provider.loadPreviousPage
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text(
                                        '${provider.currentPage} / ${provider.totalPages}'),
                                    IconButton(
                                      onPressed: provider.currentPage <
                                              provider.totalPages
                                          ? provider.loadNextPage
                                          : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainer
                                  .withValues(alpha: 0.5),
                            ),
                            columns: const [
                              DataColumn(
                                  label: Text('ID',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Désignation',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Téléphone',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Email',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('RCCM',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Secteur',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: provider.entreprises.map((entreprise) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                      Text(entreprise['id']?.toString() ?? '')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entreprise['designation']?.toString() ??
                                            'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      entreprise['gsm']?.toString() ?? 'N/A')),
                                  DataCell(Text(
                                      entreprise['email']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      entreprise['rccm']?.toString() ?? 'N/A')),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        entreprise['secteur']?.toString() ??
                                            'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              color: Colors.white),
                                          tooltip: 'Voir les détails',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[700],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showDetailsDialog(entreprise),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.white),
                                          tooltip: 'Modifier',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[800],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showEditEntrepriseModal(
                                                  entreprise),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.assignment,
                                              color: Colors.white),
                                          tooltip: 'Assigner une contravention',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[900],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _assignContraventionToEntreprise(
                                                  entreprise),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
