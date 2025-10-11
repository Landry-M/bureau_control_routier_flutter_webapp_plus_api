import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  // Coordonnées de Lubumbashi, RDC
  static const LatLng _lubumbashiCenter = LatLng(-11.6689, 27.4794);

  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  LatLng _selectedPosition = _lubumbashiCenter;
  String _selectedAddress = 'Lubumbashi, RDC';
  bool _isLoadingAddress = false;
  bool _isMapReady = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addMarker(_lubumbashiCenter);
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

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _onLocationSelected(newPosition);
          },
        ),
      );
    });
  }

  String _buildDetailedAddress(Map<String, dynamic> result) {
    if (result['address_components'] == null) {
      return result['formatted_address'] ?? '';
    }

    // Extraire toutes les composantes d'adresse
    String streetNumber = '';
    String route = '';
    String neighborhood = '';
    String locality = '';
    String sublocality = '';
    String adminLevel2 = '';
    String adminLevel1 = '';
    String country = '';
    String postalCode = '';

    for (var component in result['address_components']) {
      final types = component['types'] as List;
      final longName = component['long_name'] ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('neighborhood')) {
        neighborhood = longName;
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        sublocality = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_2')) {
        adminLevel2 = longName;
      } else if (types.contains('administrative_area_level_1')) {
        adminLevel1 = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    // Construire l'adresse complète avec toutes les informations disponibles
    List<String> addressParts = [];

    // Numéro et nom de rue
    if (streetNumber.isNotEmpty && route.isNotEmpty) {
      addressParts.add('$streetNumber $route');
    } else if (route.isNotEmpty) {
      addressParts.add(route);
    }

    // Quartier
    if (neighborhood.isNotEmpty) {
      addressParts.add(neighborhood);
    }

    // Sous-localité
    if (sublocality.isNotEmpty) {
      addressParts.add(sublocality);
    }

    // Ville
    if (locality.isNotEmpty) {
      addressParts.add(locality);
    }

    // Commune/District
    if (adminLevel2.isNotEmpty && adminLevel2 != locality) {
      addressParts.add(adminLevel2);
    }

    // Province/Région
    if (adminLevel1.isNotEmpty) {
      addressParts.add(adminLevel1);
    }

    // Code postal
    if (postalCode.isNotEmpty) {
      addressParts.add(postalCode);
    }

    // Pays
    if (country.isNotEmpty) {
      addressParts.add(country);
    }

    String detailedAddress = addressParts.join(', ');

    // Si aucune composante trouvée, utiliser formatted_address
    if (detailedAddress.isEmpty) {
      detailedAddress = result['formatted_address'] ?? '';
    }

    return detailedAddress;
  }

  Future<void> _onLocationSelected(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _isLoadingAddress = true;
      _addMarker(position);
    });

    try {
      // Utiliser l'API HTTP de Google Maps Geocoding (fonctionne sur web et mobile)
      final apiKey = 'AIzaSyAyRwr3rU43FT7RWNHUMyPi1rc16ArLMTE';
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey&language=fr');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];

          // Construire l'adresse détaillée avec toutes les composantes
          String address = _buildDetailedAddress(result);

          if (mounted) {
            setState(() {
              _selectedAddress = address.isNotEmpty
                  ? address
                  : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              _isLoadingAddress = false;
            });
          }
        } else {
          // Pas de résultat, utiliser les coordonnées
          if (mounted) {
            setState(() {
              _selectedAddress =
                  '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              _isLoadingAddress = false;
            });
          }
        }
      } else {
        // Erreur HTTP, utiliser les coordonnées
        if (mounted) {
          setState(() {
            _selectedAddress =
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      // En cas d'erreur, utiliser les coordonnées
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 700,
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
                          'Sélectionner le lieu de l\'infraction',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliquez sur la carte ou déplacez le marqueur',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.7),
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
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _lubumbashiCenter,
                      zoom: 13,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      if (!_mapControllerCompleter.isCompleted) {
                        _mapControllerCompleter.complete(controller);
                      }
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                    onTap: _onLocationSelected,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  if (!_isMapReady)
                    Container(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chargement de la carte...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Adresse sélectionnée
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Adresse sélectionnée',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: _isLoadingAddress
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Chargement de l\'adresse...'),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedAddress,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  // Copy to clipboard functionality
                                },
                                tooltip: 'Copier l\'adresse',
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoadingAddress
                            ? null
                            : () {
                                Navigator.of(context).pop({
                                  'address': _selectedAddress,
                                  'latitude': _selectedPosition.latitude,
                                  'longitude': _selectedPosition.longitude,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmer'),
                      ),
                    ],
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
