import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

class CreateAgentModal extends StatefulWidget {
  const CreateAgentModal({super.key});

  @override
  State<CreateAgentModal> createState() => _CreateAgentModalState();
}

class _CreateAgentModalState extends State<CreateAgentModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _posteController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Horaires pour chaque jour
  final Map<String, Map<String, dynamic>> _schedules = {
    'Lundi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Mardi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Mercredi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Jeudi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Vendredi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Samedi': {'enabled': false, 'start': '08:00', 'end': '17:00'},
    'Dimanche': {'enabled': false, 'start': '08:00', 'end': '17:00'},
  };

  @override
  void dispose() {
    _nomController.dispose();
    _matriculeController.dispose();
    _posteController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer l'objet agent avec toutes les données
      final agentData = {
        'nom': _nomController.text,
        'matricule': _matriculeController.text,
        'poste': _posteController.text,
        'role': _selectedRole,
        'telephone': _telephoneController.text,
        'password': _passwordController.text,
        'schedules': _schedules,
      };

      // Créer le service utilisateur
      final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
      final userService = UserService(apiClient);

      // Envoyer à l'API
      final result = await userService.createUser(agentData);

      if (mounted) {
        // Succès - retourner les données avec le message de l'API
        Navigator.of(context).pop({
          ...agentData,
          'success': true,
          'message': result['message'] ?? 'Agent créé avec succès',
          'id': result['id'],
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Erreur lors de la création de l\'agent';
        
        if (e is ApiException) {
          errorMessage = e.message;
        }

        NotificationService.error(context, errorMessage);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown() {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<String>(
      value: _selectedRole.isEmpty ? null : _selectedRole,
      decoration: InputDecoration(
        labelText: 'Rôle *',
        hintText: 'Sélectionner un rôle',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'controleur', child: Text('Contrôleur')),
        DropdownMenuItem(value: 'instructeur', child: Text('Instructeur')),
        DropdownMenuItem(value: 'inspecteur', child: Text('Inspecteur')),
        DropdownMenuItem(value: 'inspectrice', child: Text('Inspectrice')),
        DropdownMenuItem(value: 'police', child: Text('Police')),
        DropdownMenuItem(value: 'agent_special', child: Text('Agent spécial')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRole = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un rôle';
        }
        return null;
      },
    );
  }

  Widget _buildScheduleSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plage autorisée de connexion (optionnel)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez les jours et les heures pendant lesquels l\'agent est autorisé à se connecter.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // En-tête du tableau
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 80, child: Text('Jour', style: TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 80, child: Text('Autoriser', style: TextStyle(fontWeight: FontWeight.w600))),
                    const Expanded(child: Text('Heure début', style: TextStyle(fontWeight: FontWeight.w600))),
                    const Expanded(child: Text('Heure fin', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              // Lignes pour chaque jour
              ..._schedules.entries.map((entry) => _buildScheduleRow(entry.key, entry.value)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String day, Map<String, dynamic> schedule) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(day, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 80,
            child: Switch(
              value: schedule['enabled'],
              onChanged: (value) {
                setState(() {
                  _schedules[day]!['enabled'] = value;
                });
              },
            ),
          ),
          Expanded(
            child: schedule['enabled']
                ? _buildTimeField(day, 'start', schedule['start'])
                : Container(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: schedule['enabled']
                ? _buildTimeField(day, 'end', schedule['end'])
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(String day, String type, String time) {
    // Utiliser la valeur actuelle depuis _schedules au lieu d'initialValue
    final currentTime = _schedules[day]![type] as String;
    
    return TextFormField(
      key: ValueKey('${day}_${type}_$currentTime'), // Forcer la reconstruction du widget
      initialValue: currentTime,
      decoration: InputDecoration(
        hintText: type == 'start' ? '08:00' : '17:00',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: const Icon(Icons.access_time, size: 20),
      ),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(currentTime.split(':')[0]),
            minute: int.parse(currentTime.split(':')[1]),
          ),
        );
        if (picked != null) {
          setState(() {
            _schedules[day]![type] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      readOnly: true,
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
                Text(
                  'Créer un agent',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Contenu scrollable
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Première ligne : Nom complet et Matricule
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nomController,
                              label: 'Nom complet *',
                              hint: 'Nom complet de l\'agent',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _matriculeController,
                              label: 'Matricule *',
                              hint: 'Matricule de l\'agent',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Deuxième ligne : Poste et Rôle
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _posteController,
                              label: 'Poste *',
                              hint: 'Poste occupé',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRoleDropdown()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Troisième ligne : Téléphone
                      _buildTextField(
                        controller: _telephoneController,
                        label: 'Numéro de téléphone',
                        hint: 'Ex: +243 123 456 789',
                        required: false,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      
                      // Quatrième ligne : Mot de passe
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Mot de passe *',
                        hint: 'Mot de passe initial',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Section des horaires
                      _buildScheduleSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Boutons d'action
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createAgent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Créer l\'agent'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
