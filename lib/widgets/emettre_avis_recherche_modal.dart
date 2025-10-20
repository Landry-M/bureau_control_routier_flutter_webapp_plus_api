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

class EmettreAvisRechercheModal extends StatefulWidget {
  final Map<String, dynamic> cible;
  final String cibleType; // 'particuliers' ou 'vehicule_plaque'
  final VoidCallback? onSuccess;

  const EmettreAvisRechercheModal({
    super.key,
    required this.cible,
    required this.cibleType,
    this.onSuccess,
  });

  @override
  State<EmettreAvisRechercheModal> createState() => _EmettreAvisRechercheModalState();
}

class _EmettreAvisRechercheModalState extends State<EmettreAvisRechercheModal> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _numeroChassisController = TextEditingController();
  
  String _niveau = 'moyen';
  bool _isLoading = false;
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _motifController.dispose();
    _numeroChassisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Émettre un avis de recherche',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getCibleDescription(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
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
                      _buildMotifSection(theme),
                      const SizedBox(height: 24),
                      _buildNiveauSection(theme),
                      const SizedBox(height: 24),
                      _buildImagesSection(theme),
                      const SizedBox(height: 24),
                      if (widget.cibleType == 'vehicule_plaque') ...[
                        _buildNumeroChassisSection(theme),
                        const SizedBox(height: 24),
                      ],
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
            hintText: 'Décrivez le motif de l\'avis de recherche (ex: Vol, Délit de fuite, Disparition, etc.)',
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
            _buildNiveauChip('faible', 'Faible', Colors.green, theme),
            _buildNiveauChip('moyen', 'Moyen', Colors.orange, theme),
            _buildNiveauChip('élevé', 'Élevé', Colors.red, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildNiveauChip(String value, String label, Color color, ThemeData theme) {
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
                      child: ImageUtils.buildImageWidget(image, fit: BoxFit.cover),
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

  Widget _buildNumeroChassisSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Numéro de châssis',
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
        TextFormField(
          controller: _numeroChassisController,
          decoration: const InputDecoration(
            hintText: 'Entrez le numéro de châssis du véhicule',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
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
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Émettre l\'avis'),
        ),
      ],
    );
  }

  String _getCibleDescription() {
    if (widget.cibleType == 'particuliers') {
      return '${widget.cible['nom']} ${widget.cible['prenom'] ?? ''}'.trim();
    } else {
      return 'Plaque: ${widget.cible['plaque']}';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Créer une requête multipart pour l'upload d'images
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/avis-recherche/create'},
        ),
      );
      
      // Ajouter les champs de données
      request.fields['cible_type'] = widget.cibleType;
      request.fields['cible_id'] = widget.cible['id'].toString();
      request.fields['motif'] = _motifController.text.trim();
      request.fields['niveau'] = _niveau;
      request.fields['created_by'] = authProvider.username;
      request.fields['username'] = authProvider.username;
      
      // Ajouter le numéro de châssis si renseigné (pour véhicules uniquement)
      if (widget.cibleType == 'vehicule_plaque' && _numeroChassisController.text.isNotEmpty) {
        request.fields['numero_chassis'] = _numeroChassisController.text.trim();
      }
      
      // Ajouter les images si présentes
      if (_selectedImages.isNotEmpty) {
        for (final image in _selectedImages) {
          final multipartFile = await ImageUtils.createMultipartFile(image, 'images[]');
          request.files.add(multipartFile);
        }
      }
      
      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.of(context).pop();
          
          // Ouvrir automatiquement le PDF si disponible
          if (data['pdf'] != null && data['pdf']['pdf_url'] != null) {
            _openPdfAutomatically(data['pdf']['pdf_url'], data['id'].toString());
          } else {
            _showSuccess('Avis de recherche émis avec succès');
          }
        } else {
          _showError(data['message'] ?? 'Erreur lors de l\'émission de l\'avis de recherche');
        }
      } else {
        _showError('Erreur serveur: ${response.statusCode}');
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
  
  Future<void> _openPdfAutomatically(String pdfUrl, String avisId) async {
    try {
      final displayUrl = ApiConfig.getAvisRechercheDisplayUrl(int.parse(avisId));
      final uri = Uri.parse(displayUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
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
