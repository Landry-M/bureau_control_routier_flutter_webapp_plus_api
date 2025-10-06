import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../utils/image_utils.dart';
import '../utils/date_time_picker_theme.dart';

class ConducteurVehiculeModal extends StatefulWidget {
  const ConducteurVehiculeModal({super.key});

  @override
  State<ConducteurVehiculeModal> createState() =>
      _ConducteurVehiculeModalState();
}

class _ConducteurVehiculeModalState extends State<ConducteurVehiculeModal> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _withContravention = false;

  // Conducteur fields
  final _nomController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _adresseController = TextEditingController();
  final _observationsController = TextEditingController();
  DateTime? _dateNaissance;
  DateTime? _permisValideDate;
  DateTime? _permisExpireDate;
  dynamic _photoPersonnelle;
  dynamic _permisRecto;
  dynamic _permisVerso;

  // Véhicule fields
  final _plaqueController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();
  final _chassisController = TextEditingController();
  final _moteurController = TextEditingController();
  final _proprietaireController = TextEditingController();
  final _usageController = TextEditingController();
  DateTime? _dateImportation;
  DateTime? _datePlaque;

  // Contravention fields
  final _lieuController = TextEditingController();
  final _typeInfractionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceLoi = TextEditingController();
  final _amendeController = TextEditingController();
  DateTime? _dateInfraction;
  bool _contraventionPayee = false;
  List<dynamic> _photosContravention = [];

  @override
  void dispose() {
    _nomController.dispose();
    _numeroPermisController.dispose();
    _adresseController.dispose();
    _observationsController.dispose();
    _plaqueController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _chassisController.dispose();
    _moteurController.dispose();
    _proprietaireController.dispose();
    _usageController.dispose();
    _lieuController.dispose();
    _typeInfractionController.dispose();
    _descriptionController.dispose();
    _referenceLoi.dispose();
    _amendeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge, color: cs.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Conducteur et Véhicule',
                      style: tt.titleLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: cs.onPrimary),
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
                      _buildConducteurSection(cs, tt),
                      const SizedBox(height: 24),
                      _buildVehiculeSection(cs, tt),
                      const SizedBox(height: 24),
                      _buildContraventionSection(cs, tt),
                      const SizedBox(height: 32),
                      _buildActionButtons(cs, tt),
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

  Widget _buildConducteurSection(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations du Conducteur',
            style: tt.titleMedium
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Informations personnelles
        Text('Informations personnelles',
            style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 320,
                child: _buildTextField('Nom complet *', _nomController,
                    required: true)),
            SizedBox(
                width: 200,
                child: _buildDateField('Date de naissance', _dateNaissance,
                    (date) => _dateNaissance = date)),
            SizedBox(
                width: 450,
                child: _buildTextField('Adresse', _adresseController)),
          ],
        ),

        const SizedBox(height: 16),

        // Informations du permis
        Text('Informations du permis',
            style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 220,
                child: _buildTextField(
                    'Numéro de permis', _numeroPermisController)),
            SizedBox(
                width: 180,
                child: _buildDateField('Permis valide le', _permisValideDate,
                    (date) => _permisValideDate = date)),
            SizedBox(
                width: 180,
                child: _buildDateField('Permis expire le', _permisExpireDate,
                    (date) => _permisExpireDate = date)),
          ],
        ),

        const SizedBox(height: 16),

        // Observations
        Text('Observations', style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 600,
                child: _buildTextField('Observations', _observationsController,
                    maxLines: 3)),
          ],
        ),

        const SizedBox(height: 16),

        // Photos
        Text('Photos', style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        _buildPhotosSection(),
      ],
    );
  }

  Widget _buildVehiculeSection(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations du Véhicule',
            style: tt.titleMedium
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Identification du véhicule
        Text('Identification',
            style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 220,
                child: _buildTextField(
                    'Plaque d\'immatriculation *', _plaqueController,
                    required: true)),
            SizedBox(
                width: 180,
                child: _buildTextField('Marque *', _marqueController,
                    required: true)),
            SizedBox(
                width: 180,
                child: _buildTextField('Modèle *', _modeleController,
                    required: true)),
            SizedBox(
                width: 150,
                child: _buildTextField('Couleur', _couleurController)),
            SizedBox(
                width: 120, child: _buildTextField('Année', _anneeController)),
          ],
        ),

        const SizedBox(height: 16),

        // Caractéristiques techniques
        Text('Caractéristiques techniques',
            style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 220,
                child:
                    _buildTextField('Numéro de châssis', _chassisController)),
            SizedBox(
                width: 220,
                child: _buildTextField('Numéro de moteur', _moteurController)),
            SizedBox(
                width: 180, child: _buildTextField('Usage', _usageController)),
          ],
        ),

        const SizedBox(height: 16),

        // Propriété et dates
        Text('Propriété et dates',
            style: tt.titleSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 280,
                child:
                    _buildTextField('Propriétaire', _proprietaireController)),
            SizedBox(
                width: 180,
                child: _buildDateField('Date d\'importation', _dateImportation,
                    (date) => _dateImportation = date)),
            SizedBox(
                width: 180,
                child: _buildDateField('Date de plaque', _datePlaque,
                    (date) => _datePlaque = date)),
          ],
        ),
      ],
    );
  }

  Widget _buildContraventionSection(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Contravention',
                style: tt.titleMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            Switch(
              value: _withContravention,
              onChanged: (value) => setState(() => _withContravention = value),
            ),
            Text('Assigner une contravention', style: tt.bodyMedium),
          ],
        ),
        if (_withContravention) ...[
          const SizedBox(height: 16),

          // Informations de base
          Text('Informations de base',
              style: tt.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: 220,
                  child: _buildDateTimeField('Date/Heure infraction *',
                      _dateInfraction, (date) => _dateInfraction = date)),
              SizedBox(
                  width: 280,
                  child: _buildTextField('Lieu *', _lieuController,
                      required: _withContravention)),
              SizedBox(
                  width: 280,
                  child: _buildTextField(
                      'Type d\'infraction *', _typeInfractionController,
                      required: _withContravention)),
            ],
          ),

          const SizedBox(height: 16),

          // Détails légaux et financiers
          Text('Détails légaux et financiers',
              style: tt.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: 220,
                  child: _buildTextField('Référence loi', _referenceLoi)),
              SizedBox(
                  width: 180,
                  child: _buildTextField('Montant amende', _amendeController)),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text('Description',
              style: tt.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: 600,
                  child: _buildTextField('Description', _descriptionController,
                      maxLines: 3)),
            ],
          ),

          const SizedBox(height: 16),

          // Statut de paiement
          Text('Statut de paiement',
              style: tt.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _contraventionPayee,
                onChanged: (value) =>
                    setState(() => _contraventionPayee = value ?? false),
              ),
              Text('Contravention payée', style: tt.bodyMedium),
            ],
          ),

          const SizedBox(height: 16),

          // Photos de contravention
          Text('Photos de contravention',
              style: tt.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          _buildPhotosContraventionSection(),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: required
          ? (value) => value?.isEmpty == true ? 'Ce champ est requis' : null
          : null,
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () => _selectDate(onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : ''),
      ),
    );
  }

  Widget _buildDateTimeField(
      String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () => _selectDateTime(onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
            : ''),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos du conducteur',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPhotoUpload('Photo personnelle', _photoPersonnelle,
                (file) => setState(() => _photoPersonnelle = file)),
            const SizedBox(width: 16),
            _buildPhotoUpload('Permis recto', _permisRecto,
                (file) => setState(() => _permisRecto = file)),
            const SizedBox(width: 16),
            _buildPhotoUpload('Permis verso', _permisVerso,
                (file) => setState(() => _permisVerso = file)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosContraventionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos de contravention (${_photosContravention.length})',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _pickContraventionPhotos,
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        if (_photosContravention.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photosContravention.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: ImageUtils.buildImageWidget(
                              _photosContravention[index],
                              fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _photosContravention.removeAt(index)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
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
      ],
    );
  }

  Widget _buildPhotoUpload(
      String label, dynamic photo, Function(dynamic) onChanged) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(onChanged),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ImageUtils.buildImageWidget(photo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme cs, TextTheme tt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _selectDate(Function(DateTime?) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: buildThemedPicker,
    );
    if (date != null) onChanged(date);
  }

  Future<void> _selectDateTime(Function(DateTime?) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: buildThemedPicker,
    );
    if (date != null) {
      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: buildThemedPicker);
      if (time != null) {
        onChanged(
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _pickImage(Function(dynamic) onChanged) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) onChanged(ImageUtils.processPickedImage(image));
  }

  Future<void> _pickContraventionPhotos() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _photosContravention
            .addAll(images.map((img) => ImageUtils.processPickedImage(img)));
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_withContravention &&
        (_dateInfraction == null ||
            _lieuController.text.isEmpty ||
            _typeInfractionController.text.isEmpty)) {
      _showError('Veuillez remplir tous les champs requis de la contravention');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = context.read<AuthProvider>().username;
      final request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConfig.baseUrl}/conducteur-vehicule/create'));

      // Conducteur data
      request.fields['nom'] = _nomController.text;
      request.fields['numero_permis'] = _numeroPermisController.text;
      request.fields['adresse'] = _adresseController.text;
      request.fields['observations'] = _observationsController.text;
      request.fields['username'] = username;
      if (_dateNaissance != null)
        request.fields['date_naissance'] = _dateNaissance!.toIso8601String();
      if (_permisValideDate != null)
        request.fields['permis_valide_le'] =
            _permisValideDate!.toIso8601String();
      if (_permisExpireDate != null)
        request.fields['permis_expire_le'] =
            _permisExpireDate!.toIso8601String();

      // Véhicule data
      request.fields['plaque'] = _plaqueController.text;
      request.fields['marque'] = _marqueController.text;
      request.fields['modele'] = _modeleController.text;
      request.fields['couleur'] = _couleurController.text;
      request.fields['annee'] = _anneeController.text;
      request.fields['chassis'] = _chassisController.text;
      request.fields['moteur'] = _moteurController.text;
      request.fields['proprietaire'] = _proprietaireController.text;
      request.fields['usage'] = _usageController.text;
      if (_dateImportation != null)
        request.fields['date_importation'] =
            _dateImportation!.toIso8601String();
      if (_datePlaque != null)
        request.fields['date_plaque'] = _datePlaque!.toIso8601String();

      // Contravention data
      request.fields['with_contravention'] = _withContravention.toString();
      if (_withContravention) {
        request.fields['cv_lieu'] = _lieuController.text;
        request.fields['cv_type_infraction'] = _typeInfractionController.text;
        request.fields['cv_description'] = _descriptionController.text;
        request.fields['cv_reference_loi'] = _referenceLoi.text;
        request.fields['cv_amende'] = _amendeController.text;
        request.fields['cv_payed'] = _contraventionPayee ? '1' : '0';
        if (_dateInfraction != null)
          request.fields['cv_date_infraction'] =
              _dateInfraction!.toIso8601String();
      }

      // Photos
      if (_photoPersonnelle != null) {
        request.files.add(
            await ImageUtils.createMultipartFile(_photoPersonnelle, 'photo'));
      }
      if (_permisRecto != null) {
        request.files.add(
            await ImageUtils.createMultipartFile(_permisRecto, 'permis_recto'));
      }
      if (_permisVerso != null) {
        request.files.add(
            await ImageUtils.createMultipartFile(_permisVerso, 'permis_verso'));
      }

      for (int i = 0; i < _photosContravention.length; i++) {
        request.files.add(await ImageUtils.createMultipartFile(
            _photosContravention[i], 'contravention_photos[]'));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          _showSuccess('Conducteur et véhicule enregistrés avec succès');
          Navigator.of(context).pop();
        } else {
          _showError(data['message'] ?? 'Erreur lors de l\'enregistrement');
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
      title: Text('Succès'),
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
      title: Text('Erreur'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
    );
  }
}
