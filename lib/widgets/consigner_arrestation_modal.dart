import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ConsignerArrestationModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onSuccess;

  const ConsignerArrestationModal({
    super.key,
    required this.particulier,
    this.onSuccess,
  });

  @override
  State<ConsignerArrestationModal> createState() => _ConsignerArrestationModalState();
}

class _ConsignerArrestationModalState extends State<ConsignerArrestationModal> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _lieuController = TextEditingController();
  final _dateArrestationCtrl = TextEditingController();
  final _dateSortieCtrl = TextEditingController();
  
  DateTime? _selectedDateArrestation;
  DateTime? _selectedDateSortie;
  bool _isLoading = false;
  bool _estLibere = false;
  bool _isCheckingArrestations = true;
  bool _hasActiveArrestation = false;
  String? _checkError;

  @override
  void initState() {
    super.initState();
    _checkActiveArrestations();
  }

  @override
  void dispose() {
    _motifController.dispose();
    _lieuController.dispose();
    _dateArrestationCtrl.dispose();
    _dateSortieCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consigner une arrestation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pour: ${widget.particulier['nom']} ${widget.particulier['prenom'] ?? ''}'.trim(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isCheckingArrestations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Vérification des arrestations en cours...'),
          ],
        ),
      );
    }

    if (_checkError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de vérification',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _checkError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _checkError = null;
                  _isCheckingArrestations = true;
                });
                _checkActiveArrestations();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_hasActiveArrestation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Arrestation impossible',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette personne est déjà en détention.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous ne pouvez pas arrêter une personne qui n\'a pas encore été libérée de sa précédente arrestation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }

    // Formulaire normal si pas d'arrestation active
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInformationsSection(theme),
            const SizedBox(height: 24),
            _buildDatesSection(theme),
            const SizedBox(height: 24),
            _buildStatutSection(theme),
            const SizedBox(height: 32),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de l\'arrestation',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 500,
              child: TextFormField(
                controller: _motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif de l\'arrestation *',
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez le motif de l\'arrestation...',
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _lieuController,
                decoration: const InputDecoration(
                  labelText: 'Lieu de l\'arrestation',
                  border: OutlineInputBorder(),
                  hintText: 'Lieu où s\'est déroulée l\'arrestation',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates importantes',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: TextFormField(
                controller: _dateArrestationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date et heure d\'arrestation *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDateTime(true),
                validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
              ),
            ),
            if (_estLibere)
              SizedBox(
                width: 250,
                child: TextFormField(
                  controller: _dateSortieCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date et heure de sortie',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDateTime(false),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut de l\'arrestation',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            color: _estLibere 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(
                _estLibere ? Icons.check_circle : Icons.lock,
                color: _estLibere ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _estLibere ? 'Personne libérée' : 'Personne en détention',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _estLibere ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _estLibere 
                          ? 'La personne a été libérée de détention'
                          : 'La personne est actuellement en détention',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _estLibere,
                onChanged: (value) {
                  setState(() {
                    _estLibere = value;
                    if (!value) {
                      // Si on marque comme non libéré, on efface la date de sortie
                      _selectedDateSortie = null;
                      _dateSortieCtrl.clear();
                    }
                  });
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Consigner l\'arrestation'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(bool isArrestation) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
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
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                onSurface: Colors.white,
                onPrimary: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isArrestation) {
            _selectedDateArrestation = selectedDateTime;
            _dateArrestationCtrl.text =
                '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';
          } else {
            _selectedDateSortie = selectedDateTime;
            _dateSortieCtrl.text =
                '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateArrestation == null) {
      _showError('Veuillez sélectionner la date et l\'heure d\'arrestation');
      return;
    }
    if (_estLibere && _selectedDateSortie == null) {
      _showError('Veuillez sélectionner la date de sortie si la personne est libérée');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/arrestation/create'},
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'particulier_id': widget.particulier['id'],
          'motif': _motifController.text,
          'lieu': _lieuController.text,
          'date_arrestation': _selectedDateArrestation!.toIso8601String(),
          'date_sortie_prison': _estLibere ? _selectedDateSortie?.toIso8601String() : null,
          'created_by': authProvider.username,
          'username': authProvider.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccess('Arrestation consignée avec succès');
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.of(context).pop();
        } else {
          _showError(data['message'] ?? 'Erreur lors de la consignation de l\'arrestation');
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

  Future<void> _checkActiveArrestations() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {
            'route': '/arrestations/particulier/${widget.particulier['id']}',
            'username': authProvider.username,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final arrestations = List<Map<String, dynamic>>.from(data['data'] ?? []);
          
          // Vérifier s'il y a une arrestation active (pas encore libérée)
          final activeArrestation = arrestations.any((arrestation) => 
            arrestation['date_sortie_prison'] == null
          );

          setState(() {
            _isCheckingArrestations = false;
            _hasActiveArrestation = activeArrestation;
          });
        } else {
          setState(() {
            _isCheckingArrestations = false;
            _checkError = data['message'] ?? 'Erreur lors de la vérification';
          });
        }
      } else {
        setState(() {
          _isCheckingArrestations = false;
          _checkError = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingArrestations = false;
        _checkError = 'Erreur de connexion: $e';
      });
    }
  }
}
