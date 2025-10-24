import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class ContraventionMapViewer extends StatefulWidget {
  final Map<String, dynamic> contravention;

  const ContraventionMapViewer({
    super.key,
    required this.contravention,
  });

  @override
  State<ContraventionMapViewer> createState() => _ContraventionMapViewerState();
}

class _ContraventionMapViewerState extends State<ContraventionMapViewer> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  late LatLng _contraventionLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    // Disposer le contrôleur de manière asynchrone si complété
    if (_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.future.then((controller) {
        controller.dispose();
      }).catchError((_) {
        // Contrôleur pas encore initialisé
      });
    }
    super.dispose();
  }

  void _initializeLocation() {
    final latitude = widget.contravention['latitude'];
    final longitude = widget.contravention['longitude'];
    
    if (latitude != null && longitude != null) {
      _contraventionLocation = LatLng(
        double.tryParse(latitude.toString()) ?? -11.6689,
        double.tryParse(longitude.toString()) ?? 27.4794,
      );
    } else {
      // Coordonnées par défaut (Lubumbashi)
      _contraventionLocation = const LatLng(-11.6689, 27.4794);
    }

    _addMarker();
  }

  void _addMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('contravention_${widget.contravention['id']}'),
          position: _contraventionLocation,
          infoWindow: InfoWindow(
            title: 'Contravention #${widget.contravention['id']}',
            snippet: widget.contravention['type_infraction'] ?? 'Infraction',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
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
                          'Localisation de l\'infraction',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contravention #${widget.contravention['id']}',
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
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _contraventionLocation,
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

            // Informations de la contravention
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
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Détails de l\'infraction',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Type:', widget.contravention['type_infraction'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Lieu:', widget.contravention['lieu'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Date:', widget.contravention['date_infraction'] ?? 'N/A'),
                        if (widget.contravention['amende'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('Amende:', '${widget.contravention['amende']} FC'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
