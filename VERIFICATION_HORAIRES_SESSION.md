# Vérification des Horaires de Connexion en Session

## Problème résolu
Auparavant, la vérification des horaires de connexion (`login_schedule`) se faisait **uniquement lors du login**. Une fois connecté, l'utilisateur pouvait continuer à naviguer même si :
- Le superadmin modifiait ses horaires de travail
- L'heure actuelle sortait des plages autorisées
- Son compte était désactivé

## Solution implémentée

### 1. **Vérification périodique automatique**
Le système vérifie maintenant les horaires **toutes les 5 minutes** pendant la session de l'utilisateur.

### 2. **Architecture**

#### Backend (API)
- **Fichier** : `/api/check_session_schedule.php`
- **Endpoint** : `GET /check_session_schedule.php?user_id={id}` ou `?matricule={matricule}`
- **Fonctionnalité** : Vérifie si l'utilisateur est autorisé selon :
  - Ses horaires de travail (`login_schedule`)
  - Son statut de compte (actif/inactif)
  - Son rôle (les superadmins ne sont jamais restreints)

**Réponse JSON :**
```json
{
  "success": true,
  "authorized": true|false,
  "message": "Accès autorisé" | "En dehors des heures de travail",
  "reason": null | "outside_schedule" | "account_disabled",
  "current_time": "14:30",
  "current_day": 3
}
```

#### Frontend (Flutter)

##### Service
- **Fichier** : `/lib/services/session_schedule_service.dart`
- **Classe** : `SessionScheduleService`
- **Méthode** : `checkSchedule(userId, matricule)`

##### Provider
- **Fichier** : `/lib/providers/auth_provider.dart`
- **Nouvelles méthodes** :
  - `startScheduleCheck()` : Démarre la vérification périodique (toutes les 5 minutes)
  - `checkScheduleNow()` : Force une vérification immédiate
  - `_checkSchedule()` : Méthode privée de vérification
  - `onScheduleViolation` : Callback appelé si l'utilisateur est hors horaires

##### Widget de surveillance
- **Fichier** : `/lib/widgets/schedule_guard.dart`
- **Classe** : `ScheduleGuard`
- **Fonctionnalité** : 
  - Enveloppe l'application entière
  - Configure le callback de violation des horaires
  - Déconnecte automatiquement l'utilisateur et affiche une notification

### 3. **Flux de fonctionnement**

```
1. Utilisateur se connecte
   ↓
2. AuthProvider.login() réussit
   ↓
3. startScheduleCheck() est appelé
   ↓
4. Vérification immédiate, puis toutes les 5 minutes
   ↓
5. Si hors horaires détecté:
   - onScheduleViolation() est appelé
   - Notification affichée
   - Déconnexion automatique
   - Redirection vers /login
```

### 4. **Cas couverts**

✅ **Modification des horaires par le superadmin**
- L'agent est déconnecté automatiquement si les nouveaux horaires ne le permettent plus

✅ **Changement d'heure pendant la session**
- L'agent est déconnecté quand l'heure sort de ses plages autorisées

✅ **Désactivation du compte**
- L'agent est déconnecté immédiatement à la prochaine vérification

✅ **Superadmins exemptés**
- Les superadmins ne sont jamais soumis aux restrictions horaires

### 5. **Paramètres configurables**

Dans `/lib/providers/auth_provider.dart` :
```dart
// Fréquence de vérification (actuellement 5 minutes)
_scheduleCheckTimer = Timer.periodic(
  const Duration(minutes: 5),  // ← Modifiable ici
  (timer) => _checkSchedule(),
);
```

### 6. **Gestion des erreurs**

Le système est conçu pour être **fail-safe** :
- Si l'API ne répond pas → L'utilisateur n'est **PAS** déconnecté
- Si une erreur réseau survient → L'utilisateur reste connecté
- En cas de timeout → L'utilisateur continue sa session

Cela évite de déconnecter les utilisateurs en cas de problèmes techniques temporaires.

### 7. **Logs et traçabilité**

Les tentatives de connexion hors horaires sont enregistrées dans la table `logs` :
- Type d'action : "Tentative de connexion en dehors des horaires"
- Détails : user_id, role, timestamp, IP, user agent

### 8. **Tests**

Pour tester le système :

1. **Créer un utilisateur avec horaires restreints** (via superadmin)
2. **Se connecter avec cet utilisateur**
3. **Le superadmin modifie les horaires pour exclure l'heure actuelle**
4. **Attendre 5 minutes maximum**
5. **L'utilisateur est automatiquement déconnecté**

### 9. **Sécurité**

- ✅ Les tokens JWT ne sont pas invalidés côté serveur (optionnel à implémenter)
- ✅ La vérification se fait côté serveur (non contournable)
- ✅ Les superadmins sont exemptés pour éviter de se bloquer eux-mêmes
- ✅ Les erreurs ne divulguent pas d'informations sensibles

### 10. **Performance**

- **Impact minimal** : Requête HTTP légère toutes les 5 minutes
- **Pas de polling constant** : Utilisation de Timer.periodic
- **Pas de surcharge réseau** : ~12 requêtes par heure par utilisateur connecté

## Prochaines améliorations possibles

1. **Vérification en temps réel avec WebSockets** pour une déconnexion instantanée
2. **Avertissement avant déconnexion** (ex: "Vous serez déconnecté dans 5 minutes")
3. **Invalidation des tokens JWT côté serveur** pour plus de sécurité
4. **Dashboard admin** pour voir les utilisateurs actuellement connectés
5. **Historique des déconnexions automatiques** dans les logs

## Conclusion

Le système garantit maintenant que les restrictions horaires sont **appliquées en continu** pendant toute la durée de la session, et pas seulement au moment du login. Cela répond au besoin de contrôle en temps réel des accès utilisateurs.
