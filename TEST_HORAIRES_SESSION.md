# Guide de Test - Vérification des Horaires en Session

## Pré-requis
- Application Flutter lancée
- API PHP accessible
- Compte superadmin actif

## Scénario de test 1 : Modification des horaires pendant la session

### Étapes

1. **Créer un agent de test avec horaires restreints**
   - Se connecter en tant que **superadmin**
   - Aller dans **Gestion des utilisateurs**
   - Créer ou modifier un agent
   - Définir des horaires : Par exemple, **Lundi-Vendredi 08:00-17:00**
   - Sauvegarder

2. **Se connecter avec l'agent**
   - Se déconnecter du superadmin
   - Se connecter avec le compte de l'agent de test
   - Vérifier que l'on accède bien au dashboard

3. **Modifier les horaires pour exclure l'heure actuelle**
   - Dans un autre navigateur/onglet privé, se connecter en **superadmin**
   - Modifier les horaires de l'agent pour **exclure l'heure actuelle**
     - Ex: Si il est 14h, mettre les horaires à 08:00-12:00 uniquement
   - Sauvegarder les modifications

4. **Attendre la vérification automatique**
   - Retourner sur la session de l'agent
   - **Attendre maximum 5 minutes**
   - L'agent devrait être automatiquement déconnecté
   - Une notification devrait apparaître : "Vous avez été déconnecté car vous êtes en dehors de vos heures de travail autorisées"
   - Redirection automatique vers `/login`

## Scénario de test 2 : Désactivation du compte

### Étapes

1. **Agent connecté**
   - Se connecter avec un compte agent

2. **Superadmin désactive le compte**
   - Dans un autre navigateur, le superadmin désactive le compte de l'agent
   - Changer le statut à "Inactif" ou "Bloqué"

3. **Vérification automatique**
   - Attendre maximum 5 minutes
   - L'agent devrait être déconnecté automatiquement

## Scénario de test 3 : Test manuel immédiat

### Via le code (pour développement)

Vous pouvez forcer une vérification immédiate en appelant :

```dart
final authProvider = context.read<AuthProvider>();
final isAuthorized = await authProvider.checkScheduleNow();

if (!isAuthorized) {
  // L'utilisateur devrait être déconnecté
  print('Utilisateur hors horaires');
}
```

### Via API directement

Testez l'endpoint avec curl :

```bash
# Remplacer {user_id} par l'ID de l'utilisateur
curl "http://localhost/api/check_session_schedule.php?user_id=3"

# Ou avec le matricule
curl "http://localhost/api/check_session_schedule.php?matricule=police001"
```

**Réponse attendue si autorisé :**
```json
{
  "success": true,
  "authorized": true,
  "message": "Accès autorisé",
  "reason": null,
  "current_time": "14:30",
  "current_day": 3
}
```

**Réponse attendue si hors horaires :**
```json
{
  "success": true,
  "authorized": false,
  "message": "En dehors des heures de travail",
  "reason": "outside_schedule",
  "current_time": "22:30",
  "current_day": 3
}
```

## Scénario de test 4 : Superadmin jamais restreint

### Étapes

1. **Se connecter en tant que superadmin**
2. **Modifier ses propres horaires** pour exclure l'heure actuelle
3. **Attendre 5 minutes**
4. **Vérification** : Le superadmin reste connecté (jamais déconnecté)

## Points de contrôle

✅ **Timer démarre au login**
- Vérifier dans les logs de debug : "Démarrage de la vérification périodique des horaires"

✅ **Vérification périodique toutes les 5 minutes**
- Observer les requêtes réseau dans DevTools
- L'endpoint `/check_session_schedule.php` devrait être appelé régulièrement

✅ **Déconnexion automatique**
- Notification affichée
- Redirection vers `/login`
- Token supprimé

✅ **Logs enregistrés**
- Vérifier dans la table `logs` de la base de données
- Chercher les entrées "Tentative de connexion en dehors des horaires"

## Dépannage

### L'utilisateur n'est pas déconnecté après 5 minutes

1. **Vérifier que l'API est accessible**
   ```bash
   curl "http://localhost/api/check_session_schedule.php?user_id=1"
   ```

2. **Vérifier que le timer est actif**
   - Ajouter un `print()` dans `_checkSchedule()` pour confirmer l'exécution

3. **Vérifier les horaires dans la base de données**
   ```sql
   SELECT id, matricule, login_schedule FROM users WHERE id = 3;
   ```

4. **Vérifier le rôle de l'utilisateur**
   - Les superadmins ne sont jamais déconnectés

### Erreur API 404

- Vérifier que le fichier `/api/check_session_schedule.php` existe
- Vérifier la configuration CORS

### Timer ne démarre pas

- Vérifier que `startScheduleCheck()` est appelé après le login
- Vérifier dans `auth_provider.dart` ligne ~88

## Logs utiles

Pour activer les logs de debug :

```dart
// Dans auth_provider.dart, méthode _checkSchedule()
debugPrint('Vérification des horaires - User: $_userId, Authorized: ${result.authorized}');
```

## Fréquence de vérification

Pour changer la fréquence (actuellement 5 minutes) :

```dart
// Dans auth_provider.dart, méthode startScheduleCheck()
_scheduleCheckTimer = Timer.periodic(
  const Duration(minutes: 2),  // ← Changer ici (ex: 2 minutes pour les tests)
  (timer) => _checkSchedule(),
);
```

⚠️ **Attention** : Ne pas mettre une fréquence trop courte en production (consommation réseau)

## Résultats attendus

| Scénario | Résultat attendu |
|----------|-----------------|
| Agent avec horaires valides | Reste connecté |
| Agent hors horaires | Déconnecté automatiquement |
| Superadmin hors horaires | Reste connecté (jamais restreint) |
| Compte désactivé | Déconnecté automatiquement |
| Erreur API/Réseau | Reste connecté (fail-safe) |
| Login réussi | Timer démarre automatiquement |
| Logout manuel | Timer s'arrête |

## Conclusion

Le système doit garantir qu'aucun utilisateur (sauf superadmin) ne puisse continuer à travailler en dehors de ses horaires autorisés, même si ces horaires changent pendant sa session.
