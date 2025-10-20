import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../utils/image_utils.dart';

class SosAvisVehiculeModal extends StatefulWidget {
  const SosAvisVehiculeModal({super.key});

  @override
  State<SosAvisVehiculeModal> createState() => _SosAvisVehiculeModalState();
}

class _SosAvisVehiculeModalState extends State<SosAvisVehiculeModal> {
  final _formKey = GlobalKey<FormState>();
  final _plaqueController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();
  final _numeroChassisController = TextEditingController();
  final _motifController = TextEditingController();
  final _searchController = TextEditingController();

  String _niveau = 'élevé'; // Par défaut élevé pour SOS
  bool _isLoading = false;
  bool _useExisting = false; // Switch pour utiliser un enregistrement existant
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedVehicule;
  bool _isSearching = false;

  @override
  void dispose() {
    _plaqueController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _numeroChassisController.dispose();
    _motifController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_useExisting && _searchController.text.length >= 2) {
      _searchVehicules(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _selectedVehicule = null;
      });
    }
  }

  Future<void> _searchVehicules(String query) async {
    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {
            'route': '/vehicules',
            'search': query,
            'limit': '10',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _searchResults =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Erreur recherche: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
                    Icons.directions_car,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS - Avis de recherche Véhicule',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Émission d\'un avis de recherche d\'urgence',
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

            // Contenu
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeSelector(theme),
                      const SizedBox(height: 24),
                      if (_useExisting)
                        _buildSearchSection(theme)
                      else
                        _buildVehiculeSection(theme),
                      const SizedBox(height: 24),
                      _buildMotifSection(theme),
                      const SizedBox(height: 24),
                      _buildNiveauSection(theme),
                      const SizedBox(height: 24),
                      _buildImagesSection(theme),
                      const SizedBox(height: 32),
                      _buildActionButtons(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _useExisting ? Icons.search : Icons.add_road,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useExisting ? 'Véhicule existant' : 'Nouveau véhicule',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _useExisting
                      ? 'Rechercher dans la base de données'
                      : 'Créer un nouveau dossier',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useExisting,
            onChanged: (value) {
              setState(() {
                _useExisting = value;
                _selectedVehicule = null;
                _searchResults = [];
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rechercher un véhicule',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Plaque, marque ou modèle',
            hintText: 'Tapez au moins 2 caractères...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _selectedVehicule = null;
                          });
                        },
                      )
                    : null,
          ),
        ),
        if (_selectedVehicule != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVehicule!['plaque'] ?? 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '${_selectedVehicule!['marque']} ${_selectedVehicule!['modele'] ?? ''}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (_selectedVehicule!['couleur'] != null) ...[
                            Text(
                              'Couleur: ${_selectedVehicule!['couleur']}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_selectedVehicule!['annee'] != null)
                            Text(
                              'Année: ${_selectedVehicule!['annee']}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _selectedVehicule = null);
                  },
                ),
              ],
            ),
          ),
        ] else if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final vehicule = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.directions_car,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    vehicule['plaque'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule['marque']} ${vehicule['modele'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (vehicule['couleur'] != null ||
                          vehicule['annee'] != null)
                        Text(
                          '${vehicule['couleur'] ?? ''} ${vehicule['annee'] != null ? '• ${vehicule['annee']}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedVehicule = vehicule;
                      _searchResults = [];
                    });
                  },
                );
              },
            ),
          ),
        ] else if (_searchController.text.length >= 2 && !_isSearching) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aucun résultat trouvé',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehiculeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du véhicule recherché',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _plaqueController,
          decoration: const InputDecoration(
            labelText: 'Plaque d\'immatriculation *',
            border: OutlineInputBorder(),
            hintText: 'Ex: ABC-123-DE',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La plaque d\'immatriculation est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(
                  labelText: 'Marque *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Toyota',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marque est requise';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(
                  labelText: 'Modèle *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Camry',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le modèle est requis';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _couleurController,
                decoration: const InputDecoration(
                  labelText: 'Couleur *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Blanc',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La couleur est requise';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _anneeController,
                decoration: const InputDecoration(
                  labelText: 'Année',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 2020',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _numeroChassisController,
          decoration: const InputDecoration(
            labelText: 'Numéro de châssis',
            border: OutlineInputBorder(),
            hintText: 'Ex: VF1AB0005XXXXXX',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
      ],
    );
  }

  Widget _buildMotifSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motif de la recherche *',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motifController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Décrivez le motif de l\'avis de recherche (ex: Vol de véhicule, Délit de fuite, Véhicule utilisé dans un crime, etc.)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le motif est requis';
            }
            if (value.trim().length < 10) {
              return 'Le motif doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNiveauSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveau de priorité',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            _buildNiveauChip('moyen', 'Moyen', Colors.orange, theme),
            _buildNiveauChip('élevé', 'Élevé (SOS)', Colors.red, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildNiveauChip(
      String value, String label, Color color, ThemeData theme) {
    final isSelected = _niveau == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _niveau = value;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildImagesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optionnel)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter des images'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child:
                          ImageUtils.buildImageWidget(image, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(4),
                      ),
                      onPressed: () => _removeImage(index),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${_selectedImages.length} image(s) sélectionnée(s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text('${images.length} image(s) ajoutée(s)'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 2),
          showProgressBar: true,
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text('Erreur lors de la sélection: $e'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: true,
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Émettre l\'avis SOS'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    // Validation
    if (_useExisting && _selectedVehicule == null) {
      _showError('Veuillez sélectionner un véhicule existant');
      return;
    }

    if (!_useExisting && !_formKey.currentState!.validate()) {
      return;
    }

    if (_motifController.text.trim().isEmpty) {
      _showError('Le motif est requis');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      int vehiculeId;

      if (_useExisting) {
        // Utiliser le véhicule existant
        vehiculeId = int.parse(_selectedVehicule!['id'].toString());
      } else {
        // Créer un nouveau véhicule (avec vérification de doublon automatique)
        final vehiculeResponse = await http.post(
          Uri.parse(ApiConfig.baseUrl).replace(
            queryParameters: {'route': '/vehicules/create'},
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'plaque': _plaqueController.text.trim(),
            'marque': _marqueController.text.trim(),
            'modele': _modeleController.text.trim(),
            'couleur': _couleurController.text.trim(),
            'annee': _anneeController.text.trim().isNotEmpty
                ? int.tryParse(_anneeController.text.trim())
                : null,
            'username': authProvider.username,
          }),
        );

        if (vehiculeResponse.statusCode == 200) {
          final vehiculeData = jsonDecode(vehiculeResponse.body);
          if (vehiculeData['success'] == true) {
            vehiculeId = int.parse(vehiculeData['id'].toString());

            // Informer l'utilisateur si un véhicule existant a été utilisé
            if (vehiculeData['existing'] == true) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Un véhicule avec cette plaque existe déjà. L\'avis sera créé pour le véhicule existant.',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else {
            _showError(vehiculeData['message'] ??
                'Erreur lors de la création du véhicule');
            return;
          }
        } else {
          _showError(
              'Erreur serveur lors de la création du véhicule: ${vehiculeResponse.statusCode}');
          return;
        }
      }

      // Créer l'avis de recherche avec images et numéro de châssis
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/avis-recherche/create'},
        ),
      );

      request.fields['cible_type'] = 'vehicule_plaque';
      request.fields['cible_id'] = vehiculeId.toString();
      request.fields['motif'] = _motifController.text.trim();
      request.fields['niveau'] = _niveau;
      request.fields['created_by'] = authProvider.username;
      request.fields['username'] = authProvider.username;

      // Ajouter le numéro de châssis si renseigné
      if (_numeroChassisController.text.isNotEmpty) {
        request.fields['numero_chassis'] = _numeroChassisController.text.trim();
      }

      // Ajouter les images si présentes
      if (_selectedImages.isNotEmpty) {
        for (final image in _selectedImages) {
          final multipartFile =
              await ImageUtils.createMultipartFile(image, 'images[]');
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send();
      final avisResponse = await http.Response.fromStream(streamedResponse);

      if (avisResponse.statusCode == 200) {
        final avisData = jsonDecode(avisResponse.body);
        if (avisData['success'] == true) {
          // Fermer le modal de création
          Navigator.of(context).pop();

          // Afficher le PDF si disponible
          if (avisData['pdf'] != null && avisData['pdf']['pdf_url'] != null) {
            _showPdfPreview(
              context,
              avisData['pdf']['pdf_url'],
              avisData['id'].toString(),
            );
          } else {
            _showSuccess('Avis de recherche SOS émis avec succès');
          }
        } else {
          _showError(avisData['message'] ??
              'Erreur lors de l\'émission de l\'avis de recherche');
        }
      } else {
        _showError(
            'Erreur serveur lors de l\'émission de l\'avis: ${avisResponse.statusCode}');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Succès'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
    );
  }

  void _showError(String message) {
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

  void _showPdfPreview(BuildContext context, String pdfUrl, String avisId) async {
    // Ouvrir automatiquement l'affichage de l'avis dans un nouvel onglet
    try {
      final displayUrl = ApiConfig.getAvisRechercheDisplayUrl(int.parse(avisId));
      final uri = Uri.parse(displayUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Afficher un message de succès
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Succès'),
            description: Text('Avis de recherche N°$avisId émis avec succès. Le PDF a été ouvert dans un nouvel onglet.'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: true,
          );
        }
      } else {
        throw 'Impossible d\'ouvrir le PDF';
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.fillColored,
          title: const Text('Attention'),
          description: Text('Avis de recherche N°$avisId créé, mais impossible d\'ouvrir automatiquement le PDF: $e'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: true,
        );
      }
    }
  }
}
