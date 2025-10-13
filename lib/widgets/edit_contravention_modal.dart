import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../utils/date_time_picker_theme.dart';
import 'location_picker_dialog.dart';

class EditContraventionModal extends StatefulWidget {
  final Map<String, dynamic> contravention;
  final VoidCallback? onSuccess;

  const EditContraventionModal({
    super.key,
    required this.contravention,
    this.onSuccess,
  });

  @override
  State<EditContraventionModal> createState() => _EditContraventionModalState();
}

class _EditContraventionModalState extends State<EditContraventionModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  late final TextEditingController _dateHeureCtrl;
  late final TextEditingController _lieuCtrl;
  late final TextEditingController _typeInfractionCtrl;
  late final TextEditingController _refLoiCtrl;
  late final TextEditingController _montantCtrl;
  late final TextEditingController _descriptionCtrl;
  
  DateTime? _selectedDateTime;
  bool _payee = false;
  bool _submitting = false;
  
  // Coordonnées géographiques
  double? _latitude;
  double? _longitude;
  
  // Gestion des images
  List<String> _existingImages = []; // URLs des images existantes
  final List<XFile> _newImages = []; // Nouvelles images à ajouter
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs avec les valeurs existantes
    _dateHeureCtrl = TextEditingController();
    _lieuCtrl = TextEditingController(text: widget.contravention['lieu'] ?? '');
    _typeInfractionCtrl = TextEditingController(text: widget.contravention['type_infraction'] ?? '');
    _refLoiCtrl = TextEditingController(text: widget.contravention['reference_loi'] ?? '');
    _montantCtrl = TextEditingController(text: widget.contravention['amende']?.toString() ?? '');
    _descriptionCtrl = TextEditingController(text: widget.contravention['description'] ?? '');
    
    // Initialiser la date
    final dateStr = widget.contravention['date_infraction'];
    if (dateStr != null) {
      try {
        _selectedDateTime = DateTime.parse(dateStr);
        _updateDateTimeDisplay();
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Initialiser le statut de paiement
    _payee = widget.contravention['payed'] == 'oui' || widget.contravention['payed'] == '1';
    
    // Initialiser les coordonnées
    final lat = widget.contravention['latitude'];
    final lng = widget.contravention['longitude'];
    if (lat != null && lng != null) {
      _latitude = double.tryParse(lat.toString());
      _longitude = double.tryParse(lng.toString());
    }
    
    // Initialiser les images existantes
    final photosStr = widget.contravention['photos']?.toString();
    if (photosStr != null && photosStr.isNotEmpty) {
      _existingImages = photosStr.split(',')
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _dateHeureCtrl.dispose();
    _lieuCtrl.dispose();
    _typeInfractionCtrl.dispose();
    _refLoiCtrl.dispose();
    _montantCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _updateDateTimeDisplay() {
    if (_selectedDateTime != null) {
      _dateHeureCtrl.text =
          '${_selectedDateTime!.day.toString().padLeft(2, '0')}/${_selectedDateTime!.month.toString().padLeft(2, '0')}/${_selectedDateTime!.year} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      // Construire la liste complète des images (existantes + nouvelles)
      final allImagePaths = List<String>.from(_existingImages);
      
      // Préparer les nouvelles images pour l'upload
      final List<http.MultipartFile> imageFiles = [];
      for (int i = 0; i < _newImages.length; i++) {
        final image = _newImages[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'photos',
          image.path,
          filename: 'contrav_edit_${widget.contravention['id']}_${DateTime.now().millisecondsSinceEpoch}_$i.${image.path.split('.').last}',
        );
        imageFiles.add(multipartFile);
      }

      final fields = <String, String>{
        'id': widget.contravention['id'].toString(),
        'date_infraction': _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'lieu': _lieuCtrl.text.trim(),
        'type_infraction': _typeInfractionCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'reference_loi': _refLoiCtrl.text.trim(),
        'amende': _montantCtrl.text.trim(),
        'payed': _payee ? '1' : '0',
        'latitude': _latitude?.toString() ?? '',
        'longitude': _longitude?.toString() ?? '',
        'existing_photos': allImagePaths.join(','), // Images existantes à conserver
      };

      final resp = await api.postMultipart('/contravention/update', fields: fields, files: imageFiles);
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      
      if (!ok) throw Exception('Erreur (${resp.statusCode})');
      
      if (mounted) {
        NotificationService.success(context, 'Contravention modifiée avec succès');
        Navigator.of(context).pop(true);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        NotificationService.error(context, errorMessage);
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
          _updateDateTimeDisplay();
        });
      }
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
        _lieuCtrl.text = result['address'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modifier Contravention #${widget.contravention['id']}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avertissement superadmin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Action réservée aux super-administrateurs. Cette modification sera enregistrée dans les logs.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Date et heure
                TextFormField(
                  controller: _dateHeureCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date et heure *',
                    hintText: 'Sélectionner date/heure',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _submitting ? null : _selectDateTime,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),

                // Lieu avec sélection sur carte
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lieuCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lieu de l\'infraction *',
                          hintText: 'Sélectionnez sur la carte ou saisissez manuellement',
                          border: const OutlineInputBorder(),
                          suffixIcon: _latitude != null && _longitude != null
                              ? Icon(Icons.location_on, color: Colors.green[600])
                              : null,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        enabled: !_submitting,
                        maxLines: 2,
                        minLines: 1,
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
                  controller: _typeInfractionCtrl,
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
                        controller: _refLoiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Référence loi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _montantCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Montant amende (FC) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Section des images
                _buildImageSection(),
                const SizedBox(height: 12),

                // Statut de paiement
                CheckboxListTile(
                  title: const Text('Contravention payée'),
                  subtitle: Text(
                    _payee ? 'Marquée comme payée' : 'Non payée',
                    style: TextStyle(
                      color: _payee ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _payee,
                  onChanged: _submitting ? null : (value) {
                    setState(() => _payee = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Modifier'),
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
            const Icon(Icons.photo_library, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Photos de la contravention',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _submitting ? null : _pickNewImages,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Images existantes
        if (_existingImages.isNotEmpty) ...[
          const Text(
            'Images existantes:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _existingImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imagePath = entry.value;
              return _buildExistingImageThumbnail(imagePath, index);
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // Nouvelles images
        if (_newImages.isNotEmpty) ...[
          const Text(
            'Nouvelles images à ajouter:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.green),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _newImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _buildNewImageThumbnail(image, index);
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // Message informatif
        if (_existingImages.isEmpty && _newImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Aucune photo',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Appuyez sur "Ajouter" pour sélectionner des photos',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageThumbnail(String imagePath, int index) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${ApiConfig.imageBaseUrl}$imagePath',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageThumbnail(XFile image, int index) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade300),
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
            onTap: () => _removeNewImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Badge "nouveau"
        Positioned(
          bottom: 2,
          left: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickNewImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        NotificationService.error(context, 'Erreur lors de la sélection des images: $errorMessage');
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }
}
