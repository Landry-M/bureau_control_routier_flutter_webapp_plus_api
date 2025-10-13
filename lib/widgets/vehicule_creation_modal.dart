import 'package:flutter/material.dart';
import '../services/vehicule_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/notification_service.dart';
import '../utils/date_time_picker_theme.dart';

class VehiculeCreationModal extends StatefulWidget {
  const VehiculeCreationModal({super.key, this.initialPlaque});

  final String? initialPlaque;

  @override
  State<VehiculeCreationModal> createState() => _VehiculeCreationModalState();
}

class _VehiculeCreationModalState extends State<VehiculeCreationModal> {
  final _formKey = GlobalKey<FormState>();
  final _vehiculeService = VehiculeService();
  
  // Controllers pour les champs
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeController = TextEditingController();
  final _couleurController = TextEditingController();
  final _numeroChassisController = TextEditingController();
  final _frontiereEntreeController = TextEditingController();
  final _dateImportationController = TextEditingController();
  final _plaqueController = TextEditingController();
  final _plaqueValideLe = TextEditingController();
  final _plaqueExpireLe = TextEditingController();
  final _numeAssuranceController = TextEditingController();
  final _societeAssuranceController = TextEditingController();
  final _dateValideAssuranceController = TextEditingController();
  final _dateExpireAssuranceController = TextEditingController();
  
  // Détails techniques DGI
  final _genreController = TextEditingController();
  final _usageController = TextEditingController();
  final _numeroDeclarationController = TextEditingController();
  final _numMoteurController = TextEditingController();
  final _origineController = TextEditingController();
  final _sourceController = TextEditingController();
  final _anneeFabController = TextEditingController();
  final _anneeCircController = TextEditingController();
  final _typeEmController = TextEditingController();
  
  // Contravention
  final _cvDateInfractionController = TextEditingController();
  final _cvLieuController = TextEditingController();
  final _cvTypeInfractionController = TextEditingController();
  final _cvDescriptionController = TextEditingController();
  final _cvReferenceLoi = TextEditingController();
  final _cvAmendeController = TextEditingController();
  
