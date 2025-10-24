import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../utils/image_utils.dart';
import 'contravention_preview_modal.dart';
import 'location_picker_dialog.dart';

class AssignContraventionEntrepriseModal extends StatefulWidget {
  final Map<String, dynamic> dossier;
  final String typeDossier; // 'entreprise' ou 'vehicule_plaque'

  const AssignContraventionEntrepriseModal({
    super.key,
    required this.dossier,
    this.typeDossier = 'entreprise',
  });

  // Constructor pour entreprise
  const AssignContraventionEntrepriseModal.entreprise({
    super.key,
    required Map<String, dynamic> entreprise,
  })  : dossier = entreprise,
        typeDossier = 'entreprise';

  // Constructor pour véhicule
  const AssignContraventionEntrepriseModal.vehicule({
    super.key,
    required Map<String, dynamic> vehicule,
  })  : dossier = vehicule,
        typeDossier = 'vehicule_plaque';

  @override
  State<AssignContraventionEntrepriseModal> createState() =>
      _AssignContraventionEntrepriseModalState();
}

class _AssignContraventionEntrepriseModalState
    extends State<AssignContraventionEntrepriseModal> {
  final _formKey = GlobalKey<FormState>();

  // Champs de contravention
  DateTime? _selectedDateTime;
  final _cDateHeureCtrl = TextEditingController();
  final _cLieuCtrl = TextEditingController();
  final _cTypeInfractionCtrl = TextEditingController();
  final _cRefLoiCtrl = TextEditingController();
  final _cMontantCtrl = TextEditingController();
  final _cDescriptionCtrl = TextEditingController();
  bool _cPayee = false;
  bool _submitting = false;

  // Coordonnées géographiques
  double? _latitude;
  double? _longitude;

  // Images de contravention
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _cDateHeureCtrl.dispose();
    _cLieuCtrl.dispose();
    _cTypeInfractionCtrl.dispose();
    _cDescriptionCtrl.dispose();
    _cRefLoiCtrl.dispose();
    _cMontantCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final fields = <String, String>{
        'dossier_id': widget.dossier['id'].toString(),
        'type_dossier': widget.typeDossier,
        'date_infraction': _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'lieu': _cLieuCtrl.text.trim(),
        'type_infraction': _cTypeInfractionCtrl.text.trim(),
        'description': _cDescriptionCtrl.text.trim(),
        'reference_loi': _cRefLoiCtrl.text.trim(),
        'amende': _cMontantCtrl.text.trim(),
        'payed': _cPayee ? '1' : '0',
        'latitude': _latitude?.toString() ?? '',
        'longitude': _longitude?.toString() ?? '',
      };

      // Préparer les fichiers images avec ImageUtils (comme les avis de recherche SOS)
      final List<http.MultipartFile> imageFiles = [];
      for (final image in _selectedImages) {
        final multipartFile = await ImageUtils.createMultipartFile(image, 'images[]');
        imageFiles.add(multipartFile);
      }

      final resp = await api.postMultipart('/contravention/create',
          fields: fields, files: imageFiles);
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;

      if (!ok) throw Exception('Erreur (${resp.statusCode})');

      // Décoder la réponse pour récupérer l'ID de la contravention
      final responseData = resp.body.isNotEmpty ? 
          jsonDecode(resp.body) : null;
      final contraventionIdRaw = responseData?['id'];
      final contraventionId = contraventionIdRaw != null ? 
          int.tryParse(contraventionIdRaw.toString()) : null;

      NotificationService.success(
          context, 'Contravention assignée avec succès');
      
      if (mounted) {
        Navigator.of(context).pop(true);
        
        // Afficher la prévisualisation si on a l'ID
        if (contraventionId != null) {
          showDialog(
            context: context,
            builder: (context) => ContraventionPreviewModal(
              contraventionId: contraventionId,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      NotificationService.error(context, errorMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        // Afficher l'adresse dans le champ de texte pour que l'utilisateur puisse l'enrichir
        if (result['address'] != null) {
          _cLieuCtrl.text = result['address'];
        }
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.white,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.white,
                  ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _cDateHeureCtrl.text =
              '${_selectedDateTime!.day.toString().padLeft(2, '0')}/${_selectedDateTime!.month.toString().padLeft(2, '0')}/${_selectedDateTime!.year} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    String title = 'Créer contravention';
    if (widget.typeDossier == 'entreprise') {
      title += ' - ${widget.dossier['designation'] ?? 'Entreprise'}';
    } else if (widget.typeDossier == 'vehicule_plaque') {
      title += ' - ${widget.dossier['plaque'] ?? 'Véhicule'}';
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: tt.titleLarge)),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations de la contravention', style: tt.titleMedium),
                const SizedBox(height: 16),

                // Date et heure
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cDateHeureCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Date et heure *',
                          hintText: 'Sélectionner date/heure',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: _submitting ? null : _selectDateTime,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lieu avec sélection sur carte ET saisie manuelle
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cLieuCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lieu de l\'infraction *',
                          hintText: 'Saisir l\'adresse ou utiliser la carte',
                          border: const OutlineInputBorder(),
                          suffixIcon: _latitude != null && _longitude != null
                              ? Icon(Icons.location_on, color: Colors.green[600])
                              : null,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        // Permettre la saisie manuelle
                        readOnly: false,
                        maxLines: 2,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submitting ? null : _selectLocation,
                      icon: const Icon(Icons.map),
                      tooltip: 'Sélectionner sur la carte',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Type d'infraction
                TextFormField(
                  controller: _cTypeInfractionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'infraction *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),

                // Référence loi et montant
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cRefLoiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Référence loi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cMontantCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Montant amende (FC) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _cDescriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Section des images
                _buildImageSection(),
                const SizedBox(height: 16),

                // Amende payée
                Row(
                  children: [
                    Checkbox(
                      value: _cPayee,
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _cPayee = v ?? false),
                    ),
                    const Text('Amende payée'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_submitting ? 'Création...' : 'Créer'),
        ),
      ],
    );
  }

  // Section des images
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _submitting ? null : _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter des images'),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildThumbnails(
            _selectedImages,
            (f) => setState(() => _selectedImages.remove(f)),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnails(List<XFile> files, void Function(XFile) onRemove) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: files.map((f) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 90,
                height: 90,
                child: ImageUtils.buildImageWidget(f, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRemove(f),
                  borderRadius: BorderRadius.circular(12),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(context, 'Erreur lors de la sélection: $e');
      }
    }
  }
}
