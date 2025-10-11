import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../models/accident_models.dart';
import '../services/accident_api_service.dart';
import 'temoin_modal.dart';
import 'partie_impliquee_modal.dart';

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
  List<PartieImpliquee> _partiesImpliquees = [];
  List<Map<String, dynamic>> _partiesPhotos = []; // Stocke les photos pour chaque partie
  List<String> _servicesEtat = [];
  int? _partieFautiveIndex;
  final _raisonFauteController = TextEditingController();
  
  bool _isSubmitting = false;
  
  static const int maxParties = 4;

  @override
  void dispose() {
    _lieuController.dispose();
    _descriptionController.dispose();
    _raisonFauteController.dispose();
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
              onSurface: Colors.white,
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

  Future<void> _showPartieModal() async {
    if (_partiesImpliquees.length >= maxParties) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Maximum de 4 parties atteint'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PartieImpliqueeModal(apiService: _apiService),
    );
    
    if (result != null) {
      setState(() {
        _partiesImpliquees.add(result['partie'] as PartieImpliquee);
        _partiesPhotos.add({'photos': result['photos'] as List<XFile>});
      });
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: const Text('Partie ajoutée'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  void _removePartie(int index) {
    setState(() {
      _partiesImpliquees.removeAt(index);
      _partiesPhotos.removeAt(index);
      if (_partieFautiveIndex == index) {
        _partieFautiveIndex = null;
      } else if (_partieFautiveIndex != null && _partieFautiveIndex! > index) {
        _partieFautiveIndex = _partieFautiveIndex! - 1;
      }
    });
  }
  
  void _toggleServiceEtat(String service) {
    setState(() {
      if (_servicesEtat.contains(service)) {
        _servicesEtat.remove(service);
      } else {
        _servicesEtat.add(service);
      }
    });
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
        partiesImpliquees: _partiesImpliquees,
        servicesEtatPresent: _servicesEtat,
        partieFautiveId: _partieFautiveIndex != null ? _partieFautiveIndex! + 1 : null,
        raisonFaute: _raisonFauteController.text.trim(),
      );

      final result = await _apiService.createAccident(
        accident: accident,
        images: _selectedImages,
        partiesPhotos: _partiesPhotos,
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
                                    child: FutureBuilder<Uint8List>(
                                      future: _selectedImages[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
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
                    
                    // Parties impliquées
                    _buildSectionTitle('Parties impliquées (max 4)', Icons.directions_car_outlined),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _partiesImpliquees.length < maxParties ? _showPartieModal : null,
                      icon: const Icon(Icons.add),
                      label: Text('Ajouter une partie (${_partiesImpliquees.length}/$maxParties)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_partiesImpliquees.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._partiesImpliquees.asMap().entries.map((entry) {
                        final index = entry.key;
                        final partie = entry.value;
                        final photosCount = (_partiesPhotos[index]['photos'] as List).length;
                        return Card(
                          color: theme.colorScheme.surfaceContainer,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, color: Colors.white),
                            title: Text(
                              partie.plaque ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${partie.marque ?? ''} ${partie.modele ?? ''}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Rôle: ${partie.role.label} | Conducteur: ${partie.conducteurNom ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                Text(
                                  'Passagers: ${partie.passagers.length} | Photos: $photosCount',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePartie(index),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    
                    // Services de l'État présents
                    _buildSectionTitle('Services de l\'État présents', Icons.local_police),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildServiceChip('Police', Icons.local_police),
                        _buildServiceChip('Ambulance', Icons.local_hospital),
                        _buildServiceChip('Pompiers', Icons.local_fire_department),
                        _buildServiceChip('Gendarmerie', Icons.shield),
                        _buildServiceChip('Protection civile', Icons.health_and_safety),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Responsabilité
                    _buildSectionTitle('Responsabilité', Icons.gavel),
                    const SizedBox(height: 12),
                    if (_partiesImpliquees.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        value: _partieFautiveIndex,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: theme.scaffoldBackgroundColor,
                        decoration: const InputDecoration(
                          labelText: 'Partie responsable',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Indéterminé', style: TextStyle(color: Colors.white70)),
                          ),
                          ..._partiesImpliquees.asMap().entries.map((entry) {
                            final index = entry.key;
                            final partie = entry.value;
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text(
                                '${partie.plaque ?? 'N/A'} (${partie.marque ?? ''})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _partieFautiveIndex = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _raisonFauteController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Raison/Explication de la responsabilité',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Non-respect du stop, excès de vitesse...',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                        maxLines: 3,
                      ),
                    ] else ...[
                      const Text(
                        'Ajoutez au moins une partie impliquée pour définir la responsabilité',
                        style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic),
                      ),
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
  
  Widget _buildServiceChip(String service, IconData icon) {
    final isSelected = _servicesEtat.contains(service);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(width: 4),
          Text(service),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleServiceEtat(service),
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[800],
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white30,
        width: 1,
      ),
    );
  }
}
