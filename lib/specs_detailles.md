
### Ajout clé : Gestion des logs
**Objectif :** conserver une trace de toutes les actions effectuées par les utilisateurs (connexion, création/modification/suppression, uploads, génération de PDF, libérations, etc.).

#### Fonctionnalités
- Chaque appel API écrit dans un journal avec :
  - id utilisateur, rôle, action, endpoint, paramètres principaux, date/heure.
- Stockage dans :
  - table `activites` (id, user_id, role, action, endpoint, data, created_at).
  - backup fichier `api/logs/actions.log`.
- Superadmin dispose d’un écran **LogsScreen** permettant :
  - de visualiser les logs en tableau.
  - de filtrer par utilisateur, date, type d’action.

#### Écran Flutter
- `screens/logs/logs_screen.dart`
- Liste paginée des logs (data table).
- Accessible uniquement si `AuthProvider.role == superadmin`.

#### Provider associé
- `LogProvider`
  - État : `logs`, `isLoading`, `errorMessage`.
  - Actions : `fetchLogs()`, `filterLogs()`, `clearLogs()`.

#### Service associé
- `LogService`
  - GET `/logs` → récupère tous les logs (superadmin uniquement).

#### Contrôleur PHP
- `controllers/LogController.php`
  ```php
  class LogController {
      public function getAll() {
          Auth::requireRole('superadmin');
          $logs = Log::all();
          echo json_encode($logs);
      }
      public static function record($userId, $role, $action, $endpoint, $data = []) {
          // Sauvegarde en DB
          DB::insert('INSERT INTO  activites (user_id, role, action, endpoint, data) VALUES (?, ?, ?, ?, ?)',
            [$userId, $role, $action, $endpoint, json_encode($data)]);
          // Sauvegarde en fichier
          file_put_contents(__DIR__.'/../logs/actions.log',
              date('Y-m-d H:i:s')." | $role#$userId | $action | $endpoint | ".json_encode($data)."\n",
              FILE_APPEND);
      }
  }
  ```
- Exemple d’utilisation dans `VehiculeController` :
  ```php
  LogController::record($userId, $role, 'CREATE', '/vehicule', $_POST);
  ```

---

👉 Résumé :
- Le **fichier minimal** donne juste la structure et l’écran de logs vide.
- Le **fichier détaillé** ajoute toute la logique de logs (DB + fichiers), visible seulement par le **superadmin**.

