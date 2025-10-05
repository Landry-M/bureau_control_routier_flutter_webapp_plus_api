import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class CreateEntrepriseModal extends StatefulWidget {
  const CreateEntrepriseModal({super.key});

  @override
  State<CreateEntrepriseModal> createState() => _CreateEntrepriseModalState();
}

class _CreateEntrepriseModalState extends State<CreateEntrepriseModal> {
  final _formKey = GlobalKey<FormState>();

  final _raisonCtrl = TextEditingController();
  final _rccmCtrl = TextEditingController();
  // Champs supprimés: ID Nat, Numéro d'impôt
  final _adresseCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _typeActiviteCtrl = TextEditingController();
  // Champs supprimés: Représentant légal et Téléphone représentant
  final _personneContactCtrl = TextEditingController();
  final _fonctionContactCtrl = TextEditingController();
  final _telContactCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Contravention section
  bool _withContrav = false;
  DateTime? _selectedDateTime;
  final _cDateHeureCtrl = TextEditingController();
  final _cLieuCtrl = TextEditingController();
  final _cTypeInfractionCtrl = TextEditingController();
  final _cRefLoiCtrl = TextEditingController();
  final _cMontantCtrl = TextEditingController();
  final _cDescriptionCtrl = TextEditingController();
  bool _cPayee = false;

  bool _submitting = false;

  // Uploads supprimés: logo, document
  List<PlatformFile> _contravPhotos = [];

  @override
  void dispose() {
    _raisonCtrl.dispose();
    _rccmCtrl.dispose();
    // champs supprimés
    _adresseCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    _typeActiviteCtrl.dispose();
    // champs supprimés
    _personneContactCtrl.dispose();
    _fonctionContactCtrl.dispose();
    _telContactCtrl.dispose();
    _notesCtrl.dispose();
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
        'nom_entreprise': _raisonCtrl.text.trim(),
        'rccm': _rccmCtrl.text.trim(),
        'adresse': _adresseCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'type_activite': _typeActiviteCtrl.text.trim(),
        // champs supprimés: representant_legal, telephone_representant
        'personne_contact': _personneContactCtrl.text.trim(),
        'fonction_contact': _fonctionContactCtrl.text.trim(),
        'telephone_contact': _telContactCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      };

      final files = <http.MultipartFile>[];
      // plus de logo/document

      final path = _withContrav
          ? '/create-entreprise-with-contravention'
          : '/create-entreprise';
      print('DEBUG: Calling endpoint: $path, withContrav: $_withContrav');
      if (_withContrav) {
        fields.addAll({
          'contrav_date_heure': _selectedDateTime != null
              ? _selectedDateTime!.toIso8601String()
              : DateTime.now().toIso8601String(),
          'contrav_lieu': _cLieuCtrl.text.trim(),
          'contrav_type_infraction': _cTypeInfractionCtrl.text.trim(),
          'contrav_reference_loi': _cRefLoiCtrl.text.trim(),
          'contrav_montant': _cMontantCtrl.text.trim(),
          'contrav_description': _cDescriptionCtrl.text.trim(),
          'contrav_payee': _cPayee ? '1' : '0',
        });
        // Add multiple photos with field name 'contrav_photos[]' for PHP array
        for (final p in _contravPhotos) {
          if (kIsWeb) {
            // Sur le web, utiliser les bytes car path n'est pas disponible
            if (p.bytes != null) {
              files.add(http.MultipartFile.fromBytes(
                'contrav_photos[]',
                p.bytes!,
                filename: p.name,
              ));
            }
          } else {
            // Sur mobile/desktop, utiliser le chemin si disponible, sinon les bytes
            if (p.path != null) {
              files.add(await http.MultipartFile.fromPath(
                  'contrav_photos[]', p.path!));
            } else if (p.bytes != null) {
              files.add(http.MultipartFile.fromBytes(
                'contrav_photos[]',
                p.bytes!,
                filename: p.name,
              ));
            }
          }
        }
      }

