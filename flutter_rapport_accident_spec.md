# Spécification Technique : Création de Rapport d'Accident
## Architecture Flutter/Dart

---

## 📋 Vue d'ensemble

### Fonctionnalité
Création complète d'un rapport d'accident de circulation avec :
- **Informations de base** : date, lieu, gravité, description
- **Images** : photos multiples de la scène d'accident  
- **Témoins** : liste de témoins avec leurs coordonnées
- **Véhicules impliqués** : véhicules avec rôle, dommages et notes

### Flux utilisateur
1. Agent ouvre le formulaire
2. Remplit informations de base (obligatoires)
3. Ajoute images (optionnel)
4. Ajoute témoins via modal (optionnel)
5. Ajoute véhicules via modal (optionnel)
6. Enregistre le rapport

---

## 📊 Structure des données

### Accident
```dart
class Accident {
  int? id;
  DateTime dateAccident;
  String lieu;
  String gravite;  // 'leger', 'grave', 'mortel', 'materiel'
  String description;
  List<String> imagesPaths;
  List<Temoin> temoins;
  List<VehiculeImplique> vehiculesImpliques;
  DateTime createdAt;
}
```

### Témoin
```dart
class Temoin {
  int? id;
  String nom;
  String telephone;
  int age;
  String lienAvecAccident;  // 'temoin_direct', 'passant', etc.
  String? temoignage;
}
```

### Véhicule Impliqué
```dart
class VehiculeImplique {
  int vehiculePlaqueId;
  String? plaque;
  String? marque;
  String? modele;
  String? role;  // 'responsable', 'victime', 'indetermine'
  String? dommages;
  String? notes;
}
```

---

## 🎨 Architecture UI

```
RapportAccidentScreen
├── AppBar
├── ScrollView
│   ├── InformationsBaseSection
│   │   ├── DateTimePicker
│   │   ├── GravitéDropdown
│   │   ├── LieuTextField
│   │   └── DescriptionTextField
│   ├── ImagesSection
│   │   ├── AddButton
│   │   └── ImagesGrid
│   ├── TemoinsSection
│   │   ├── AddButton
│   │   └── TemoinsList
│   └── VehiculesSection
│       ├── AddButton
│       └── VehiculesList
└── FAB (Enregistrer)
```

---

## 🔄 Workflows clés

### 1. Ajout d'images
```
1. Clic "Ajouter images"
2. ImagePicker (multi-select)
3. Prévisualisation avec suppression
4. Stockage local
5. Upload à l'enregistrement
```

### 2. Ajout de témoin
```
1. Clic "Ajouter témoin"
2. Modal avec formulaire
3. Validation inline
4. Ajout à liste locale
5. Affichage card
```

### 3. Ajout véhicule - Mode Recherche
```
1. Clic "Ajouter véhicule"
2. Modal en mode recherche
3. Saisie plaque + recherche
4. API: POST /api/accident/search-vehicle
5. Sélection véhicule
6. Ajout rôle/dommages/notes
7. Ajout à liste locale
```

### 4. Ajout véhicule - Mode Création
```
1. Activation switch "Créer"
2. Formulaire création
3. API: POST /vehicule/quick-create
4. Ajout à liste locale
```

### 5. Enregistrement
```
1. Validation formulaire
2. FormData avec:
   - Champs de base
   - JSON temoins
   - JSON vehicules
   - Images multipart
3. POST /create-accident
4. Affichage succès
5. Navigation
```

---

## 🌐 API Endpoints

### 1. Créer accident
```
POST /create-accident
Content-Type: multipart/form-data

Payload:
- date_accident: "2025-01-15T14:30:00"
- lieu: "Avenue de la Paix"
- gravite: "grave"
- description: "..."
- temoins_data: JSON array
- vehicules_data: JSON array
- images[]: Files

Response:
{
  "state": true,
  "message": "Accident enregistré",
  "data": {"id": 456}
}
```

### 2. Rechercher véhicule
```
POST /api/accident/search-vehicle
Content-Type: application/json

Payload:
{"plaque": "ABC1234"}

Response:
{
  "success": true,
  "vehicles": [
    {
      "id": 123,
      "plaque": "ABC1234",
      "marque": "Toyota",
      "modele": "Corolla",
      "couleur": "Blanc",
      "annee": "2020"
    }
  ]
}
```

