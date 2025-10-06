import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/accident_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../widgets/top_bar.dart';
import 'dart:async';

class AccidentsScreen extends StatefulWidget {
  const AccidentsScreen({super.key});

  @override
  State<AccidentsScreen> createState() => _AccidentsScreenState();
}

class _AccidentsScreenState extends State<AccidentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccidentProvider>().loadAccidents(refresh: true);
    });

    // Scroll infini
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<AccidentProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAccidentDetails(Map<String, dynamic> accident) async {
    try {
      final provider = context.read<AccidentProvider>();
      final details = await provider.getAccidentDetails(accident['id']);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _AccidentDetailsModal(accident: details),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showEditAccidentModal(Map<String, dynamic> accident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'accident #${accident['id']}'),
        content: const SizedBox(
          width: 400,
          child: Text('Fonctionnalité de modification en cours de développement...'),
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

  void _showLocationOnMap(dynamic latitude, dynamic longitude, String locationName) {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnées GPS non disponibles')),
      );
      return;
    }

    double? lat;
    double? lng;

    try {
      if (latitude is String) {
        lat = double.parse(latitude);
      } else if (latitude is num) {
        lat = latitude.toDouble();
      }

      if (longitude is String) {
        lng = double.parse(longitude);
      } else if (longitude is num) {
        lng = longitude.toDouble();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de format des coordonnées: $e')),
      );
      return;
    }

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnées invalides')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _LocationMapDialog(
        latitude: lat!,
        longitude: lng!,
        locationName: locationName,
      ),
    );
  }

  Widget _buildThumbnail(String? images) {
    if (images == null || images.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Supposons que les images sont séparées par des virgules
    final imageList = images.split(',');
    final firstImage = imageList.first.trim();

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          firstImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isSuperAdmin = authProvider.role == 'superadmin';

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
                    horizontal: Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
                    vertical: Responsive.value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                  ),
                  child: const TopBar(),
                ),
                
                // Titre avec flèche de retour
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        tooltip: 'Retour',
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.car_crash, size: 28, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rapports d\'accidents',
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
                            hintText: 'Rechercher par lieu, gravité, description...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<AccidentProvider>().clearSearch();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (value) {
                            context.read<AccidentProvider>().searchAccidents(value);
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

                // Tableau des accidents
                Expanded(
                  child: Consumer<AccidentProvider>(
                    builder: (context, provider, child) {
                      if (provider.loading && provider.accidents.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null && provider.accidents.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text('Erreur de chargement', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(provider.error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
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

                      if (provider.accidents.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.car_crash, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('Aucun accident trouvé', style: theme.textTheme.titleLarge),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => provider.refresh(),
                        child: SingleChildScrollView(
                          controller: _scrollController,
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
                                      children: [
                                        Icon(Icons.car_crash, color: theme.colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Liste des accidents (${provider.accidents.length})',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      columnSpacing: 20,
                                      headingRowColor: WidgetStateProperty.all(
                                        theme.colorScheme.surfaceContainer.withOpacity(0.5),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Photo', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Lieu', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Gravité', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: provider.accidents.map((accident) {
                                        return DataRow(
                                          cells: [
                                            DataCell(_buildThumbnail(accident['images'])),
                                            DataCell(
                                              Text(
                                                _formatDate(accident['date_accident']),
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  accident['lieu']?.toString() ?? 'N/A',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getGravityColor(accident['gravite']),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  accident['gravite']?.toString() ?? 'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 200,
                                                child: Text(
                                                  accident['description']?.toString() ?? 'N/A',
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility, color: Colors.white),
                                                    tooltip: 'Voir les détails',
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.grey[700],
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    onPressed: () => _showAccidentDetails(accident),
                                                  ),
                                                  if (accident['latitude'] != null && accident['longitude'] != null) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.map, color: Colors.white),
                                                      tooltip: 'Voir sur la carte',
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: Colors.blue[700],
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      onPressed: () => _showLocationOnMap(
                                                        accident['latitude'],
                                                        accident['longitude'],
                                                        accident['lieu'] ?? 'Lieu de l\'accident',
                                                      ),
                                                    ),
                                                  ],
                                                  if (isSuperAdmin) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.white),
                                                      tooltip: 'Modifier',
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: Colors.grey[800],
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      onPressed: () => _showEditAccidentModal(accident),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  if (provider.loading)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Color _getGravityColor(String? gravity) {
    switch (gravity?.toLowerCase()) {
      case 'léger':
      case 'leger':
        return Colors.green;
      case 'modéré':
      case 'modere':
        return Colors.orange;
      case 'grave':
        return Colors.red;
      case 'mortel':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }
}

class _AccidentDetailsModal extends StatelessWidget {
  final Map<String, dynamic> accident;

  const _AccidentDetailsModal({required this.accident});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temoins = accident['temoins'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: Text('Détails de l\'accident #${accident['id']}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Date', _formatDate(accident['date_accident'])),
              _buildDetailRow('Lieu', accident['lieu']),
              _buildDetailRow('Gravité', accident['gravite']),
              _buildDetailRow('Description', accident['description']),
              
              const SizedBox(height: 16),
              Text(
                'Photos:',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildImagesSection(accident['images']),
              
              const SizedBox(height: 16),
              Text(
                'Témoins (${temoins.length}):',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...temoins.map((temoin) => _buildWitnessCard(temoin)).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildImagesSection(String? images) {
    if (images == null || images.isEmpty) {
      return const Text('Aucune photo disponible');
    }

    final imageList = images.split(',').map((e) => e.trim()).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: imageList.map((image) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWitnessCard(Map<String, dynamic> temoin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temoin['nom']?.toString() ?? 'Témoin anonyme',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (temoin['telephone'] != null)
              Text('Tél: ${temoin['telephone']}'),
            if (temoin['age'] != null)
              Text('Âge: ${temoin['age']}'),
            Text('Lien: ${temoin['lien_avec_accident'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text(
              'Témoignage: ${temoin['temoignage'] ?? 'Aucun témoignage'}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }
}

// Modal pour afficher la localisation sur la carte
class _LocationMapDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const _LocationMapDialog({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<_LocationMapDialog> createState() => _LocationMapDialogState();
}

class _LocationMapDialogState extends State<_LocationMapDialog> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('accident_location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: 'Lieu de l\'accident',
          snippet: widget.locationName,
        ),
      ),
    };
  }

  @override
  void dispose() {
    _mapControllerCompleter.future.then((controller) {
      controller.dispose();
    }).catchError((_) {
      // Contrôleur pas encore initialisé
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 600,
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Localisation de l\'accident',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.locationName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Carte Google Maps
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: 15,
                ),
                markers: _markers,
                onMapCreated: (controller) {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(controller);
                  }
                },
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              ),
            ),

            // Informations en bas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordonnées: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Fermer'),
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
