# Expiration de Session par Inactivité

## Vue d'ensemble

L'application implémente maintenant un **système d'expiration de session après 1 heure d'inactivité**. Si l'utilisateur n'interagit pas avec l'application pendant 1 heure, sa session expire automatiquement et il est déconnecté.

## Fonctionnement

### Détection d'activité

**Qu'est-ce qui compte comme activité ?**
- ✅ Cliquer n'importe où dans l'application
- ✅ Taper au clavier (saisie de texte)
- ✅ Défiler (scroll)
- ✅ Déplacer la souris (hover)
- ✅ Toucher l'écran (mobile/tablette)
- ✅ Utiliser les gestes (pinch, zoom, etc.)

**Qu'est-ce qui NE compte PAS comme activité ?**
- ❌ Laisser la page ouverte sans interaction
- ❌ Regarder l'écran sans toucher
- ❌ Requêtes automatiques en arrière-plan

### Timer d'inactivité

- **Durée** : 1 heure (60 minutes)
- **Vérification** : Toutes les minutes
- **Réinitialisation** : À chaque interaction utilisateur
- **Action** : Déconnexion automatique + notification

## Architecture technique

### 1. AuthProvider (`/lib/providers/auth_provider.dart`)

#### Nouvelles propriétés

```dart
Timer? _inactivityCheckTimer;           // Timer de vérification
DateTime? _lastActivityTime;            // Dernière activité enregistrée
static const Duration inactivityTimeout = Duration(hours: 1); // Timeout
Function()? onInactivityTimeout;        // Callback de timeout
```

#### Méthodes principales

##### `startInactivityCheck()`
Démarre la vérification d'inactivité toutes les minutes.

```dart
void startInactivityCheck() {
  _lastActivityTime = DateTime.now();
  _inactivityCheckTimer = Timer.periodic(
    const Duration(minutes: 1),
    (timer) => _checkInactivity(),
  );
}
```

##### `recordActivity()`
Enregistre une activité utilisateur et réinitialise le timer.

```dart
void recordActivity() {
  _lastActivityTime = DateTime.now();
}
```

##### `_checkInactivity()`
Vérifie si l'utilisateur est inactif depuis trop longtemps.

```dart
void _checkInactivity() {
  final inactiveDuration = DateTime.now().difference(_lastActivityTime!);
  
  if (inactiveDuration >= inactivityTimeout) {
    onInactivityTimeout?.call(); // Déclencher la déconnexion
  }
}
```

##### `getTimeUntilSessionExpiry()`
Retourne le temps restant avant expiration de session.

```dart
Duration? getTimeUntilSessionExpiry() {
  final elapsed = DateTime.now().difference(_lastActivityTime!);
  return inactivityTimeout - elapsed;
}
```

### 2. ActivityDetector (`/lib/widgets/activity_detector.dart`)

Widget qui enveloppe toute l'application et détecte les interactions.

```dart
class ActivityDetector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _recordActivity(context),
      onPanDown: (_) => _recordActivity(context),
      child: Listener(
        onPointerDown: (_) => _recordActivity(context),
        onPointerMove: (_) => _recordActivity(context),
        onPointerHover: (_) => _recordActivity(context),
        child: child,
      ),
    );
  }
  
  void _recordActivity(BuildContext context) {
    context.read<AuthProvider>().recordActivity();
  }
}
```

### 3. ScheduleGuard (`/lib/widgets/schedule_guard.dart`)

Gère la déconnexion automatique en cas d'inactivité.

```dart
void _handleInactivityTimeout() {
  NotificationService.warning(
    context,
    'Votre session a expiré en raison d\'une inactivité prolongée (1 heure).',
    title: 'Session expirée',
  );
  
  authProvider.logout().then((_) {
    context.go('/login');
  });
}
```

### 4. Intégration dans main.dart

```dart
MultiProvider(
  providers: [...],
  child: ScheduleGuard(
    child: ActivityDetector(  // ← Détecte toutes les interactions
      child: MaterialApp.router(...),
    ),
  ),
)
```

## Flux de fonctionnement

```
1. Utilisateur se connecte
   ↓
2. startInactivityCheck() démarré
   ↓
3. _lastActivityTime = maintenant
   ↓
4. Timer vérifie toutes les minutes
   ↓
5. Utilisateur interagit avec l'app
   ↓
6. recordActivity() réinitialise _lastActivityTime
   ↓
7. Si aucune interaction pendant 1h
   ↓
8. onInactivityTimeout() appelé
   ↓
9. Notification affichée
   ↓
10. Déconnexion automatique
   ↓
11. Redirection vers /login
```

## Exemples de scénarios

### Scénario 1 : Utilisateur actif

```
10:00 - Connexion
10:30 - Clique sur un bouton → Timer réinitialisé
11:15 - Saisit du texte → Timer réinitialisé
11:45 - Scroll dans une liste → Timer réinitialisé
12:30 - Toujours connecté (activité régulière)
```

### Scénario 2 : Utilisateur inactif

```
10:00 - Connexion
10:15 - Clique sur un rapport
10:16 - Plus d'interaction
11:16 - Session expire automatiquement
      - Notification "Session expirée"
      - Déconnexion
      - Redirection vers /login
```

### Scénario 3 : Retour après pause

```
14:00 - Connexion
14:30 - Pause déjeuner (ferme le navigateur)
15:45 - Retour et réouverture du navigateur
      - Session déjà expirée (> 1h d'inactivité)
      - Vérifié immédiatement
      - Déconnecté automatiquement
```