  bool _withContravention = false;
  bool _cvPayed = false;
  bool _isLoading = false;
  List<PlatformFile> _vehicleFiles = [];
  List<PlatformFile> _contraventionFiles = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehiculeSection(),
                      const SizedBox(height: 24),
                      _buildPlaqueSection(),
                      const SizedBox(height: 24),
                      _buildTechnicalSection(),
                      const SizedBox(height: 24),
                      _buildAssuranceSection(),
                      const SizedBox(height: 24),
                      _buildContraventionSwitch(),
                      if (_withContravention) ...[
                        const SizedBox(height: 16),
                        _buildContraventionSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPlaque != null && widget.initialPlaque!.isNotEmpty) {
      _plaqueController.text = widget.initialPlaque!;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.directions_car, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Créer un véhicule',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildVehiculeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations du véhicule', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildVehicleImagePicker(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modeleController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anneeController,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _couleurController,
                    decoration: const InputDecoration(
                      labelText: 'Couleur *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requis' : null,
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
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _frontiereEntreeController,
                    decoration: const InputDecoration(
                      labelText: 'Frontière d\'entrée',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dateImportationController,
                    decoration: const InputDecoration(
                      labelText: 'Date d\'importation',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_dateImportationController),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaqueSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plaque d\'immatriculation', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plaqueController,
                    decoration: const InputDecoration(
                      labelText: 'Plaque d\'immatriculation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchPlaque,
                  child: const Text('Rechercher'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plaqueValideLe,
                    decoration: const InputDecoration(
                      labelText: 'Valide le',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_plaqueValideLe),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _plaqueExpireLe,
                    decoration: const InputDecoration(
                      labelText: 'Expire le',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_plaqueExpireLe),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails techniques (DGI)', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _genreController,
                    decoration: const InputDecoration(
                      labelText: 'Genre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _usageController,
                    decoration: const InputDecoration(
                      labelText: 'Usage',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroDeclarationController,
              decoration: const InputDecoration(
                labelText: 'Numéro volet jaune',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numMoteurController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro moteur',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _origineController,
                    decoration: const InputDecoration(
                      labelText: 'Origine',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssuranceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations d\'assurance', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numeAssuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro d\'assurance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _societeAssuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Société d\'assurance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateValideAssuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Date valide assurance',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_dateValideAssuranceController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dateExpireAssuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Date expire assurance',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_dateExpireAssuranceController),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContraventionSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Switch(
              value: _withContravention,
              onChanged: (value) {
                setState(() {
                  _withContravention = value;
                });
              },
            ),
            const SizedBox(width: 8),
            const Text('Attribuer directement une contravention'),
          ],
        ),
      ),
    );
  }

  Widget _buildContraventionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contravention', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cvDateInfractionController,
                    decoration: const InputDecoration(
                      labelText: 'Date/Heure infraction',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDateTime(_cvDateInfractionController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvLieuController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cvTypeInfractionController,
              decoration: const InputDecoration(
                labelText: 'Type d\'infraction',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cvReferenceLoi,
                    decoration: const InputDecoration(
                      labelText: 'Référence de loi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvAmendeController,
                    decoration: const InputDecoration(
                      labelText: 'Montant amende',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cvDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildContraventionImagePicker(),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _cvPayed,
                  onChanged: (value) {
                    setState(() {
                      _cvPayed = value ?? false;
                    });
                  },
                ),
                const Text('Contravention payée'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickVehicleImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter des images'),
        ),
        if (_vehicleFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildThumbnails(
            _vehicleFiles,
            (f) => setState(() => _vehicleFiles.remove(f)),
          ),
        ],
      ],
    );
  }

  Widget _buildContraventionImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickContraventionImages,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Ajouter des photos pour la contravention'),
        ),
        if (_contraventionFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildThumbnails(
            _contraventionFiles,
            (f) => setState(() => _contraventionFiles.remove(f)),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnails(List<PlatformFile> files, void Function(PlatformFile) onRemove) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: files.map((f) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: f.bytes != null
                    ? Image.memory(
                        f.bytes!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          (f.extension ?? 'file').toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ),
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

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveVehicule,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _withContravention
                      ? 'Enregistrer le véhicule et créer la contravention'
                      : 'Enregistrer le véhicule',
                ),
        ),
      ],
    );
  }

  Future<void> _pickVehicleImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _vehicleFiles.addAll(result.files);
      });
    }
  }

  Future<void> _pickContraventionImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _contraventionFiles.addAll(result.files);
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: buildThemedPicker,
    );
    if (date != null) {
      controller.text = date.toIso8601String().split('T')[0];
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: buildThemedPicker,
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: buildThemedPicker,
      );
      
      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        controller.text = dateTime.toIso8601String();
      }
    }
  }

  Future<void> _searchPlaque() async {
    if (_plaqueController.text.isEmpty) return;
    
    try {
      final result = await _vehiculeService.searchPlaque(_plaqueController.text);
      if (result != null) {
        // Pré-remplir les champs avec les données trouvées
        _marqueController.text = result['marque'] ?? '';
        _modeleController.text = result['modele'] ?? '';
        _couleurController.text = result['couleur'] ?? '';
        // ... autres champs
        
        NotificationService.success(context, 'Données trouvées et pré-remplies');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      NotificationService.error(context, errorMessage);
    }
  }

  Future<void> _saveVehicule() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = {
        'marque': _marqueController.text,
        'modele': _modeleController.text,
        'annee': _anneeController.text,
        'couleur': _couleurController.text,
        'numero_chassis': _numeroChassisController.text,
        'frontiere_entree': _frontiereEntreeController.text,
        'date_importation': _dateImportationController.text,
        'plaque': _plaqueController.text,
        'plaque_valide_le': _plaqueValideLe.text,
        'plaque_expire_le': _plaqueExpireLe.text,
        'nume_assurance': _numeAssuranceController.text,
        'societe_assurance': _societeAssuranceController.text,
        'date_valide_assurance': _dateValideAssuranceController.text,
        'date_expire_assurance': _dateExpireAssuranceController.text,
        'genre': _genreController.text,
        'usage': _usageController.text,
        'numero_declaration': _numeroDeclarationController.text,
        'num_moteur': _numMoteurController.text,
        'origine': _origineController.text,
        'source': _sourceController.text,
        'annee_fab': _anneeFabController.text,
        'annee_circ': _anneeCircController.text,
        'type_em': _typeEmController.text,
        'with_contravention': _withContravention ? '1' : '0',
      };
      
      if (_withContravention) {
        data.addAll({
          'cv_date_infraction': _cvDateInfractionController.text,
          'cv_lieu': _cvLieuController.text,
          'cv_type_infraction': _cvTypeInfractionController.text,
          'cv_description': _cvDescriptionController.text,
          'cv_reference_loi': _cvReferenceLoi.text,
          'cv_amende': _cvAmendeController.text,
          'cv_payed': _cvPayed ? '1' : '0',
        });
      }
      
      final result = await _vehiculeService.createVehicule(
        data,
        _vehicleFiles,
        _contraventionFiles,
      );
      
      if (result['success'] == true || result['state'] == true) {
        Navigator.of(context).pop();
        NotificationService.success(context, result['message'] ?? 'Véhicule créé avec succès');
      } else {
        final errorMessage = result['message'] ?? 'Erreur lors de la création du véhicule';
        NotificationService.error(context, errorMessage);
      }
    } catch (e) {
      // Extraire uniquement le message d'erreur sans le préfixe "Exception:"
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // Enlever "Exception: "
      }
      NotificationService.error(context, errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    _numeroChassisController.dispose();
    _frontiereEntreeController.dispose();
    _dateImportationController.dispose();
    _plaqueController.dispose();
    _plaqueValideLe.dispose();
    _plaqueExpireLe.dispose();
    _numeAssuranceController.dispose();
    _societeAssuranceController.dispose();
    _dateValideAssuranceController.dispose();
    _dateExpireAssuranceController.dispose();
    _genreController.dispose();
    _usageController.dispose();
    _numeroDeclarationController.dispose();
    _numMoteurController.dispose();
    _origineController.dispose();
    _sourceController.dispose();
    _anneeFabController.dispose();
    _anneeCircController.dispose();
    _typeEmController.dispose();
    _cvDateInfractionController.dispose();
    _cvLieuController.dispose();
    _cvTypeInfractionController.dispose();
    _cvDescriptionController.dispose();
    _cvReferenceLoi.dispose();
    _cvAmendeController.dispose();
    super.dispose();
  }
}
