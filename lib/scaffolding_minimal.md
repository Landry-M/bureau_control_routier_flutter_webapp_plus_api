
### Objectif
Générer le scaffolding Flutter Web et API PHP suivants, sans logique métier complète. Uniquement la structure de fichiers, routes, écrans vides, providers stubs, services stubs et contrôleurs vides côté backend.

### Structure
```
lib/
  main.dart
  routes.dart
  theme.dart
  screens/ ...
  widgets/ ...
  providers/ ...
  services/ ...
  models/ ...
api/
  config/
    database.php
    env.php
  controllers/
    AuthController.php
    VehiculeController.php
    ParticulierController.php
    EntrepriseController.php
    ContraventionController.php
    PermisController.php
    AvisController.php
    AccidentController.php
    ArrestationController.php
    UploadController.php
    PdfController.php
    LogController.php
  routes/
    index.php
  logs/
    actions.log
```

### Particularité (Logs)
- Chaque action API (create/update/delete/login/logout, etc.) est **enregistrée dans un fichier `api/logs/actions.log`** ou en base de données.
- Un écran Flutter `LogsScreen` est créé, mais **visible uniquement par le superadmin** via les rôles gérés par `AuthProvider`.

### Écrans Flutter à générer (vides)
- LoginScreen, FirstConnectionScreen, DashboardScreen
- CRUD (véhicules, particuliers, entreprises, contraventions, permis, avis, accidents, arrestations)
- LogsScreen (liste des logs, restreint au superadmin)

### Providers (stubs vides)
- AuthProvider, VehiculeProvider, ParticulierProvider, EntrepriseProvider, ContraventionProvider, PermisProvider, AvisProvider, AccidentProvider, ArrestationProvider, SearchProvider, **LogProvider** (pour récupérer les logs).

### Services Flutter (interfaces vides)
- ApiClient, AuthService, VehiculeService, ParticulierService, EntrepriseService, ContraventionService, PermisService, AvisService, AccidentService, ArrestationService, UploadService, PdfService, **LogService**.

### Backend API (routes de base)
- Chaque contrôleur expose des méthodes CRUD.
- `LogController` : GET `/logs` (accessible uniquement par superadmin).

---