import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import '../models/accident_models.dart';
import '../services/accident_api_service.dart';
import '../providers/auth_provider.dart';

class PartieImpliqueeModal extends StatefulWidget {
  final AccidentApiService apiService;

  const PartieImpliqueeModal({super.key, required this.apiService});

  @override
  State<PartieImpliqueeModal> createState() => _PartieImpliqueeModalState();
}

class _PartieImpliqueeModalState extends State<PartieImpliqueeModal> {
  final _formKey = GlobalKey<FormState>();
  final _plaqueController = TextEditingController();
  final _conducteurNomController = TextEditingController();
  final _dommagesController = TextEditingController();
  final _notesController = TextEditingController();

  RolePartie _role = RolePartie.autre;
  EtatPersonne _conducteurEtat = EtatPersonne.indemne;
  List<Passager> _passagers = [];
  List<XFile> _photos = [];
  
  int? _selectedVehiculeId;
  String? _marque;
  String? _modele;
  bool _isSearching = false;

  @override
  void dispose() {
    _plaqueController.dispose();
    _conducteurNomController.dispose();
    _dommagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    final plaque = _plaqueController.text.trim();
    if (plaque.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await widget.apiService.searchVehicle(plaque);
      if (results.isNotEmpty) {
        final vehicule = results.first;
        setState(() {
          _selectedVehiculeId = vehicule.vehiculePlaqueId;
          _marque = vehicule.marque;
          _modele = vehicule.modele;
        });
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Véhicule trouvé et sélectionné'),
          description: Text('${vehicule.marque ?? ''} ${vehicule.modele ?? ''}'.trim()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      } else {
        _showCreateVehicleDialog();
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur de recherche'),
        description: Text(e.toString()),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showCreateVehicleDialog() {
    final marqueCtrl = TextEditingController();
    final modeleCtrl = TextEditingController();
    final couleurCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.add_road, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Création rapide de véhicule', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plaque: ${_plaqueController.text.trim()}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: marqueCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Marque *',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modeleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Modèle *',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: couleurCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Couleur',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                hintText: 'Optionnel',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '* Champs obligatoires pour création rapide',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validation des champs obligatoires
              if (marqueCtrl.text.trim().isEmpty || modeleCtrl.text.trim().isEmpty) {
                toastification.show(
                  context: context,
                  type: ToastificationType.warning,
                  style: ToastificationStyle.fillColored,
                  title: const Text('Champs requis'),
                  description: const Text('La marque et le modèle sont obligatoires'),
                );
                return;
              }

              try {
                final username = context.read<AuthProvider>().username;
                final vehiculeId = await widget.apiService.quickCreateVehicle(
                  plaque: _plaqueController.text.trim(),
                  marque: marqueCtrl.text.trim(),
                  modele: modeleCtrl.text.trim(),
                  couleur: couleurCtrl.text.trim().isNotEmpty ? couleurCtrl.text.trim() : null,
                  username: username,
                );
                setState(() {
                  _selectedVehiculeId = vehiculeId;
                  _marque = marqueCtrl.text.trim();
                  _modele = modeleCtrl.text.trim();
                });
                Navigator.pop(context);
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  style: ToastificationStyle.fillColored,
                  title: const Text('Véhicule créé avec succès'),
                  description: Text('${marqueCtrl.text.trim()} ${modeleCtrl.text.trim()}'),
                  autoCloseDuration: const Duration(seconds: 3),
                );
              } catch (e) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.fillColored,
                  title: const Text('Erreur de création'),
                  description: Text(e.toString()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer le véhicule'),
          ),
        ],
      ),
    );
  }

  void _addPassager() {
    final nomCtrl = TextEditingController();
    EtatPersonne etat = EtatPersonne.indemne;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Ajouter un passager', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom du passager *',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EtatPersonne>(
                value: etat,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                decoration: const InputDecoration(
                  labelText: 'État',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: EtatPersonne.values.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.label, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (v) => setDialogState(() => etat = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _passagers.add(Passager(nom: nomCtrl.text.trim(), etat: etat));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _photos.addAll(images));
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text('${images.length} photo(s) ajoutée(s)'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('Erreur'),
        description: Text(e.toString()),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVehiculeId == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        title: const Text('Veuillez rechercher ou créer un véhicule'),
      );
      return;
    }

    final partie = PartieImpliquee(
      vehiculePlaqueId: _selectedVehiculeId,
      plaque: _plaqueController.text.trim(),
      marque: _marque,
      modele: _modele,
      role: _role,
      conducteurNom: _conducteurNomController.text.trim(),
      conducteurEtat: _conducteurEtat,
      passagers: _passagers,
      dommagesVehicule: _dommagesController.text.trim(),
      photosLocales: _photos.map((p) => p.path).toList(),
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, {'partie': partie, 'photos': _photos});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.directions_car, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ajouter une partie impliquée',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Recherche véhicule
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _plaqueController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Plaque d\'immatriculation *',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : null,
                            ),
                            validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSearching ? null : _searchVehicle,
                          icon: const Icon(Icons.search),
                          label: const Text('Rechercher'),
                        ),
                      ],
                    ),
                    if (_selectedVehiculeId != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.green[900],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Véhicule: $_marque $_modele',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Rôle
                    DropdownButtonFormField<RolePartie>(
                      value: _role,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: theme.scaffoldBackgroundColor,
                      decoration: const InputDecoration(
                        labelText: 'Rôle *',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: RolePartie.values.map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.label),
                      )).toList(),
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                    const SizedBox(height: 24),

                    // Conducteur
                    const Text(
                      'Informations du conducteur',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _conducteurNomController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nom du conducteur',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EtatPersonne>(
                      value: _conducteurEtat,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: theme.scaffoldBackgroundColor,
                      decoration: const InputDecoration(
                        labelText: 'État du conducteur',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: EtatPersonne.values.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.label),
                      )).toList(),
                      onChanged: (v) => setState(() => _conducteurEtat = v!),
                    ),
                    const SizedBox(height: 24),

                    // Passagers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Passagers',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addPassager,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    if (_passagers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._passagers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final passager = entry.value;
                        return Card(
                          color: theme.colorScheme.surfaceContainer,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(passager.nom, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(passager.etat.label, style: const TextStyle(color: Colors.white70)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _passagers.removeAt(index)),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),

                    // Photos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos de la partie',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickPhotos,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FutureBuilder<Uint8List>(
                                      future: _photos[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Center(child: CircularProgressIndicator()),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () => setState(() => _photos.removeAt(index)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Dommages
                    TextFormField(
                      controller: _dommagesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Dommages du véhicule',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Ajouter cette partie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
