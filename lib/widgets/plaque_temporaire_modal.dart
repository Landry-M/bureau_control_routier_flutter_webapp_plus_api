import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../utils/date_time_picker_theme.dart';

class PlaqueTemporaireModal extends StatefulWidget {
  final Map<String, dynamic> vehicule;

  const PlaqueTemporaireModal({
    super.key,
    required this.vehicule,
  });

  @override
  State<PlaqueTemporaireModal> createState() => _PlaqueTemporaireModalState();
}

class _PlaqueTemporaireModalState extends State<PlaqueTemporaireModal> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Dates par défaut : aujourd'hui à dans 30 jours
    _dateDebut = DateTime.now();
    _dateFin = DateTime.now().add(const Duration(days: 30));
    _motifController.text = 'Plaque temporaire en attente de plaque définitive';
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _dateDebut ?? DateTime.now()
          : _dateFin ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: buildThemedPicker,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Si la date de fin est antérieure à la nouvelle date de début, l'ajuster
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = picked.add(const Duration(days: 30));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _genererPlaqueTemporaire() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      _showError('Veuillez sélectionner les dates de validité');
      return;
    }
    if (_dateFin!.isBefore(_dateDebut!)) {
      _showError('La date de fin doit être postérieure à la date de début');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/plaque-temporaire/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cible_type': 'vehicule_plaque',
          'cible_id': widget.vehicule['id'],
          'motif': _motifController.text.trim(),
          'date_debut': _dateDebut!.toIso8601String().split('T')[0],
          'date_fin': _dateFin!.toIso8601String().split('T')[0],
          'statut': 'actif',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop(true);

          // Ouvrir la page de prévisualisation
          final plaqueId = data['id'];
          final previewUrl =
              "http://localhost:8000/api/plaque_temporaire_display.php?id=$plaqueId";

          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Plaque temporaire générée'),
            description: Text(
                'Numéro: ${data['numero']}\nOuverture de la prévisualisation...'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: true,
          );

          // Ouvrir automatiquement la prévisualisation dans une nouvelle fenêtre
          _openPreviewUrl(previewUrl);
        }
      } else {
        _showError(data['message'] ??
            'Erreur lors de la génération de la plaque temporaire');
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

  void _showError(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Erreur'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
    );
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
        _showUrlDialog(
            url, 'Impossible d\'ouvrir automatiquement la prévisualisation.');
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
        title: Row(
          children: [
            const Expanded(
              child: Text('Prévisualisation de la plaque'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Fermer',
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Générer une plaque temporaire',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.vehicule['marque']} ${widget.vehicule['modele']} - ${widget.vehicule['plaque']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du véhicule
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Véhicule concerné',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      'Plaque: ${widget.vehicule['plaque']}'),
                                ),
                                Expanded(
                                  child: Text(
                                      'Marque: ${widget.vehicule['marque']}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      'Modèle: ${widget.vehicule['modele']}'),
                                ),
                                Expanded(
                                  child: Text(
                                      'Couleur: ${widget.vehicule['couleur']}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dates de validité
                      Text(
                        'Période de validité',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de début *',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: theme.colorScheme.outline),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_formatDate(_dateDebut)),
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
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: theme.colorScheme.outline),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_formatDate(_dateFin)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Motif
                      Text(
                        'Motif',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _motifController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Motif de la plaque temporaire',
                          hintText:
                              'Expliquez pourquoi une plaque temporaire est nécessaire...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le motif est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Informations
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Un numéro de plaque temporaire sera généré automatiquement au format PT-XXXXXX. Après génération, vous pourrez télécharger et enregistrer le document PDF.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _genererPlaqueTemporaire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Générer la plaque temporaire'),
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
