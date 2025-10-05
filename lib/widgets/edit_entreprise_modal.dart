import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../providers/entreprise_provider.dart';

class EditEntrepriseModal extends StatefulWidget {
  final Map<String, dynamic> entreprise;

  const EditEntrepriseModal({
    super.key,
    required this.entreprise,
  });

  @override
  State<EditEntrepriseModal> createState() => _EditEntrepriseModalState();
}

class _EditEntrepriseModalState extends State<EditEntrepriseModal> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs
  late final TextEditingController _designationCtrl;
  late final TextEditingController _rccmCtrl;
  late final TextEditingController _siegeSocialCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _secteurCtrl;
  late final TextEditingController _personneContactCtrl;
  late final TextEditingController _fonctionContactCtrl;
  late final TextEditingController _telContactCtrl;
  late final TextEditingController _observationsCtrl;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs avec les valeurs existantes
    _designationCtrl = TextEditingController(text: widget.entreprise['designation']?.toString() ?? '');
    _rccmCtrl = TextEditingController(text: widget.entreprise['rccm']?.toString() ?? '');
    _siegeSocialCtrl = TextEditingController(text: widget.entreprise['siege_social']?.toString() ?? '');
    _telephoneCtrl = TextEditingController(text: widget.entreprise['gsm']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: widget.entreprise['email']?.toString() ?? '');
    _secteurCtrl = TextEditingController(text: widget.entreprise['secteur']?.toString() ?? '');
    _personneContactCtrl = TextEditingController(text: widget.entreprise['personne_contact']?.toString() ?? '');
    _fonctionContactCtrl = TextEditingController(text: widget.entreprise['fonction_contact']?.toString() ?? '');
    _telContactCtrl = TextEditingController(text: widget.entreprise['telephone_contact']?.toString() ?? '');
    _observationsCtrl = TextEditingController(text: widget.entreprise['observations']?.toString() ?? '');
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _rccmCtrl.dispose();
    _siegeSocialCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    _secteurCtrl.dispose();
    _personneContactCtrl.dispose();
    _fonctionContactCtrl.dispose();
    _telContactCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    
    try {
      final api = ApiClient(baseUrl: ApiConfig.baseUrl);
      final data = {
        'designation': _designationCtrl.text.trim(),
        'rccm': _rccmCtrl.text.trim(),
        'siege_social': _siegeSocialCtrl.text.trim(),
        'gsm': _telephoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'secteur': _secteurCtrl.text.trim(),
        'personne_contact': _personneContactCtrl.text.trim(),
        'fonction_contact': _fonctionContactCtrl.text.trim(),
        'telephone_contact': _telContactCtrl.text.trim(),
        'observations': _observationsCtrl.text.trim(),
      };

      final response = await api.postJson('/entreprise/${widget.entreprise['id']}/update', data);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        NotificationService.success(context, 'Entreprise modifiée avec succès');
        
        // Rafraîchir la liste des entreprises
        if (mounted) {
          context.read<EntrepriseProvider>().refresh();
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Erreur lors de la modification (${response.statusCode})');
      }
    } catch (e) {
      NotificationService.error(context, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modifier l\'entreprise'),
                Text(
                  widget.entreprise['designation']?.toString() ?? 'N/A',
                  style: tt.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations principales', style: tt.titleMedium),
                const SizedBox(height: 16),
                
                // Désignation
                TextFormField(
                  controller: _designationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Désignation *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                
                // RCCM et Siège social
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rccmCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RCCM',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _siegeSocialCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Siège social *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Téléphone et Email
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telephoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Secteur d'activité
                TextFormField(
                  controller: _secteurCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Secteur d\'activité',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text('Personne de contact', style: tt.titleMedium),
                const SizedBox(height: 16),
                
                // Personne de contact et fonction
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _personneContactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la personne',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fonctionContactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fonction',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Téléphone contact
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telContactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone contact',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const Expanded(child: SizedBox()), // Espace vide pour équilibrer
                  ],
                ),
                const SizedBox(height: 12),
                
                // Observations
                TextFormField(
                  controller: _observationsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observations',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
