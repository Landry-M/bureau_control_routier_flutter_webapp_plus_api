import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class EditParticulierModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onSuccess;

  const EditParticulierModal({
    super.key,
    required this.particulier,
    this.onSuccess,
  });

  @override
  State<EditParticulierModal> createState() => _EditParticulierModalState();
}

class _EditParticulierModalState extends State<EditParticulierModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs de texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _sexeController = TextEditingController();
  final _gsmController = TextEditingController();
  final _adresseController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _categoriePermisController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables pour les dates
  DateTime? _dateNaissance;
  DateTime? _permisDateEmission;
  DateTime? _permisDateExpiration;

  // Variables pour les photos
  File? _photoPersonnelle;
  File? _permisRecto;
  File? _permisVerso;
  
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Pré-remplir les champs avec les données existantes
    _nomController.text = widget.particulier['nom'] ?? '';
    _prenomController.text = widget.particulier['prenom'] ?? '';
    _sexeController.text = widget.particulier['sexe'] ?? '';
    _gsmController.text = widget.particulier['gsm'] ?? '';
    _adresseController.text = widget.particulier['adresse'] ?? '';
    _numeroPermisController.text = widget.particulier['numero_permis'] ?? '';
    _categoriePermisController.text = widget.particulier['categorie_permis'] ?? '';
    _observationsController.text = widget.particulier['observations'] ?? '';

    // Initialiser les dates
    if (widget.particulier['date_naissance'] != null) {
      try {
        _dateNaissance = DateTime.parse(widget.particulier['date_naissance']);
      } catch (e) {
        _dateNaissance = null;
      }
    }

    if (widget.particulier['permis_date_emission'] != null) {
      try {
        _permisDateEmission = DateTime.parse(widget.particulier['permis_date_emission']);
      } catch (e) {
        _permisDateEmission = null;
      }
    }

    if (widget.particulier['permis_date_expiration'] != null) {
      try {
        _permisDateExpiration = DateTime.parse(widget.particulier['permis_date_expiration']);
      } catch (e) {
        _permisDateExpiration = null;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _sexeController.dispose();
    _gsmController.dispose();
    _adresseController.dispose();
    _numeroPermisController.dispose();
    _categoriePermisController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case 'naissance':
        initialDate = _dateNaissance ?? DateTime(1980);
        firstDate = DateTime(1900);
        lastDate = DateTime.now();
        break;
      case 'emission':
        initialDate = _permisDateEmission ?? DateTime.now().subtract(const Duration(days: 365));
        firstDate = DateTime(2000);
        lastDate = DateTime.now();
        break;
      case 'expiration':
        initialDate = _permisDateExpiration ?? DateTime.now().add(const Duration(days: 365));
        firstDate = DateTime.now();
        lastDate = DateTime.now().add(const Duration(days: 365 * 20));
        break;
      default:
        return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
            textTheme: TextTheme(
              labelLarge: TextStyle(color: Colors.white), // Texte des boutons
              bodyLarge: TextStyle(color: Colors.black), // Texte du calendrier
              titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600), // Titre du mois
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'naissance':
            _dateNaissance = picked;
            break;
          case 'emission':
            _permisDateEmission = picked;
            break;
          case 'expiration':
            _permisDateExpiration = picked;
            break;
        }
      });
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'personnelle':
              _photoPersonnelle = File(image.path);
              break;
            case 'recto':
              _permisRecto = File(image.path);
              break;
            case 'verso':
              _permisVerso = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image: ${e.toString()}');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _updateParticulier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final username = authProvider.username;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/particulier/${widget.particulier['id']}/update'),
      );

      // Ajouter les champs de texte
      request.fields['nom'] = _nomController.text.trim();
      request.fields['prenom'] = _prenomController.text.trim();
      request.fields['sexe'] = _sexeController.text.trim();
      request.fields['gsm'] = _gsmController.text.trim();
      request.fields['adresse'] = _adresseController.text.trim();
      request.fields['numero_permis'] = _numeroPermisController.text.trim();
      request.fields['categorie_permis'] = _categoriePermisController.text.trim();
      request.fields['observations'] = _observationsController.text.trim();
      request.fields['username'] = username;

      // Ajouter les dates
      if (_dateNaissance != null) {
        request.fields['date_naissance'] = _dateNaissance!.toIso8601String().split('T')[0];
      }
      if (_permisDateEmission != null) {
        request.fields['permis_date_emission'] = _permisDateEmission!.toIso8601String().split('T')[0];
      }
      if (_permisDateExpiration != null) {
        request.fields['permis_date_expiration'] = _permisDateExpiration!.toIso8601String().split('T')[0];
      }

      // Ajouter les photos si elles ont été modifiées
      if (_photoPersonnelle != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _photoPersonnelle!.path,
        ));
      }

      if (_permisRecto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'permis_recto',
          _permisRecto!.path,
        ));
      }

      if (_permisVerso != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'permis_verso',
          _permisVerso!.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccess('Particulier modifié avec succès');
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        }
      } else {
        _showError(data['message'] ?? 'Erreur lors de la modification du particulier');
      }
    } catch (e) {
      _showError('Erreur de connexion: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Succès'),
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
      title: const Text('Erreur'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
    );
  }

  Widget _buildPhotoSection(String title, String type, File? currentPhoto, String? existingPhotoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: currentPhoto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    currentPhoto,
                    fit: BoxFit.cover,
                  ),
                )
              : existingPhotoUrl != null && existingPhotoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${ApiConfig.imageBaseUrl}$existingPhotoUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPhotoPlaceholder(type);
                        },
                      ),
                    )
                  : _buildPhotoPlaceholder(type),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(type),
            icon: const Icon(Icons.photo_camera, size: 18),
            label: Text(currentPhoto != null ? 'Changer la photo' : 'Ajouter une photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(String type) {
    IconData icon;
    String text;
    
    switch (type) {
      case 'personnelle':
        icon = Icons.person;
        text = 'Photo\npersonnelle';
        break;
      case 'recto':
        icon = Icons.credit_card;
        text = 'Permis\nrecto';
        break;
      case 'verso':
        icon = Icons.credit_card_off;
        text = 'Permis\nverso';
        break;
      default:
        icon = Icons.photo;
        text = 'Photo';
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modifier le particulier',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Photos
                      Text(
                        'Photos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoSection(
                              'Photo personnelle',
                              'personnelle',
                              _photoPersonnelle,
                              widget.particulier['photo'],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPhotoSection(
                              'Permis recto',
                              'recto',
                              _permisRecto,
                              widget.particulier['permis_recto'],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPhotoSection(
                              'Permis verso',
                              'verso',
                              _permisVerso,
                              widget.particulier['permis_verso'],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Informations personnelles
                      Text(
                        'Informations personnelles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _nomController,
                              decoration: const InputDecoration(
                                labelText: 'Nom *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le nom est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _prenomController,
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: DropdownButtonFormField<String>(
                              value: _sexeController.text.isNotEmpty ? _sexeController.text : null,
                              decoration: const InputDecoration(
                                labelText: 'Sexe',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                DropdownMenuItem(value: 'F', child: Text('Féminin')),
                              ],
                              onChanged: (value) {
                                _sexeController.text = value ?? '';
                              },
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: InkWell(
                              onTap: () => _selectDate(context, 'naissance'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDate(_dateNaissance),
                                        style: TextStyle(
                                          color: _dateNaissance != null ? Colors.black : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Coordonnées
                      Text(
                        'Coordonnées',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _gsmController,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le téléphone est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: TextFormField(
                              controller: _adresseController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'L\'adresse est requise';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Permis de conduire
                      Text(
                        'Permis de conduire',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _numeroPermisController,
                              decoration: const InputDecoration(
                                labelText: 'Numéro de permis',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _categoriePermisController,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: InkWell(
                              onTap: () => _selectDate(context, 'emission'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Émission: ${_formatDate(_permisDateEmission)}',
                                        style: TextStyle(
                                          color: _permisDateEmission != null ? Colors.black : Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: InkWell(
                              onTap: () => _selectDate(context, 'expiration'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Expiration: ${_formatDate(_permisDateExpiration)}',
                                        style: TextStyle(
                                          color: _permisDateExpiration != null ? Colors.black : Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Observations
                      Text(
                        'Observations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _observationsController,
                        decoration: const InputDecoration(
                          labelText: 'Observations',
                          border: OutlineInputBorder(),
                          hintText: 'Notes et observations supplémentaires...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateParticulier,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Modifier'),
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
