import 'package:flutter/material.dart';
import '../models/accident_models.dart';
import '../services/accident_api_service.dart';
import 'package:toastification/toastification.dart';

class VehiculeImpliqueModal extends StatefulWidget {
  final AccidentApiService apiService;

  const VehiculeImpliqueModal({
    super.key,
    required this.apiService,
  });

  @override
  State<VehiculeImpliqueModal> createState() => _VehiculeImpliqueModalState();
}

class _VehiculeImpliqueModalState extends State<VehiculeImpliqueModal> {
  bool _isCreationMode = false;
  VehiculeImplique? _selectedVehicule;
  List<VehiculeImplique> _searchResults = [];
  bool _isSearching = false;
  bool _isCreating = false;
  
  final _searchController = TextEditingController();
  RoleVehicule _role = RoleVehicule.indetermine;
  final _dommagesController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Pour mode création
  final _plaqueController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _dommagesController.dispose();
    _notesController.dispose();
    _plaqueController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    if (_searchController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Saisir une plaque'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await widget.apiService.searchVehicle(
        _searchController.text.trim(),
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      if (results.isEmpty) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          title: const Text('Aucun véhicule trouvé'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur de recherche'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _createAndAdd() async {
    if (_plaqueController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Plaque obligatoire'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final id = await widget.apiService.quickCreateVehicle(
        plaque: _plaqueController.text.trim(),
        marque: _marqueController.text.trim(),
        modele: _modeleController.text.trim(),
        couleur: _couleurController.text.trim(),
        annee: _anneeController.text.trim(),
      );

      Navigator.pop(
        context,
        VehiculeImplique(
          vehiculePlaqueId: id,
          plaque: _plaqueController.text.trim(),
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          couleur: _couleurController.text.trim(),
          annee: _anneeController.text.trim(),
          role: _role,
          dommages: _dommagesController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      );
    } catch (e) {
      setState(() => _isCreating = false);
      // Extraire le message d'erreur propre
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur de création'),
        description: Text(errorMessage),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  void _addSelectedVehicle() {
    if (_selectedVehicule == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Sélectionnez un véhicule'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    Navigator.pop(
      context,
      VehiculeImplique(
        vehiculePlaqueId: _selectedVehicule!.vehiculePlaqueId,
        plaque: _selectedVehicule!.plaque,
        marque: _selectedVehicule!.marque,
        modele: _selectedVehicule!.modele,
        couleur: _selectedVehicule!.couleur,
        annee: _selectedVehicule!.annee,
        role: _role,
        dommages: _dommagesController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        'Ajouter véhicule impliqué',
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text(
                  'Créer un nouveau véhicule',
                  style: TextStyle(color: Colors.white),
                ),
                value: _isCreationMode,
                activeColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() {
                  _isCreationMode = v;
                  _searchResults.clear();
                  _selectedVehicule = null;
                }),
              ),
              const Divider(color: Colors.white30),
              const SizedBox(height: 16),
              
              if (!_isCreationMode) ...[
                // Mode recherche
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Rechercher par plaque',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      onPressed: _isSearching ? null : _searchVehicle,
                    ),
                  ),
                  onSubmitted: (_) => _searchVehicle(),
                ),
                const SizedBox(height: 16),
                
                if (_searchResults.isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final v = _searchResults[index];
                        final isSelected = _selectedVehicule == v;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primary.withOpacity(0.3),
                          title: Text(
                            v.plaque ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${v.marque ?? ''} ${v.modele ?? ''} • ${v.couleur ?? ''} • ${v.annee ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          leading: Icon(
                            Icons.directions_car,
                            color: isSelected ? theme.colorScheme.primary : Colors.white,
                          ),
                          onTap: () => setState(() => _selectedVehicule = v),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                DropdownButtonFormField<RoleVehicule>(
                  value: _role,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: theme.scaffoldBackgroundColor,
                  decoration: const InputDecoration(
                    labelText: 'Rôle du véhicule',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  items: RoleVehicule.values.map((role) =>
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.label, style: const TextStyle(color: Colors.white)),
                    ),
                  ).toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dommagesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Dommages',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: 2,
                ),
              ] else ...[
                // Mode création
                TextField(
                  controller: _plaqueController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Plaque *',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _marqueController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _modeleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couleurController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Couleur',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _anneeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Année',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoleVehicule>(
                  value: _role,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: theme.scaffoldBackgroundColor,
                  decoration: const InputDecoration(
                    labelText: 'Rôle du véhicule',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  items: RoleVehicule.values.map((role) =>
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.label, style: const TextStyle(color: Colors.white)),
                    ),
                  ).toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dommagesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Dommages',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: (_isCreating || _isSearching)
              ? null
              : (_isCreationMode ? _createAndAdd : _addSelectedVehicle),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isCreating || _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isCreationMode ? 'Créer & Ajouter' : 'Ajouter'),
        ),
      ],
    );
  }
}