      final resp = await api.postMultipart(path, fields: fields, files: files);
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      if (!ok) throw Exception('Erreur (${resp.statusCode})');
      NotificationService.success(context, 'Entreprise enregistrée');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      NotificationService.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Pickers supprimés (logo/document)

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
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
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
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
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
          // Mettre à jour le contrôleur de texte pour l'affichage
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
        withData: true);
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
                  color: Colors.black.withOpacity(0.7),
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
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Enregistrer une entreprise'),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations principales', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 380,
                    child: TextFormField(
                      controller: _raisonCtrl,
                      decoration: const InputDecoration(
                          labelText: "Nom de l'entreprise *"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _rccmCtrl,
                      decoration: const InputDecoration(labelText: 'RCCM'),
                    ),
                  ),
                  // Champs supprimés: ID Nat., Numéro d'impôt
                  SizedBox(
                    width: 380,
                    child: TextFormField(
                      controller: _adresseCtrl,
                      decoration: const InputDecoration(labelText: 'Adresse *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _telephoneCtrl,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _typeActiviteCtrl,
                      decoration:
                          const InputDecoration(labelText: "Type d'activité"),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Uploads supprimés: logo/document
                const SizedBox(height: 16),
                Text('Représentant / Contact', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  // Champs supprimés: Représentant légal, Téléphone représentant
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _personneContactCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Personne à contacter'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _fonctionContactCtrl,
                      decoration: const InputDecoration(labelText: 'Fonction'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _telContactCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Téléphone contact'),
                    ),
                  ),
                  SizedBox(
                    width: 640,
                    child: TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _withContrav,
                      onChanged: (v) => setState(() => _withContrav = v),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                        "Attribuer une contravention à l’enregistrement"),
                  ],
                ),
                if (_withContrav) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                        width: 220,
                        child: TextFormField(
                          controller: _cDateHeureCtrl,
                          readOnly: true,
                          onTap: _submitting ? null : _selectDateTime,
                          decoration: const InputDecoration(
                            labelText: 'Date/heure *',
                            suffixIcon: Icon(Icons.calendar_today),
                            hintText: 'Sélectionner date/heure',
                          ),
                          validator: (v) =>
                              _withContrav && (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          controller: _cLieuCtrl,
                          decoration: const InputDecoration(labelText: 'Lieu'),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: TextFormField(
                          controller: _cTypeInfractionCtrl,
                          decoration: const InputDecoration(
                              labelText: "Type d’infraction *"),
                          validator: (v) =>
                              _withContrav && (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _cRefLoiCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Réf. loi'),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _cMontantCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Montant amende'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: 640,
                        child: TextFormField(
                          controller: _cDescriptionCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 2,
                        ),
                      ),
                      Row(children: [
                        Checkbox(
                            value: _cPayee,
                            onChanged: (v) =>
                                setState(() => _cPayee = v ?? false)),
                        const Text('Amende payée'),
                      ]),
                      SizedBox(
                        width: 360,
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickContravPhotos,
                          icon: const Icon(Icons.photo_library),
                          label: Text(_contravPhotos.isEmpty
                              ? 'Ajouter photos (JPG/PNG/GIF)'
                              : '${_contravPhotos.length} photo(s) sélectionnée(s)'),
                        ),
                      ),
                      if (_contravPhotos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Photos sélectionnées (${_contravPhotos.length})',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _contravPhotos.length,
                            itemBuilder: (context, index) {
                              final file = _contravPhotos[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                child: Stack(
                                  children: [
                                    // Image preview
                                    GestureDetector(
                                      onTap: () => _showImagePreview(file),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: file.bytes != null
                                              ? Image.memory(
                                                  file.bytes!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 24,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                    size: 24,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    // Delete button
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _contravPhotos.removeAt(index));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        )
      ],
    );
  }
}
