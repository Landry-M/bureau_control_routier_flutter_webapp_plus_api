import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../utils/date_time_picker_theme.dart';
import '../utils/image_utils.dart';
import 'location_picker_dialog.dart';
import 'contravention_preview_modal.dart';

class AssignContraventionVehiculeModal extends StatefulWidget {
  final Map<String, dynamic> vehicule;
  final VoidCallback? onSuccess;

  const AssignContraventionVehiculeModal({
    super.key,
    required this.vehicule,
    this.onSuccess,
  });

  @override
  State<AssignContraventionVehiculeModal> createState() =>
      _AssignContraventionVehiculeModalState();
}

class _AssignContraventionVehiculeModalState
    extends State<AssignContraventionVehiculeModal> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _cDateHeureCtrl = TextEditingController();
  final _cLieuCtrl = TextEditingController();
  final _cTypeInfractionCtrl = TextEditingController();
  final _cRefLoiCtrl = TextEditingController();
  final _cMontantCtrl = TextEditingController();
  final _cDescriptionCtrl = TextEditingController();

  DateTime? _selectedDateTime;
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
    _cRefLoiCtrl.dispose();
    _cMontantCtrl.dispose();
    _cDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final fields = <String, String>{
        'dossier_id': widget.vehicule['id'].toString(),
        'type_dossier': 'vehicule_plaque',
        'date_infraction': _selectedDateTime?.toIso8601String() ??
            DateTime.now().toIso8601String(),
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
      for (final image in _selectedImages) {
        final multipartFile =
            await ImageUtils.createMultipartFile(image, 'images[]');
        imageFiles.add(multipartFile);
      }

      final resp = await api.postMultipart('/contravention/create',
          fields: fields, files: imageFiles);
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;

      if (!ok) throw Exception('Erreur (${resp.statusCode})');

      // Décoder la réponse pour récupérer l'ID de la contravention
      final responseData = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
      final contraventionIdRaw = responseData?['id'];
      final contraventionId = contraventionIdRaw != null
          ? int.tryParse(contraventionIdRaw.toString())
          : null;

      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.success(context,
            'Contravention créée avec succès pour le véhicule ${widget.vehicule['plaque']}');
        widget.onSuccess?.call();

        // Afficher l'aperçu de la contravention
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
      if (mounted) {
        NotificationService.error(
            context, 'Erreur lors de la création de la contravention: $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickLocation() async {
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

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      setState(() {
        _selectedImages.addAll(images);
      });
    } catch (e) {
      if (mounted) {
        NotificationService.error(
            context, 'Erreur lors de la sélection des images: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
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
                  Icon(Icons.directions_car, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créer une contravention',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Véhicule: ${widget.vehicule['plaque']} - ${widget.vehicule['marque']}',
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
                  ),
                ],
              ),
            ),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date et heure
                      TextFormField(
                        controller: _cDateHeureCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Date et heure de l\'infraction *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: buildThemedPicker,
                          );

                          if (date != null && mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: buildThemedPicker,
                            );

                            if (time != null) {
                              _selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              _cDateHeureCtrl.text =
                                  '${date.day}/${date.month}/${date.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                            }
                          }
                        },
                        validator: (val) => val?.isEmpty ?? true
                            ? 'Date et heure requises'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Lieu
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cLieuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Lieu de l\'infraction *',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val?.trim().isEmpty ?? true
                                  ? 'Lieu requis'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _pickLocation,
                            icon: Icon(
                              Icons.map,
                              color: _latitude != null && _longitude != null
                                  ? Colors.green
                                  : null,
                            ),
                            tooltip: 'Choisir sur la carte',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Type d'infraction
                      TextFormField(
                        controller: _cTypeInfractionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Type d\'infraction *',
                          prefixIcon: Icon(Icons.warning),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val?.trim().isEmpty ?? true ? 'Type requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Référence loi
                      TextFormField(
                        controller: _cRefLoiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Référence de loi',
                          prefixIcon: Icon(Icons.gavel),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Montant
                      TextFormField(
                        controller: _cMontantCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Montant de l\'amende (FC) *',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val?.trim().isEmpty ?? true
                            ? 'Montant requis'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _cDescriptionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payée
                      CheckboxListTile(
                        value: _cPayee,
                        onChanged: (val) =>
                            setState(() => _cPayee = val ?? false),
                        title: const Text('Contravention payée'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),

                      // Photos
                      Text(
                        'Photos de la contravention',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Ajouter des photos'),
                      ),
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _selectedImages.asMap().entries.map((entry) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ImageUtils.buildImageWidget(
                                      entry.value,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    onPressed: () => _removeImage(entry.key),
                                    icon: const Icon(Icons.close, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(24, 24),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer la contravention'),
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
