import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../utils/image_utils.dart';
import '../utils/date_time_picker_theme.dart';

class EditVehiculeModal extends StatefulWidget {
  final Map<String, dynamic> vehicule;

  const EditVehiculeModal({
    Key? key,
    required this.vehicule,
  }) : super(key: key);

  @override
  State<EditVehiculeModal> createState() => _EditVehiculeModalState();
}

class _EditVehiculeModalState extends State<EditVehiculeModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers pour tous les champs
  late TextEditingController _marqueController;
  late TextEditingController _anneeController;
  late TextEditingController _couleurController;
  late TextEditingController _modeleController;
  late TextEditingController _numeroChassisController;
  late TextEditingController _frontiereEntreeController;
  late TextEditingController _dateImportationController;
  late TextEditingController _plaqueController;
  late TextEditingController _plaqueValideLe;
  late TextEditingController _plaqueExpireLe;
  late TextEditingController _numeAssuranceController;
  late TextEditingController _dateExpireAssuranceController;
  late TextEditingController _dateValideAssuranceController;
  late TextEditingController _societeAssuranceController;
  late TextEditingController _genreController;
  late TextEditingController _usageController;
  late TextEditingController _numeroDeclarationController;
  late TextEditingController _numMoteurController;
  late TextEditingController _origineController;
  late TextEditingController _sourceController;
  late TextEditingController _anneeFabController;
  late TextEditingController _anneeCircController;
  late TextEditingController _typeEmController;

  bool _enCirculation = true;
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _marqueController = TextEditingController(text: widget.vehicule['marque'] ?? '');
    _anneeController = TextEditingController(text: widget.vehicule['annee'] ?? '');
    _couleurController = TextEditingController(text: widget.vehicule['couleur'] ?? '');
    _modeleController = TextEditingController(text: widget.vehicule['modele'] ?? '');
    _numeroChassisController = TextEditingController(text: widget.vehicule['numero_chassis'] ?? '');
    _frontiereEntreeController = TextEditingController(text: widget.vehicule['frontiere_entree'] ?? '');
    _dateImportationController = TextEditingController(text: widget.vehicule['date_importation'] ?? '');
    _plaqueController = TextEditingController(text: widget.vehicule['plaque'] ?? '');
    _plaqueValideLe = TextEditingController(text: widget.vehicule['plaque_valide_le'] ?? '');
    _plaqueExpireLe = TextEditingController(text: widget.vehicule['plaque_expire_le'] ?? '');
    _numeAssuranceController = TextEditingController(text: widget.vehicule['nume_assurance'] ?? '');
    _dateExpireAssuranceController = TextEditingController(text: widget.vehicule['date_expire_assurance'] ?? '');
    _dateValideAssuranceController = TextEditingController(text: widget.vehicule['date_valide_assurance'] ?? '');
    _societeAssuranceController = TextEditingController(text: widget.vehicule['societe_assurance'] ?? '');
    _genreController = TextEditingController(text: widget.vehicule['genre'] ?? '');
    _usageController = TextEditingController(text: widget.vehicule['usage'] ?? '');
    _numeroDeclarationController = TextEditingController(text: widget.vehicule['numero_declaration'] ?? '');
    _numMoteurController = TextEditingController(text: widget.vehicule['num_moteur'] ?? '');
    _origineController = TextEditingController(text: widget.vehicule['origine'] ?? '');
    _sourceController = TextEditingController(text: widget.vehicule['source'] ?? '');
    _anneeFabController = TextEditingController(text: widget.vehicule['annee_fab'] ?? '');
    _anneeCircController = TextEditingController(text: widget.vehicule['annee_circ'] ?? '');
    _typeEmController = TextEditingController(text: widget.vehicule['type_em'] ?? '');
    
    _enCirculation = widget.vehicule['en_circulation'] == 1 || widget.vehicule['en_circulation'] == '1';
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    _modeleController.dispose();
    _numeroChassisController.dispose();
    _frontiereEntreeController.dispose();
    _dateImportationController.dispose();
    _plaqueController.dispose();
    _plaqueValideLe.dispose();
    _plaqueExpireLe.dispose();
    _numeAssuranceController.dispose();
    _dateExpireAssuranceController.dispose();
    _dateValideAssuranceController.dispose();
    _societeAssuranceController.dispose();
    _genreController.dispose();
    _usageController.dispose();
    _numeroDeclarationController.dispose();
    _numMoteurController.dispose();
    _origineController.dispose();
    _sourceController.dispose();
    _anneeFabController.dispose();
    _anneeCircController.dispose();
    _typeEmController.dispose();
    super.dispose();
  }

  Future<void> _selectImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb, // Sur web, on a besoin des bytes
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text('Erreur lors de la sélection des images: $e'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: buildThemedPicker,
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: buildThemedPicker,
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: buildThemedPicker,
      );
      
      if (pickedTime != null) {
        final DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          controller.text = "${combined.year}-${combined.month.toString().padLeft(2, '0')}-${combined.day.toString().padLeft(2, '0')} ${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}:00";
        });
      }
    }
  }

  Future<void> _updateVehicule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}?route=/vehicule/${widget.vehicule['id']}/update'),
      );

      // Ajouter tous les champs
      request.fields['marque'] = _marqueController.text;
      request.fields['annee'] = _anneeController.text;
      request.fields['couleur'] = _couleurController.text;
      request.fields['modele'] = _modeleController.text;
      request.fields['numero_chassis'] = _numeroChassisController.text;
      request.fields['frontiere_entree'] = _frontiereEntreeController.text;
      request.fields['date_importation'] = _dateImportationController.text;
      request.fields['plaque'] = _plaqueController.text;
      request.fields['plaque_valide_le'] = _plaqueValideLe.text;
      request.fields['plaque_expire_le'] = _plaqueExpireLe.text;
      request.fields['en_circulation'] = _enCirculation ? '1' : '0';
      request.fields['nume_assurance'] = _numeAssuranceController.text;
      request.fields['date_expire_assurance'] = _dateExpireAssuranceController.text;
      request.fields['date_valide_assurance'] = _dateValideAssuranceController.text;
      request.fields['societe_assurance'] = _societeAssuranceController.text;
      request.fields['genre'] = _genreController.text;
      request.fields['usage'] = _usageController.text;
      request.fields['numero_declaration'] = _numeroDeclarationController.text;
      request.fields['num_moteur'] = _numMoteurController.text;
      request.fields['origine'] = _origineController.text;
      request.fields['source'] = _sourceController.text;
      request.fields['annee_fab'] = _anneeFabController.text;
      request.fields['annee_circ'] = _anneeCircController.text;
      request.fields['type_em'] = _typeEmController.text;

      // Ajouter les images si sélectionnées
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        if (kIsWeb) {
          // Sur web, utiliser les bytes
          if (file.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'vehicule_images[]',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        } else {
          // Sur mobile/desktop, utiliser le path
          if (file.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'vehicule_images[]',
                file.path!,
              ),
            );
          }
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (jsonResponse['success'] == true) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Succès'),
          description: Text(jsonResponse['message'] ?? 'Véhicule modifié avec succès'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
        
        Navigator.of(context).pop(true);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text('Erreur lors de la modification: $e'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 5),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onTap != null ? const Icon(Icons.calendar_today) : null,
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label est requis';
          }
          return null;
        } : null,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onTap: onTap,
        readOnly: readOnly || onTap != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.edit, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Modifier le véhicule ${widget.vehicule['plaque'] ?? 'N/A'}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Informations de base
                      Text('Informations de base', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                      const SizedBox(width: double.infinity, height: 8),
                      
                      _buildTextField(label: 'Marque', controller: _marqueController, required: true),
                      _buildTextField(label: 'Modèle', controller: _modeleController),
                      _buildTextField(label: 'Année', controller: _anneeController, keyboardType: TextInputType.number),
                      _buildTextField(label: 'Couleur', controller: _couleurController),
                      _buildTextField(label: 'Numéro chassis', controller: _numeroChassisController),
                      _buildTextField(label: 'Genre', controller: _genreController),
                      _buildTextField(label: 'Usage', controller: _usageController),
                      _buildTextField(label: 'Numéro moteur', controller: _numMoteurController),
                      _buildTextField(label: 'Origine', controller: _origineController),
                      _buildTextField(label: 'Source', controller: _sourceController),
                      _buildTextField(label: 'Année fabrication', controller: _anneeFabController, keyboardType: TextInputType.number),
                      _buildTextField(label: 'Année circulation', controller: _anneeCircController, keyboardType: TextInputType.number),
                      _buildTextField(label: 'Type EM', controller: _typeEmController),

                      const SizedBox(width: double.infinity, height: 16),
                      
                      // Informations d'importation
                      Text('Informations d\'importation', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                      const SizedBox(width: double.infinity, height: 8),
                      
                      _buildTextField(label: 'Frontière d\'entrée', controller: _frontiereEntreeController),
                      _buildTextField(
                        label: 'Date d\'importation', 
                        controller: _dateImportationController,
                        onTap: () => _selectDate(_dateImportationController),
                      ),
                      _buildTextField(label: 'Numéro déclaration', controller: _numeroDeclarationController),

                      const SizedBox(width: double.infinity, height: 16),
                      
                      // Informations plaque
                      Text('Informations plaque', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                      const SizedBox(width: double.infinity, height: 8),
                      
                      _buildTextField(label: 'Plaque', controller: _plaqueController),
                      _buildTextField(
                        label: 'Plaque valide le', 
                        controller: _plaqueValideLe,
                        onTap: () => _selectDateTime(_plaqueValideLe),
                      ),
                      _buildTextField(
                        label: 'Plaque expire le', 
                        controller: _plaqueExpireLe,
                        onTap: () => _selectDateTime(_plaqueExpireLe),
                      ),
                      
                      SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _enCirculation,
                              onChanged: (value) {
                                setState(() {
                                  _enCirculation = value ?? true;
                                });
                              },
                            ),
                            const Text('En circulation'),
                          ],
                        ),
                      ),

                      const SizedBox(width: double.infinity, height: 16),
                      
                      // Informations assurance
                      Text('Informations assurance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                      const SizedBox(width: double.infinity, height: 8),
                      
                      _buildTextField(label: 'Société assurance', controller: _societeAssuranceController),
                      _buildTextField(label: 'Numéro assurance', controller: _numeAssuranceController),
                      _buildTextField(
                        label: 'Date valide assurance', 
                        controller: _dateValideAssuranceController,
                        onTap: () => _selectDateTime(_dateValideAssuranceController),
                      ),
                      _buildTextField(
                        label: 'Date expire assurance', 
                        controller: _dateExpireAssuranceController,
                        onTap: () => _selectDateTime(_dateExpireAssuranceController),
                      ),

                      const SizedBox(width: double.infinity, height: 16),
                      
                      // Images
                      Text('Images du véhicule', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                      const SizedBox(width: double.infinity, height: 8),
                      
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: Text('Sélectionner des images (${_selectedFiles.length})'),
                            ),
                            if (_selectedFiles.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedFiles.map((file) => Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? (file.bytes != null
                                            ? Image.memory(
                                                file.bytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.error))
                                        : (file.path != null
                                            ? Image.file(File(file.path!), fit: BoxFit.cover)
                                            : const Icon(Icons.error)),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateVehicule,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
