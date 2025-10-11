import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class SosAvisVehiculeModal extends StatefulWidget {
  const SosAvisVehiculeModal({super.key});

  @override
  State<SosAvisVehiculeModal> createState() => _SosAvisVehiculeModalState();
}

class _SosAvisVehiculeModalState extends State<SosAvisVehiculeModal> {
  final _formKey = GlobalKey<FormState>();
  final _plaqueController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();
  final _motifController = TextEditingController();
  
  String _niveau = 'élevé'; // Par défaut élevé pour SOS
  bool _isLoading = false;

  @override
  void dispose() {
    _plaqueController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS - Avis de recherche Véhicule',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Émission d\'un avis de recherche d\'urgence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: theme.colorScheme.onPrimaryContainer,
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
                      _buildVehiculeSection(theme),
                      const SizedBox(height: 24),
                      _buildMotifSection(theme),
                      const SizedBox(height: 24),
                      _buildNiveauSection(theme),
                      const SizedBox(height: 32),
                      _buildActionButtons(theme),
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

  Widget _buildVehiculeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du véhicule recherché',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _plaqueController,
          decoration: const InputDecoration(
            labelText: 'Plaque d\'immatriculation *',
            border: OutlineInputBorder(),
            hintText: 'Ex: ABC-123-DE',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La plaque d\'immatriculation est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(
                  labelText: 'Marque *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Toyota',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marque est requise';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(
                  labelText: 'Modèle *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Camry',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le modèle est requis';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _couleurController,
                decoration: const InputDecoration(
                  labelText: 'Couleur *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Blanc',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La couleur est requise';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _anneeController,
                decoration: const InputDecoration(
                  labelText: 'Année',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 2020',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotifSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motif de la recherche *',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motifController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Décrivez le motif de l\'avis de recherche (ex: Vol de véhicule, Délit de fuite, Véhicule utilisé dans un crime, etc.)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le motif est requis';
            }
            if (value.trim().length < 10) {
              return 'Le motif doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNiveauSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveau de priorité',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            _buildNiveauChip('moyen', 'Moyen', Colors.orange, theme),
            _buildNiveauChip('élevé', 'Élevé (SOS)', Colors.red, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildNiveauChip(String value, String label, Color color, ThemeData theme) {
    final isSelected = _niveau == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _niveau = value;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
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
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Émettre l\'avis SOS'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Créer d'abord le véhicule
      final vehiculeResponse = await http.post(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/vehicules/create'},
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plaque': _plaqueController.text.trim(),
          'marque': _marqueController.text.trim(),
          'modele': _modeleController.text.trim(),
          'couleur': _couleurController.text.trim(),
          'annee': _anneeController.text.trim().isNotEmpty ? int.tryParse(_anneeController.text.trim()) : null,
          'username': authProvider.username,
        }),
      );

      if (vehiculeResponse.statusCode == 200) {
        final vehiculeData = jsonDecode(vehiculeResponse.body);
        if (vehiculeData['success'] == true) {
          final vehiculeId = vehiculeData['id'];
          
          // Ensuite créer l'avis de recherche
          final avisResponse = await http.post(
            Uri.parse(ApiConfig.baseUrl).replace(
              queryParameters: {'route': '/avis-recherche/create'},
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cible_type': 'vehicule_plaque',
              'cible_id': vehiculeId,
              'motif': _motifController.text.trim(),
              'niveau': _niveau,
              'created_by': authProvider.username,
              'username': authProvider.username,
            }),
          );

          if (avisResponse.statusCode == 200) {
            final avisData = jsonDecode(avisResponse.body);
            if (avisData['success'] == true) {
              _showSuccess('Avis de recherche SOS émis avec succès');
              Navigator.of(context).pop();
            } else {
              _showError(avisData['message'] ?? 'Erreur lors de l\'émission de l\'avis de recherche');
            }
          } else {
            _showError('Erreur serveur lors de l\'émission de l\'avis: ${avisResponse.statusCode}');
          }
        } else {
          _showError(vehiculeData['message'] ?? 'Erreur lors de la création du véhicule');
        }
      } else {
        _showError('Erreur serveur lors de la création du véhicule: ${vehiculeResponse.statusCode}');
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
}
