import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../utils/date_time_picker_theme.dart';
import 'location_picker_dialog.dart';

class AssignContraventionParticulierModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onSuccess;

  const AssignContraventionParticulierModal({
    super.key,
    required this.particulier,
    this.onSuccess,
  });

  @override
  State<AssignContraventionParticulierModal> createState() => _AssignContraventionParticulierModalState();
}

class _AssignContraventionParticulierModalState extends State<AssignContraventionParticulierModal> {
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
  List<PlatformFile> _contravPhotos = [];

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

  Future<void> _selectLocationOnMap() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null && result['address'] != null) {
      setState(() {
        _cLieuCtrl.text = result['address'];
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      
      final fields = <String, String>{
        'dossier_id': widget.particulier['id'].toString(),
        'type_dossier': 'particulier',
        'date_infraction': _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'lieu': _cLieuCtrl.text.trim(),
        'type_infraction': _cTypeInfractionCtrl.text.trim(),
        'description': _cDescriptionCtrl.text.trim(),
        'reference_loi': _cRefLoiCtrl.text.trim(),
        'amende': _cMontantCtrl.text.trim(),
        'payed': _cPayee ? 'oui' : 'non',
      };

      final files = <http.MultipartFile>[];
      
      if (_contravPhotos.isNotEmpty) {
        for (final p in _contravPhotos) {
          if (p.bytes != null) {
            files.add(http.MultipartFile.fromBytes(
              'photos[]',
              p.bytes!,
              filename: p.name,
            ));
          }
        }
      }

      final resp = await api.postMultipart('/contravention/create', fields: fields, files: files);
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      
      if (!ok) throw Exception('Erreur (${resp.statusCode})');
      
      if (mounted) {
        NotificationService.success(context, 'Contravention assignée avec succès');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: buildThemedPicker,
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
        builder: buildThemedPicker,
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

  Future<void> _pickContravPhotos() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _contravPhotos = res.files);
    }
  }

  void _showImagePreview(PlatformFile file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: file.bytes != null
                  ? Image.memory(
                      file.bytes!,
                      fit: BoxFit.contain,
                    )
                  : const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  file.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigner une contravention'),
                Text(
                  'Particulier: ${widget.particulier['nom']} ${widget.particulier['prenom'] ?? ''}',
                  style: tt.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
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
                        readOnly: true,
                        onTap: _submitting ? null : _selectDateTime,
                        decoration: const InputDecoration(
                          labelText: 'Date/heure *',
                          suffixIcon: Icon(Icons.calendar_today),
                          hintText: 'Sélectionner date/heure',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Lieu
                TextFormField(
                  controller: _cLieuCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lieu de l\'infraction',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: _selectLocationOnMap,
                      tooltip: 'Sélectionner sur la carte',
                    ),
                  ),
                  readOnly: false,
                ),
                const SizedBox(height: 12),
                
                // Type d'infraction
                TextFormField(
                  controller: _cTypeInfractionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'infraction *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
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
                
                // Amende payée
                Row(
                  children: [
                    Checkbox(
                      value: _cPayee,
                      onChanged: (v) => setState(() => _cPayee = v ?? false),
                    ),
                    const Text('Amende payée'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Photos
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickContravPhotos,
                  icon: const Icon(Icons.photo_library),
                  label: Text('Ajouter des photos (${_contravPhotos.length})'),
                ),
                
                if (_contravPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _contravPhotos.length,
                      itemBuilder: (context, index) {
                        final file = _contravPhotos[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _showImagePreview(file),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: file.bytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        file.bytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assigner'),
        ),
      ],
    );
  }
}