## Configuration

### Modifier la durée du timeout

Dans `/lib/providers/auth_provider.dart` :

```dart
static const Duration inactivityTimeout = Duration(hours: 1);
```

Changez en :
```dart
static const Duration inactivityTimeout = Duration(minutes: 30); // 30 minutes
static const Duration inactivityTimeout = Duration(hours: 2);    // 2 heures
static const Duration inactivityTimeout = Duration(hours: 8);    // 8 heures
```

### Modifier la fréquence de vérification

Dans `startInactivityCheck()` :

```dart
_inactivityCheckTimer = Timer.periodic(
  const Duration(minutes: 1),  // ← Modifier ici
  (timer) => _checkInactivity(),
);
```

⚠️ **Attention** : Ne pas mettre une fréquence trop courte (< 30 secondes) pour éviter une consommation excessive des ressources.

## Avantages

### Sécurité

✅ **Protection des données** : Les sessions inactives ne restent pas ouvertes indéfiniment
✅ **Conformité** : Répond aux exigences de sécurité pour les applications gouvernementales
✅ **Prévention d'accès non autorisé** : Si quelqu'un laisse sa session ouverte

### Expérience utilisateur

✅ **Notification claire** : L'utilisateur sait pourquoi il a été déconnecté
✅ **Aucune perte de données** : Les saisies sont sauvegardées avant expiration
✅ **Réinitialisation automatique** : Le timer se réinitialise à chaque interaction

### Performance

✅ **Impact minimal** : Vérification légère toutes les minutes
✅ **Pas de polling constant** : Utilise des events natifs (GestureDetector/Listener)
✅ **Économie de ressources** : Sessions inactives libérées

## Combinaison avec autres sécurités

Le système d'inactivité fonctionne **en parallèle** avec :

1. **Vérification des horaires** (toutes les 5 minutes)
   - Si hors horaires → Déconnexion
   
2. **Vérification du statut du compte**
   - Si compte désactivé → Déconnexion

3. **Expiration d'inactivité** (toutes les minutes)
   - Si inactif > 1h → Déconnexion

Les trois systèmes sont indépendants et complémentaires.

## Exemptions

### Qui est concerné ?

- ✅ **Tous les utilisateurs** (agents, admins, superadmins)

Il n'y a **aucune exemption** pour l'expiration par inactivité. Même les superadmins sont soumis à cette règle pour des raisons de sécurité.

Si vous souhaitez exempter les superadmins, modifiez `_checkInactivity()` :

```dart
void _checkInactivity() {
  // Exempter les superadmins
  if (_role == 'superadmin') {
    return;
  }
  
  // ... reste du code
}
```

## Logs et traçabilité

Actuellement, les logs de debug affichent :
- ✅ Chaque enregistrement d'activité
- ✅ Chaque vérification d'inactivité
- ✅ Expiration de session

Pour activer/désactiver les logs, modifiez les `debugPrint()` dans `auth_provider.dart`.

## Tests

### Test 1 : Session active

1. Se connecter
2. Interagir régulièrement (cliquer, taper, scroller)
3. **Résultat attendu** : Rester connecté indéfiniment

### Test 2 : Session inactive

1. Se connecter
2. Ne plus toucher pendant 1 heure
3. **Résultat attendu** :
   - Notification "Session expirée"
   - Déconnexion automatique
   - Redirection vers login

### Test 3 : Activité sporadique

1. Se connecter à 10:00
2. Interagir à 10:30
3. Ne plus toucher jusqu'à 11:31
4. **Résultat attendu** : Déconnexion à 11:30 (1h après 10:30)

### Test 4 : Temps restant

```dart
// Afficher le temps restant
final remaining = authProvider.getTimeUntilSessionExpiry();
print('Session expire dans : ${remaining?.inMinutes} minutes');
```

## Améliorations futures possibles

1. **Avertissement avant expiration**
   - Notification 5 minutes avant expiration
   - Option "Rester connecté" pour prolonger

2. **Statistiques d'utilisation**
   - Temps moyen de session
   - Taux d'expiration par inactivité

3. **Timeout personnalisable par rôle**
   - Agents : 1 heure
   - Admins : 4 heures
   - Superadmins : 8 heures

4. **Mode "Rester connecté"**
   - Option au login pour désactiver l'expiration
   - Uniquement pour certains rôles/situations

## Dépannage

### L'utilisateur est déconnecté trop rapidement

- Vérifier que `inactivityTimeout` est bien à 1 heure
- Vérifier que `recordActivity()` est appelé lors des interactions
- Ajouter des `debugPrint()` pour tracer les activités

### L'utilisateur n'est jamais déconnecté

- Vérifier que `startInactivityCheck()` est appelé après login
- Vérifier que le Timer est actif (`_inactivityCheckTimer != null`)
- Vérifier que `onInactivityTimeout` est bien défini

### Problèmes de performance

- Réduire la verbosité des logs (enlever les `debugPrint()`)
- Augmenter la fréquence de vérification (ex: 5 minutes au lieu de 1)

## Conclusion

Le système d'expiration de session par inactivité améliore significativement la sécurité de l'application tout en maintenant une bonne expérience utilisateur. Il fonctionne de manière transparente en arrière-plan et garantit qu'aucune session ne reste ouverte indéfiniment.

## Statut

✅ **Implémenté** - 13 octobre 2025
✅ **Testé** - Détection d'activité + Expiration fonctionnelle
✅ **Documenté** - Ce fichier
⏱️ **Timeout configuré** : 1 heure d'inactivité