### 3. Créer véhicule rapide
```
POST /vehicule/quick-create
Content-Type: multipart/form-data

Payload:
- plaque: "XYZ9876"
- marque: "Honda"
- modele: "Civic"

Response:
{"ok": true, "id": 789}
```

---

## 💾 Modèles Dart complets

### Accident Model
```dart
class Accident {
  final int? id;
  final DateTime dateAccident;
  final String lieu;
  final AccidentGravite gravite;
  final String description;
  final List<String> imagesPaths;
  final List<Temoin> temoins;
  final List<VehiculeImplique> vehiculesImpliques;

  Accident({
    this.id,
    required this.dateAccident,
    required this.lieu,
    required this.gravite,
    required this.description,
    this.imagesPaths = const [],
    this.temoins = const [],
    this.vehiculesImpliques = const [],
  });

  Map<String, dynamic> toJson() => {
    'date_accident': dateAccident.toIso8601String(),
    'lieu': lieu,
    'gravite': gravite.value,
    'description': description,
    'temoins_data': jsonEncode(temoins.map((t) => t.toJson()).toList()),
    'vehicules_data': jsonEncode(vehiculesImpliques.map((v) => v.toPayload()).toList()),
  };
}

enum AccidentGravite {
  leger('leger', 'Léger'),
  grave('grave', 'Grave'),
  mortel('mortel', 'Mortel'),
  materiel('materiel', 'Matériel uniquement');

  final String value;
  final String label;
  const AccidentGravite(this.value, this.label);
}
```

### Témoin Model
```dart
class Temoin {
  final String nom;
  final String telephone;
  final int age;
  final LienAccident lienAvecAccident;
  final String? temoignage;

  Temoin({
    required this.nom,
    required this.telephone,
    required this.age,
    required this.lienAvecAccident,
    this.temoignage,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'telephone': telephone,
    'age': age,
    'lien_avec_accident': lienAvecAccident.value,
    'temoignage': temoignage ?? '',
  };
}

enum LienAccident {
  temoinDirect('temoin_direct', 'Témoin direct'),
  temoinIndirect('temoin_indirect', 'Témoin indirect'),
  passant('passant', 'Passant'),
  resident('resident', 'Résident du quartier'),
  automobiliste('automobiliste', 'Automobiliste présent'),
  autre('autre', 'Autre');

  final String value;
  final String label;
  const LienAccident(this.value, this.label);
}
```

### Véhicule Model
```dart
class VehiculeImplique {
  final int vehiculePlaqueId;
  final String? plaque;
  final String? marque;
  final String? modele;
  final String? couleur;
  final String? annee;
  final RoleVehicule? role;
  final String? dommages;
  final String? notes;

  VehiculeImplique({
    required this.vehiculePlaqueId,
    this.plaque,
    this.marque,
    this.modele,
    this.couleur,
    this.annee,
    this.role,
    this.dommages,
    this.notes,
  });

  Map<String, dynamic> toPayload() => {
    'vehicule_id': vehiculePlaqueId,
    'role': role?.value,
    'dommages': dommages,
    'notes': notes,
  };
}

enum RoleVehicule {
  responsable('responsable', 'Responsable'),
  victime('victime', 'Victime'),
  indetermine('indetermine', 'Indéterminé');

  final String value;
  final String label;
  const RoleVehicule(this.value, this.label);
}
```

---

## 🎯 Service API

```dart
class AccidentApiService {
  final String baseUrl;
  final http.Client client;

  AccidentApiService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<Map<String, dynamic>> createAccident({
    required Accident accident,
    required List<File> images,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/create-accident'),
    );

    // Ajouter les champs de base
    request.fields.addAll(accident.toJson());

    // Ajouter les images
    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images[]', image.path),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }

  Future<List<VehiculeImplique>> searchVehicle(String plaque) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/accident/search-vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'plaque': plaque}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['vehicles'] as List)
          .map((v) => VehiculeImplique.fromJson(v))
          .toList();
    }
    throw Exception('Erreur recherche véhicule');
  }

  Future<int> quickCreateVehicle({
    required String plaque,
    String? marque,
    String? modele,
    String? couleur,
    String? annee,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vehicule/quick-create'),
    );

    request.fields['plaque'] = plaque;
    if (marque != null) request.fields['marque'] = marque;
    if (modele != null) request.fields['modele'] = modele;
    if (couleur != null) request.fields['couleur'] = couleur;
    if (annee != null) request.fields['annee'] = annee;

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    
    if (data['ok'] == true) {
      return data['id'];
    }
    throw Exception(data['error'] ?? 'Création impossible');
  }
}
```

