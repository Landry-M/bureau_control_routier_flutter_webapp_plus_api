import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class GenererPermisTemporaireModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onSuccess;

  const GenererPermisTemporaireModal({
    super.key,
    required this.particulier,
    this.onSuccess,
  });

  @override
  State<GenererPermisTemporaireModal> createState() => _GenererPermisTemporaireModalState();
}

class _GenererPermisTemporaireModalState extends State<GenererPermisTemporaireModal> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 30)); // 30 jours par défaut
  bool _isLoading = false;

  @override
  void dispose() {
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
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(Icons.credit_card, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Générer un permis temporaire',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pour ${widget.particulier['nom']} ${widget.particulier['prenom'] ?? ''}'.trim(),
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildParticulierInfoSection(theme),
                      const SizedBox(height: 24),
                      _buildMotifSection(theme),
                      const SizedBox(height: 24),
                      _buildDatesSection(theme),
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

  Widget _buildParticulierInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du particulier',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Particulier',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.particulier['nom']} ${widget.particulier['prenom'] ?? ''}'.trim(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.particulier['numero_national'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'N° National: ${widget.particulier['numero_national']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              if (widget.particulier['telephone'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Téléphone: ${widget.particulier['telephone']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotifSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motif du permis temporaire *',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motifController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Indiquez le motif de délivrance du permis temporaire (ex: Perte du permis original, Renouvellement en cours, etc.)',
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

  Widget _buildDatesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période de validité',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de début *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDateDebut(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                            color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_dateDebut.day.toString().padLeft(2, '0')}/${_dateDebut.month.toString().padLeft(2, '0')}/${_dateDebut.year}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de fin *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDateFin(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                            color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_dateFin.day.toString().padLeft(2, '0')}/${_dateFin.month.toString().padLeft(2, '0')}/${_dateFin.year}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Durée: ${_dateFin.difference(_dateDebut).inDays + 1} jour(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
              : const Text('Générer le permis'),
        ),
      ],
    );
  }

  Future<void> _selectDateDebut(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null && picked != _dateDebut) {
      setState(() {
        _dateDebut = picked;
        // Ajuster la date de fin si elle est antérieure à la date de début
        if (_dateFin.isBefore(_dateDebut)) {
          _dateFin = _dateDebut.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectDateFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: _dateDebut,
      lastDate: _dateDebut.add(const Duration(days: 365)),
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
    if (picked != null && picked != _dateFin) {
      setState(() {
        _dateFin = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des dates
    if (_dateFin.isBefore(_dateDebut)) {
      _showError('La date de fin doit être postérieure à la date de début');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl).replace(
          queryParameters: {'route': '/permis-temporaire/create'},
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cible_type': 'particulier',
          'cible_id': widget.particulier['id'],
          'motif': _motifController.text.trim(),
          'date_debut': '${_dateDebut.year}-${_dateDebut.month.toString().padLeft(2, '0')}-${_dateDebut.day.toString().padLeft(2, '0')}',
          'date_fin': '${_dateFin.year}-${_dateFin.month.toString().padLeft(2, '0')}-${_dateFin.day.toString().padLeft(2, '0')}',
          'created_by': authProvider.username,
          'username': authProvider.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccess('Permis temporaire généré avec succès');
          
          // Ouvrir l'URL de prévisualisation
          if (data['preview_url'] != null) {
            await _openPreviewUrl(data['preview_url']);
          }
          
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.of(context).pop();
        } else {
          _showError(data['message'] ?? 'Erreur lors de la génération du permis temporaire');
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

  Future<void> _openPreviewUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Essayer plusieurs modes de lancement
      bool launched = false;
      
      // 1. Essayer le mode externe (nouvelle fenêtre/onglet)
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // 2. Essayer le mode par défaut de la plateforme
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          // 3. Essayer avec WebView intégrée
          try {
            launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } catch (e3) {
            launched = false;
          }
        }
      }
      
      if (!launched) {
        // Si toutes les tentatives échouent, afficher l'URL
        _showUrlDialog(url, 'Impossible d\'ouvrir automatiquement la prévisualisation.');
      }
    } catch (e) {
      // En cas d'erreur générale, afficher l'URL
      _showUrlDialog(url, 'Erreur lors de l\'ouverture: ${e.toString()}');
    }
  }
  
  void _showUrlDialog(String url, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévisualisation du permis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
            const Text('Copiez cette URL dans votre navigateur:'),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Essayer encore une fois d'ouvrir l'URL
              try {
                await launchUrl(Uri.parse(url));
              } catch (e) {
                // Ignorer l'erreur, l'utilisateur a l'URL
              }
            },
            child: const Text('Essayer d\'ouvrir'),
          ),
        ],
      ),
    );
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
