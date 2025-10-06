import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../models/accident_models.dart';
import '../services/accident_api_service.dart';
import 'temoin_modal.dart';
import 'vehicule_implique_modal.dart';

class RapportAccidentModal extends StatefulWidget {
  const RapportAccidentModal({super.key});

  @override
  State<RapportAccidentModal> createState() => _RapportAccidentModalState();
}

class _RapportAccidentModalState extends State<RapportAccidentModal> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = AccidentApiService();
  
  DateTime _dateAccident = DateTime.now();
  AccidentGravite _gravite = AccidentGravite.materiel;
  final _lieuController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<XFile> _selectedImages = [];
  List<Temoin> _temoins = [];
  List<VehiculeImplique> _vehiculesImpliques = [];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _lieuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
            textTheme: const TextTheme(
              labelLarge: TextStyle(color: Colors.white),
              bodyLarge: TextStyle(color: Colors.black),
              titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateAccident),
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

      if (pickedTime != null) {
        setState(() {
          _dateAccident = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
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
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur lors de la sélection'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _showTemoinModal() async {
    final temoin = await showDialog<Temoin>(
      context: context,
      builder: (context) => const TemoinModal(),
    );
    if (temoin != null) {
      setState(() => _temoins.add(temoin));
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: const Text('Témoin ajouté'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  void _removeTemoin(int index) {
    setState(() => _temoins.removeAt(index));
  }

  Future<void> _showVehiculeModal() async {
    final vehicule = await showDialog<VehiculeImplique>(
      context: context,
      builder: (context) => VehiculeImpliqueModal(apiService: _apiService),
    );
    if (vehicule != null) {
      setState(() => _vehiculesImpliques.add(vehicule));
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: const Text('Véhicule ajouté'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  void _removeVehicule(int index) {
    setState(() => _vehiculesImpliques.removeAt(index));
  }

  Future<void> _submitAccident() async {
    if (!_formKey.currentState!.validate()) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Veuillez remplir tous les champs obligatoires'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final accident = Accident(
        dateAccident: _dateAccident,
        lieu: _lieuController.text.trim(),
        gravite: _gravite,
        description: _descriptionController.text.trim(),
        temoins: _temoins,
        vehiculesImpliques: _vehiculesImpliques,
      );

      final images = _selectedImages.map((xfile) => File(xfile.path)).toList();

      final result = await _apiService.createAccident(
        accident: accident,
        images: images,
      );

      if (result['state'] == true || result['success'] == true) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Rapport créé avec succès'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Créer un rapport d\'accident',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Informations de base
                    _buildSectionTitle('Informations de base', Icons.info_outline),
                    const SizedBox(height: 12),
                    
                    // Date et heure
                    InkWell(
                      onTap: () => _selectDateTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date et heure *',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_dateAccident),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Gravité
                    DropdownButtonFormField<AccidentGravite>(
                      value: _gravite,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: theme.scaffoldBackgroundColor,
                      decoration: const InputDecoration(
                        labelText: 'Gravité *',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      items: AccidentGravite.values.map((gravite) =>
                        DropdownMenuItem(
                          value: gravite,
                          child: Text(gravite.label, style: const TextStyle(color: Colors.white)),
                        ),
                      ).toList(),
                      onChanged: (v) => setState(() => _gravite = v!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lieu
                    TextFormField(
                      controller: _lieuController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Lieu *',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (v) {
                        if (v?.trim().isEmpty == true) return 'Lieu requis';
                        if (v!.trim().length < 5) return 'Minimum 5 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (v) {
                        if (v?.trim().isEmpty == true) return 'Description requise';
                        if (v!.trim().length < 10) return 'Minimum 10 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Images
                    _buildSectionTitle('Photos de la scène', Icons.photo_camera),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Ajouter des photos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${_selectedImages.length} photo(s) sélectionnée(s)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
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
                    const SizedBox(height: 24),
                    
                    // Témoins
                    _buildSectionTitle('Témoins', Icons.people_outline),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showTemoinModal,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un témoin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_temoins.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._temoins.asMap().entries.map((entry) {
                        final index = entry.key;
                        final temoin = entry.value;
                        return Card(
                          color: theme.colorScheme.surfaceContainer,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(temoin.nom, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${temoin.telephone} • ${temoin.age} ans • ${temoin.lienAvecAccident.label}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeTemoin(index),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    
                    // Véhicules impliqués
                    _buildSectionTitle('Véhicules impliqués', Icons.directions_car_outlined),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showVehiculeModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un véhicule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_vehiculesImpliques.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._vehiculesImpliques.asMap().entries.map((entry) {
                        final index = entry.key;
                        final vehicule = entry.value;
                        return Card(
                          color: theme.colorScheme.surfaceContainer,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, color: Colors.white),
                            title: Text(
                              vehicule.plaque ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${vehicule.marque ?? ''} ${vehicule.modele ?? ''}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Rôle: ${vehicule.role?.label ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                if (vehicule.dommages != null && vehicule.dommages!.isNotEmpty)
                                  Text(
                                    'Dommages: ${vehicule.dommages}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeVehicule(index),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAccident,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Enregistrement...' : 'Enregistrer le rapport'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