---

## 🧩 Widgets Flutter essentiels

### Écran principal (résumé)
```dart
class RapportAccidentScreen extends StatefulWidget {
  @override
  State<RapportAccidentScreen> createState() => _RapportAccidentScreenState();
}

class _RapportAccidentScreenState extends State<RapportAccidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = AccidentApiService(baseUrl: 'https://api.example.com');
  
  DateTime _dateAccident = DateTime.now();
  AccidentGravite _gravite = AccidentGravite.materiel;
  final _lieuController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<XFile> _selectedImages = [];
  List<Temoin> _temoins = [];
  List<VehiculeImplique> _vehiculesImpliques = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images != null) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  void _showTemoinModal() async {
    final temoin = await showDialog<Temoin>(
      context: context,
      builder: (context) => TemoinModal(),
    );
    if (temoin != null) {
      setState(() => _temoins.add(temoin));
    }
  }

  void _showVehiculeModal() async {
    final vehicule = await showDialog<VehiculeImplique>(
      context: context,
      builder: (context) => VehiculeImpliquéModal(apiService: _apiService),
    );
    if (vehicule != null) {
      setState(() => _vehiculesImpliques.add(vehicule));
    }
  }

  Future<void> _submitAccident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final accident = Accident(
        dateAccident: _dateAccident,
        lieu: _lieuController.text,
        gravite: _gravite,
        description: _descriptionController.text,
        temoins: _temoins,
        vehiculesImpliques: _vehiculesImpliques,
      );

      final images = await Future.wait(
        _selectedImages.map((xfile) => File(xfile.path)),
      );

      final result = await _apiService.createAccident(
        accident: accident,
        images: images.toList(),
      );

      if (result['state'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapport d\'Accident')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sections...
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submitAccident,
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer'),
      ),
    );
  }
}
```

### Modal Témoin
```dart
class TemoinModal extends StatefulWidget {
  @override
  State<TemoinModal> createState() => _TemoinModalState();
}

class _TemoinModalState extends State<TemoinModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _temoignageController = TextEditingController();
  LienAccident _lien = LienAccident.temoinDirect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom complet *'),
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone *'),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Âge *'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              DropdownButtonFormField<LienAccident>(
                value: _lien,
                decoration: const InputDecoration(labelText: 'Lien'),
                items: LienAccident.values.map((lien) =>
                  DropdownMenuItem(value: lien, child: Text(lien.label)),
                ).toList(),
                onChanged: (v) => setState(() => _lien = v!),
              ),
              TextFormField(
                controller: _temoignageController,
                decoration: const InputDecoration(labelText: 'Témoignage'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                Temoin(
                  nom: _nomController.text,
                  telephone: _telephoneController.text,
                  age: int.parse(_ageController.text),
                  lienAvecAccident: _lien,
                  temoignage: _temoignageController.text,
                ),
              );
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
```

