import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../utils/date_time_picker_theme.dart';

class CreateParticulierModal extends StatefulWidget {
  const CreateParticulierModal({super.key});

  @override
  State<CreateParticulierModal> createState() => _CreateParticulierModalState();
}

class _CreateParticulierModalState extends State<CreateParticulierModal> {
  final _formKey = GlobalKey<FormState>();

  // Champs principaux
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  DateTime? _dateNaissance;
  final _dateNaissanceCtrl = TextEditingController();
  String? _genre;
  final _numeroNationalCtrl = TextEditingController();
  final _gsmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _lieuNaissanceCtrl = TextEditingController();
  final _nationaliteCtrl = TextEditingController();
  String? _etatCivil;
  final _personneContactCtrl = TextEditingController();
  final _personneContactTelCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();

  // Type de document (pour numero_national)
  String _typeDocument = 'carte_electeur';
  
  // Permis de conduire
  bool _hasPermis = false;
  DateTime? _permisDateEmission;
  DateTime? _permisDateExpiration;
  final _permisDateEmissionCtrl = TextEditingController();
  final _permisDateExpirationCtrl = TextEditingController();

  // Photos
  PlatformFile? _photo;
  PlatformFile? _permisRecto;
  PlatformFile? _permisVerso;

  bool _submitting = false;
  bool _checkingDuplicate = false;

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
  List<PlatformFile> _contravPhotos = [];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _professionCtrl.dispose();
    _dateNaissanceCtrl.dispose();
    _numeroNationalCtrl.dispose();
    _gsmCtrl.dispose();
    _emailCtrl.dispose();
    _lieuNaissanceCtrl.dispose();
    _nationaliteCtrl.dispose();
    _personneContactCtrl.dispose();
    _personneContactTelCtrl.dispose();
    _observationsCtrl.dispose();
    _permisDateEmissionCtrl.dispose();
    _permisDateExpirationCtrl.dispose();
    _cDateHeureCtrl.dispose();
    _cLieuCtrl.dispose();
    _cTypeInfractionCtrl.dispose();
    _cRefLoiCtrl.dispose();
    _cMontantCtrl.dispose();
    _cDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateNaissance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: buildThemedPicker,
    );

    if (date != null && mounted) {
      setState(() {
        _dateNaissance = date;
        _dateNaissanceCtrl.text =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      });
    }
  }

  Future<void> _selectPermisDateEmission() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _permisDateEmission ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: buildThemedPicker,
    );

    if (date != null && mounted) {
      setState(() {
        _permisDateEmission = date;
        _permisDateEmissionCtrl.text =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      });
    }
  }

  Future<void> _selectPermisDateExpiration() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _permisDateExpiration ?? DateTime.now().add(const Duration(days: 365 * 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      builder: buildThemedPicker,
    );

    if (date != null && mounted) {
      setState(() {
        _permisDateExpiration = date;
        _permisDateExpirationCtrl.text =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      });
    }
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _photo = res.files.first);
    }
  }

  Future<void> _pickPermisRecto() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _permisRecto = res.files.first);
    }
  }

  Future<void> _pickPermisVerso() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _permisVerso = res.files.first);
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
                  primary: Colors.blue,
                  onPrimary: Colors.black,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
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
                    onPrimary: Colors.black,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
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

  String get _numeroNationalPlaceholder {
    switch (_typeDocument) {
      case 'passeport':
        return 'Numéro passeport';
      case 'carte_electeur':
      default:
        return 'Numéro national';
    }
  }

  Future<bool> _checkIfParticulierExists(String nom) async {
    if (nom.trim().isEmpty) return false;
    
    setState(() => _checkingDuplicate = true);
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final response = await api.get('/check-particulier-exists?nom=${Uri.encodeComponent(nom.trim())}');
      
      if (response.statusCode == 200) {
        // Supposer que la réponse est un JSON avec un champ 'exists'
        return response.body.contains('"exists":true');
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    } finally {
      if (mounted) setState(() => _checkingDuplicate = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Vérifier les doublons
    final exists = await _checkIfParticulierExists(_nomCtrl.text);
    if (exists) {
      NotificationService.error(context, 'Un particulier avec ce nom existe déjà dans la base de données.');
      return;
    }
    
    setState(() => _submitting = true);
    
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final fields = <String, String>{
        'nom': _nomCtrl.text.trim(),
        'adresse': _adresseCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'date_naissance': _dateNaissance?.toIso8601String() ?? '',
        'genre': _genre ?? '',
        'numero_national': _numeroNationalCtrl.text.trim(),
        'gsm': _gsmCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'lieu_naissance': _lieuNaissanceCtrl.text.trim(),
        'nationalite': _nationaliteCtrl.text.trim(),
        'etat_civil': _etatCivil ?? '',
        'personne_contact': _personneContactCtrl.text.trim(),
        'personne_contact_telephone': _personneContactTelCtrl.text.trim(),
        'observations': _observationsCtrl.text.trim(),
      };

      // Ajouter les champs permis si activés
      if (_hasPermis) {
        fields.addAll({
          'permis_date_emission': _permisDateEmission?.toIso8601String().split('T')[0] ?? '',
          'permis_date_expiration': _permisDateExpiration?.toIso8601String().split('T')[0] ?? '',
        });
      }

      final files = <http.MultipartFile>[];
      
      // Photo principale
      if (_photo != null) {
        if (kIsWeb && _photo!.bytes != null) {
          files.add(http.MultipartFile.fromBytes(
            'photo',
            _photo!.bytes!,
            filename: _photo!.name,
          ));
        } else if (_photo!.path != null) {
          files.add(await http.MultipartFile.fromPath('photo', _photo!.path!));
        }
      }

      // Photos permis si activées
      if (_hasPermis) {
        if (_permisRecto != null) {
          if (kIsWeb && _permisRecto!.bytes != null) {
            files.add(http.MultipartFile.fromBytes(
              'permis_recto',
              _permisRecto!.bytes!,
              filename: _permisRecto!.name,
            ));
          } else if (_permisRecto!.path != null) {
            files.add(await http.MultipartFile.fromPath('permis_recto', _permisRecto!.path!));
          }
        }

        if (_permisVerso != null) {
          if (kIsWeb && _permisVerso!.bytes != null) {
            files.add(http.MultipartFile.fromBytes(
              'permis_verso',
              _permisVerso!.bytes!,
              filename: _permisVerso!.name,
            ));
          } else if (_permisVerso!.path != null) {
            files.add(await http.MultipartFile.fromPath('permis_verso', _permisVerso!.path!));
          }
        }
      }

      final path = _withContrav
          ? '/create-particulier-with-contravention'
          : '/create-particulier';
      
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
      
      NotificationService.success(context, 'Particulier enregistré');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      NotificationService.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Enregistrer un particulier'),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: 950,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations personnelles', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _nomCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nom complet *',
                        suffixIcon: _checkingDuplicate 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _genre,
                      decoration: const InputDecoration(labelText: 'Genre'),
                      items: const [
                        DropdownMenuItem(value: 'Masculin', child: Text('Masculin')),
                        DropdownMenuItem(value: 'Féminin', child: Text('Féminin')),
                      ],
                      onChanged: (v) => setState(() => _genre = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _dateNaissanceCtrl,
                      readOnly: true,
                      onTap: _submitting ? null : _selectDateNaissance,
                      decoration: const InputDecoration(
                        labelText: 'Date de naissance',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _lieuNaissanceCtrl,
                      decoration: const InputDecoration(labelText: 'Lieu de naissance'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _nationaliteCtrl,
                      decoration: const InputDecoration(labelText: 'Nationalité'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _etatCivil,
                      decoration: const InputDecoration(labelText: 'État civil'),
                      items: const [
                        DropdownMenuItem(value: 'Célibataire', child: Text('Célibataire')),
                        DropdownMenuItem(value: 'Marié(e)', child: Text('Marié(e)')),
                        DropdownMenuItem(value: 'Divorcé(e)', child: Text('Divorcé(e)')),
                        DropdownMenuItem(value: 'Veuf/Veuve', child: Text('Veuf/Veuve')),
                      ],
                      onChanged: (v) => setState(() => _etatCivil = v),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _professionCtrl,
                      decoration: const InputDecoration(labelText: 'Profession'),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _adresseCtrl,
                      decoration: const InputDecoration(labelText: 'Adresse'),
                      maxLines: 2,
                    ),
                  ),
                ]),
                
                const SizedBox(height: 16),
                Text('Document d\'identité', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _typeDocument,
                      decoration: const InputDecoration(labelText: 'Type de document'),
                      items: const [
                        DropdownMenuItem(value: 'carte_electeur', child: Text('Carte électeur')),
                        DropdownMenuItem(value: 'passeport', child: Text('Passeport')),
                      ],
                      onChanged: (v) => setState(() => _typeDocument = v ?? 'carte_electeur'),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _numeroNationalCtrl,
                      decoration: InputDecoration(labelText: _numeroNationalPlaceholder),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),
                Text('Contact', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _gsmCtrl,
                      decoration: const InputDecoration(labelText: 'GSM'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _personneContactCtrl,
                      decoration: const InputDecoration(labelText: 'Personne à contacter'),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _personneContactTelCtrl,
                      decoration: const InputDecoration(labelText: 'Téléphone contact'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ]),

                const SizedBox(height: 16),
                Text('Photo', style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 300,
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera),
                      label: Text(_photo == null ? 'Ajouter photo' : 'Photo sélectionnée'),
                    ),
                  ),
                  if (_photo != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _photo!.bytes != null
                            ? Image.memory(_photo!.bytes!, fit: BoxFit.cover)
                            : const Icon(Icons.photo, size: 50),
                      ),
                    ),
                ]),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _hasPermis,
                      onChanged: (v) => setState(() => _hasPermis = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Possède un permis de conduire'),
                  ],
                ),

                if (_hasPermis) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations permis de conduire', style: tt.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _permisDateEmissionCtrl,
                              readOnly: true,
                              onTap: _submitting ? null : _selectPermisDateEmission,
                              decoration: const InputDecoration(
                                labelText: 'Date d\'émission',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _permisDateExpirationCtrl,
                              readOnly: true,
                              onTap: _submitting ? null : _selectPermisDateExpiration,
                              decoration: const InputDecoration(
                                labelText: 'Date d\'expiration',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(
                            width: 250,
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : _pickPermisRecto,
                              icon: const Icon(Icons.photo),
                              label: Text(_permisRecto == null 
                                ? 'Photo recto permis' 
                                : 'Recto sélectionné'),
                            ),
                          ),
                          if (_permisRecto != null)
                            Container(
                              width: 100,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: _permisRecto!.bytes != null
                                    ? Image.memory(_permisRecto!.bytes!, fit: BoxFit.cover)
                                    : const Icon(Icons.photo, size: 30),
                              ),
                            ),
                          SizedBox(
                            width: 250,
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : _pickPermisVerso,
                              icon: const Icon(Icons.photo),
                              label: Text(_permisVerso == null 
                                ? 'Photo verso permis' 
                                : 'Verso sélectionné'),
                            ),
                          ),
                          if (_permisVerso != null)
                            Container(
                              width: 100,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: _permisVerso!.bytes != null
                                    ? Image.memory(_permisVerso!.bytes!, fit: BoxFit.cover)
                                    : const Icon(Icons.photo, size: 30),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _withContrav,
                      onChanged: (v) => setState(() => _withContrav = v),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                        "Attribuer une contravention à l'enregistrement"),
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
                              labelText: "Type d'infraction *"),
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
                    ]),
                  ),
                ],

                const SizedBox(height: 16),
                Text('Observations', style: tt.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _observationsCtrl,
                    decoration: const InputDecoration(labelText: 'Observations'),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: (_submitting || _checkingDuplicate) ? null : _submit,
          child: (_submitting || _checkingDuplicate)
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
