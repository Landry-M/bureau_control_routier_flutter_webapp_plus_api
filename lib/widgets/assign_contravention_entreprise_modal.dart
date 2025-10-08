import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
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
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

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

      // Préparer les fichiers images
      final List<http.MultipartFile> imageFiles = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'photos',
          image.path,
          filename: 'contrav_${DateTime.now().millisecondsSinceEpoch}_$i.${image.path.split('.').last}',
        );
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
      NotificationService.error(context, 'Erreur: ${e.toString()}');
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
        _cLieuCtrl.text = result['address'];
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
                  onSurface: Colors.black,
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
                    onSurface: Colors.black,
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
                          labelText: 'Montant amende (FC)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
        Row(
          children: [
            const Icon(Icons.camera_alt, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Photos de la contravention',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _submitting ? null : _pickImages,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Aucune photo sélectionnée',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'Appuyez sur "Ajouter" pour sélectionner des photos',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _buildImageThumbnail(image, index);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(XFile image, int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red);
              },
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(context, 'Erreur lors de la sélection des images: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
}
