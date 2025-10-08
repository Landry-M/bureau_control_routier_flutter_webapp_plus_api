import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/vehicule_service.dart';

class AssocierVehiculeModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onSuccess;

  const AssocierVehiculeModal({
    super.key,
    required this.particulier,
    this.onSuccess,
  });

  @override
  State<AssocierVehiculeModal> createState() => _AssocierVehiculeModalState();
}

class _AssocierVehiculeModalState extends State<AssocierVehiculeModal> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _vehiculeService = VehiculeService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _vehicules = [];
  Map<String, dynamic>? _selectedVehicule;
  String _searchType = 'plaque'; // 'plaque' ou 'general'

  @override
  void dispose() {
    _searchController.dispose();
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: 400,
        ),
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
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Associer un véhicule',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'À: ${widget.particulier['nom']} ${widget.particulier['prenom'] ?? ''}'.trim(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section de recherche
                      _buildSearchSection(theme, colorScheme),
                      const SizedBox(height: 16),
                      
                      // Résultats de recherche
                      if (_vehicules.isNotEmpty) ...[
                        Text(
                          'Véhicules trouvés (${_vehicules.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildVehiculesList(theme, colorScheme)),
                      ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun véhicule trouvé',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Recherchez un véhicule à associer',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Boutons d'action
                      _buildActionButtons(theme, colorScheme),
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

  Widget _buildSearchSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rechercher un véhicule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Type de recherche
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Par plaque'),
                value: 'plaque',
                groupValue: _searchType,
                onChanged: (value) => setState(() => _searchType = value!),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Recherche générale'),
                value: 'general',
                groupValue: _searchType,
                onChanged: (value) => setState(() => _searchType = value!),
                dense: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Champ de recherche
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: _searchType == 'plaque' 
                    ? 'Numéro de plaque' 
                    : 'Recherche (plaque, marque, modèle...)',
                  hintText: _searchType == 'plaque' 
                    ? 'Ex: AB-123-CD' 
                    : 'Ex: Toyota, Corolla, rouge...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                ),
                onFieldSubmitted: (_) => _searchVehicules(),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Veuillez saisir un terme de recherche';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchVehicules,
              icon: const Icon(Icons.search),
              label: const Text('Rechercher'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehiculesList(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _vehicules.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final vehicule = _vehicules[index];
          final isSelected = _selectedVehicule?['id'] == vehicule['id'];
          
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                  ? colorScheme.primary.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car,
                color: isSelected ? colorScheme.primary : Colors.orange,
              ),
            ),
            title: Text(
              '${vehicule['plaque'] ?? vehicule['plate'] ?? 'N/A'} - ${vehicule['marque'] ?? 'N/A'} ${vehicule['modele'] ?? 'N/A'}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicule['couleur'] != null)
                  Text('Couleur: ${vehicule['couleur']}'),
                if (vehicule['annee'] != null)
                  Text('Année: ${vehicule['annee']}'),
                if (vehicule['proprietaire'] != null)
                  Text('Propriétaire: ${vehicule['proprietaire']}'),
              ],
            ),
            trailing: isSelected
              ? Icon(Icons.check_circle, color: colorScheme.primary)
              : Icon(Icons.radio_button_unchecked, color: colorScheme.onSurfaceVariant),
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedVehicule = isSelected ? null : vehicule;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _selectedVehicule != null && !_isLoading
            ? _associerVehicule
            : null,
          child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Associer'),
        ),
      ],
    );
  }

  Future<void> _searchVehicules() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSearching = true;
      _vehicules.clear();
      _selectedVehicule = null;
    });

    try {
      List<Map<String, dynamic>> results;
      
      if (_searchType == 'plaque') {
        results = await _vehiculeService.searchByPlaque(_searchController.text.trim());
      } else {
        results = await _vehiculeService.searchLocal(_searchController.text.trim());
      }

      setState(() {
        _vehicules = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _showError('Erreur lors de la recherche: $e');
    }
  }

  Future<void> _associerVehicule() async {
    if (_selectedVehicule == null) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/particulier-vehicule/associate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'particulier_id': widget.particulier['id'],
          'vehicule_plaque_id': _selectedVehicule!['id'],
          'username': authProvider.username,
          'date_assoc': DateTime.now().toIso8601String(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      } else {
        _showError(data['message'] ?? 'Erreur lors de l\'association');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
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
    );
  }
}