### Modal Véhicule
```dart
class VehiculeImpliquéModal extends StatefulWidget {
  final AccidentApiService apiService;

  const VehiculeImpliquéModal({required this.apiService});

  @override
  State<VehiculeImpliquéModal> createState() => _VehiculeImpliquéModalState();
}

class _VehiculeImpliquéModalState extends State<VehiculeImpliquéModal> {
  bool _isCreationMode = false;
  VehiculeImplique? _selectedVehicule;
  List<VehiculeImplique> _searchResults = [];
  
  final _searchController = TextEditingController();
  final _roleController = TextEditingController();
  final _dommagesController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Pour mode création
  final _plaqueController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();

  Future<void> _searchVehicle() async {
    try {
      final results = await widget.apiService.searchVehicle(
        _searchController.text,
      );
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _createAndAdd() async {
    if (_plaqueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plaque obligatoire')),
      );
      return;
    }

    try {
      final id = await widget.apiService.quickCreateVehicle(
        plaque: _plaqueController.text,
        marque: _marqueController.text,
        modele: _modeleController.text,
      );

      Navigator.pop(
        context,
        VehiculeImplique(
          vehiculePlaqueId: id,
          plaque: _plaqueController.text,
          marque: _marqueController.text,
          modele: _modeleController.text,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _addSelectedVehicle() {
    if (_selectedVehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un véhicule')),
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
        dommages: _dommagesController.text,
        notes: _notesController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter véhicule impliqué'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Créer un nouveau véhicule'),
              value: _isCreationMode,
              onChanged: (v) => setState(() => _isCreationMode = v),
            ),
            const Divider(),
            if (!_isCreationMode) ...[
              // Mode recherche
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher plaque',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchVehicle,
                  ),
                ),
              ),
              if (_searchResults.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final v = _searchResults[index];
                    return ListTile(
                      selected: _selectedVehicule == v,
                      title: Text(v.plaque ?? ''),
                      subtitle: Text('${v.marque} ${v.modele}'),
                      onTap: () => setState(() => _selectedVehicule = v),
                    );
                  },
                ),
              TextField(
                controller: _dommagesController,
                decoration: const InputDecoration(labelText: 'Dommages'),
              ),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ] else ...[
              // Mode création
              TextField(
                controller: _plaqueController,
                decoration: const InputDecoration(labelText: 'Plaque *'),
              ),
              TextField(
                controller: _marqueController,
                decoration: const InputDecoration(labelText: 'Marque'),
              ),
              TextField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Modèle'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _isCreationMode ? _createAndAdd : _addSelectedVehicle,
          child: Text(_isCreationMode ? 'Créer & Ajouter' : 'Ajouter'),
        ),
      ],
    );
  }
}
```

---

## ✅ Validation et contraintes

### Champs obligatoires
- Date accident
- Lieu
- Gravité
- Description

### Champs optionnels
- Images
- Témoins
- Véhicules impliqués

### Règles de validation
- **Date**: Pas dans le futur
- **Lieu**: Min 5 caractères
- **Description**: Min 10 caractères
- **Témoin âge**: Entre 1 et 120
- **Plaque véhicule**: Format valide (selon pays)

---

## 📱 Packages Flutter requis

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  image_picker: ^1.0.4
  intl: ^0.18.1
```

---

## 🎨 Design Tokens

```dart
// Colors
const primaryColor = Color(0xFF007BFF);
const successColor = Color(0xFF28A745);
const dangerColor = Color(0xFFDC3545);
const warningColor = Color(0xFFFFC107);

// Spacing
const spacing8 = 8.0;
const spacing16 = 16.0;
const spacing24 = 24.0;

// Border Radius
const borderRadius8 = BorderRadius.all(Radius.circular(8));
```

---

## 🔐 Gestion d'erreurs

```dart
try {
  final result = await apiService.createAccident(...);
  if (result['state'] == true) {
    // Succès
  } else {
    // Erreur métier
    showError(result['message']);
  }
} on SocketException {
  showError('Pas de connexion internet');
} on TimeoutException {
  showError('Délai d\'attente dépassé');
} catch (e) {
  showError('Erreur: $e');
}
```

---

## 📝 Notes d'implémentation

1. **Images**: Compresser avant upload (max 2MB par image)
2. **Offline**: Stocker en local avec SQLite si pas de connexion
3. **Progress**: Afficher progression upload pour grandes images
4. **Validation**: Valider côté client ET serveur
5. **UX**: Désactiver bouton pendant traitement
6. **Cache**: Mettre en cache les véhicules récemment recherchés

---

## 🚀 Checklist d'implémentation

- [ ] Créer modèles Dart (Accident, Temoin, VehiculeImplique)
- [ ] Créer service API
- [ ] Implémenter écran principal
- [ ] Implémenter modal témoin
- [ ] Implémenter modal véhicule (2 modes)
- [ ] Intégrer ImagePicker
- [ ] Gérer upload multipart
- [ ] Ajouter validation formulaires
- [ ] Gérer états de chargement
- [ ] Ajouter gestion d'erreurs
- [ ] Tester avec API réelle
- [ ] Ajouter stockage offline (optionnel)

---

**Fin de la spécification**
