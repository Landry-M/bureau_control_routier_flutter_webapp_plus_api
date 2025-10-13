# Guide de Test - Expiration de Session par Inactivité

## Pré-requis
- Application Flutter lancée
- Compte utilisateur actif

## Test 1 : Session active (utilisateur interagit régulièrement)

### Objectif
Vérifier que l'utilisateur reste connecté tant qu'il interagit avec l'application.

### Étapes

1. **Se connecter**
   - Ouvrir l'application
   - Se connecter avec un compte valide
   - Noter l'heure de connexion

2. **Interagir régulièrement**
   - Toutes les 10-15 minutes :
     - Cliquer sur un bouton
     - Naviguer entre les écrans
     - Saisir du texte dans un formulaire
     - Scroller dans une liste

3. **Vérification après 2 heures**
   - ✅ L'utilisateur doit toujours être connecté
   - ✅ Aucune notification d'expiration
   - ✅ Toutes les fonctionnalités accessibles

### Résultat attendu
✅ **PASS** : L'utilisateur reste connecté indéfiniment avec interactions régulières

---

## Test 2 : Session inactive (aucune interaction pendant 1h)

### Objectif
Vérifier que la session expire après 1 heure d'inactivité totale.

### Étapes

1. **Se connecter**
   - Se connecter à l'application
   - Noter l'heure : ______

2. **Ne plus toucher l'application**
   - Laisser l'application ouverte
   - Ne faire AUCUNE interaction pendant 1 heure
   - Ne pas toucher la souris/écran
   - Ne pas taper au clavier

3. **Attendre 1 heure complète**
   - Timer : 60 minutes
   
4. **Observer après 1h + 1 minute**
   - Une notification doit apparaître
   - Message : "Votre session a expiré en raison d'une inactivité prolongée (1 heure)"
   - Redirection automatique vers `/login`

### Résultat attendu
✅ **PASS** : Déconnexion automatique + Notification + Redirection login

---

## Test 3 : Réinitialisation du timer par interaction

### Objectif
Vérifier que chaque interaction réinitialise le timer d'inactivité.

### Étapes

1. **Se connecter à 10:00**
   - Connexion initiale

2. **Attendre 30 minutes sans interaction**
   - De 10:00 à 10:30 : Aucune interaction

3. **Interagir à 10:30**
   - Cliquer sur n'importe quel bouton
   - → Timer réinitialisé

4. **Attendre 30 minutes sans interaction**
   - De 10:30 à 11:00 : Aucune interaction

5. **Interagir à 11:00**
   - Taper du texte dans un champ
   - → Timer réinitialisé

6. **Attendre 30 minutes**
   - De 11:00 à 11:30 : Aucune interaction

7. **Vérification à 11:30**
   - ✅ Toujours connecté (dernière activité il y a 30 min)

8. **Attendre encore 30 minutes**
   - De 11:30 à 12:00 : Aucune interaction

9. **Vérification à 12:00**
   - ✅ Déconnexion automatique (1h depuis 11:00)

### Résultat attendu
✅ **PASS** : Le timer est réinitialisé à chaque interaction

---

## Test 4 : Types d'interactions détectées

### Objectif
Vérifier que tous les types d'interactions réinitialisent le timer.

### Interactions à tester

| Type d'interaction | Test | Résultat |
|-------------------|------|----------|
| **Clic souris** | Cliquer sur un bouton | ⬜ Timer réinitialisé |
| **Saisie clavier** | Taper dans un champ | ⬜ Timer réinitialisé |
| **Scroll** | Défiler une liste | ⬜ Timer réinitialisé |
| **Hover** | Survoler un élément | ⬜ Timer réinitialisé |
| **Touch** | Toucher l'écran (mobile) | ⬜ Timer réinitialisé |
| **Drag** | Glisser un élément | ⬜ Timer réinitialisé |
| **Pinch/Zoom** | Zoomer (mobile) | ⬜ Timer réinitialisé |

### Procédure pour chaque test

1. Se connecter
2. Attendre 55 minutes sans interaction
3. Effectuer l'interaction spécifique
4. Attendre 10 minutes supplémentaires (total 65 min depuis connexion)
5. **Vérification** : Toujours connecté (car interaction à 55 min)

### Résultat attendu
✅ **PASS** : Toutes les interactions réinitialisent le timer

---

## Test 5 : Fermeture et réouverture du navigateur

### Objectif
Vérifier que la session expire même si l'application est fermée.

### Étapes

1. **Se connecter à 14:00**
   - Connexion normale

2. **Fermer le navigateur à 14:05**
   - Fermer complètement l'application

3. **Réouvrir à 15:10**
   - Relancer l'application (1h05 après connexion)

4. **Vérification**
   - Le système détecte l'inactivité
   - Déconnexion automatique immédiate
   - Redirection vers login

### Résultat attendu
✅ **PASS** : Déconnexion automatique même après fermeture/réouverture

---

## Test 6 : Vérification des logs (développement)

### Objectif
Vérifier que les logs de debug affichent correctement les activités.

### Étapes

1. **Activer les logs de debug**
   - Ouvrir la console de développement
   - Filtrer par "Activité" ou "inactivité"

2. **Se connecter**
   - Observer les logs :
     ```
     Activité utilisateur enregistrée: 2025-10-13 14:00:00.000
     ```

3. **Interagir (cliquer)**
   - Observer les logs :
     ```
     Activité utilisateur enregistrée: 2025-10-13 14:05:30.000
     ```

4. **Attendre 1 minute sans interaction**
   - Observer les logs :
     ```
     Vérification inactivité: 1 minutes
     ```

5. **Attendre 60 minutes**
   - Observer les logs :
     ```
     Vérification inactivité: 60 minutes
     Session expirée par inactivité (60 minutes)
     ```

### Résultat attendu
✅ **PASS** : Les logs confirment l'enregistrement des activités et vérifications

---

## Test 7 : Temps restant avant expiration

### Objectif
Vérifier que la méthode `getTimeUntilSessionExpiry()` retourne le bon temps.

### Code de test (à intégrer temporairement)

```dart
// Dans un widget visible (ex: Dashboard)
Timer.periodic(Duration(seconds: 10), (timer) {
  final authProvider = context.read<AuthProvider>();
  final remaining = authProvider.getTimeUntilSessionExpiry();
  
  if (remaining != null) {
    print('Session expire dans : ${remaining.inMinutes} minutes');
  }
});
```

### Vérification

1. Se connecter
2. Observer la console toutes les 10 secondes
3. **Attendu** :
   ```
   Session expire dans : 60 minutes
   Session expire dans : 59 minutes
   Session expire dans : 59 minutes
   ...
   Session expire dans : 1 minutes
   Session expire dans : 0 minutes
   → Déconnexion
   ```

4. Faire une interaction
5. **Attendu** : Le compteur redémarre à 60 minutes

### Résultat attendu
✅ **PASS** : Le temps restant est calculé correctement

---

## Test 8 : Plusieurs utilisateurs simultanés

### Objectif
Vérifier que chaque session est indépendante.

### Étapes

1. **Session 1 (Chrome)**
   - Se connecter en tant qu'Agent1 à 10:00
   - Ne plus toucher

2. **Session 2 (Firefox)**
   - Se connecter en tant qu'Agent2 à 10:30
   - Interagir régulièrement

3. **Vérification à 11:00**
   - Session 1 : ✅ Déconnectée (1h d'inactivité)
   - Session 2 : ✅ Toujours connectée (activité régulière)

### Résultat attendu
✅ **PASS** : Les sessions sont indépendantes

---

## Test 9 : Mode de test rapide (pour développement)

### Objectif
Tester l'expiration sans attendre 1 heure.

### Modification temporaire

Dans `/lib/providers/auth_provider.dart` :

```dart
// TEMPORAIRE - pour tests uniquement
static const Duration inactivityTimeout = Duration(minutes: 2); // Au lieu de 1 heure
```

### Procédure

1. Modifier le timeout à 2 minutes
2. Se connecter
3. Ne pas toucher pendant 2 minutes
4. **Résultat** : Déconnexion après 2 minutes

⚠️ **IMPORTANT** : Remettre à 1 heure après les tests !

```dart
static const Duration inactivityTimeout = Duration(hours: 1);
```

---

## Checklist de validation

| Test | Description | Statut | Notes |
|------|-------------|--------|-------|
| 1 | Session active | ⬜ | |
| 2 | Session inactive 1h | ⬜ | |
| 3 | Réinitialisation timer | ⬜ | |
| 4 | Types d'interactions | ⬜ | |
| 5 | Fermeture/réouverture | ⬜ | |
| 6 | Logs de debug | ⬜ | |
| 7 | Temps restant | ⬜ | |
| 8 | Sessions multiples | ⬜ | |

---

## Résultats attendus globaux

### Comportement normal

✅ Utilisateur actif → Reste connecté indéfiniment
✅ Utilisateur inactif 1h → Déconnecté automatiquement
✅ Notification claire affichée lors de l'expiration
✅ Redirection automatique vers login
✅ Chaque interaction réinitialise le timer
✅ Logs de debug affichent les activités

### Cas limites

✅ Fermeture/réouverture → Expiration détectée
✅ Multiples sessions → Indépendantes
✅ Changement d'onglet → Timer continue
✅ Minimiser la fenêtre → Timer continue

---

## Dépannage

### Problème : Déconnexion trop rapide

**Cause possible** : Le timeout est configuré à une valeur trop courte

**Solution** :
```dart
// Vérifier dans auth_provider.dart
static const Duration inactivityTimeout = Duration(hours: 1); // ✅ Correct
```

### Problème : Jamais déconnecté

**Cause possible** : Le timer ne démarre pas

**Solution** :
1. Vérifier que `startInactivityCheck()` est appelé après login
2. Vérifier les logs : "Vérification inactivité: X minutes"
3. Vérifier que `ActivityDetector` enveloppe bien l'application

### Problème : Activités non détectées

**Cause possible** : `ActivityDetector` mal placé

**Solution** :
```dart
// Vérifier dans main.dart
child: ScheduleGuard(
  child: ActivityDetector(  // ← Doit envelopper MaterialApp
    child: MaterialApp.router(...),
  ),
),
```

---

## Rapport de test (à remplir)

**Date** : _______________
**Testeur** : _______________
**Version** : _______________

### Tests réussis
- [ ] Test 1 : Session active
- [ ] Test 2 : Session inactive 1h
- [ ] Test 3 : Réinitialisation timer
- [ ] Test 4 : Types d'interactions
- [ ] Test 5 : Fermeture/réouverture

### Tests échoués
_Décrire les problèmes rencontrés :_

---

### Commentaires
_Observations, suggestions, améliorations :_

---

## Conclusion

Le système d'expiration de session par inactivité doit garantir :
1. **Sécurité** : Aucune session ne reste ouverte indéfiniment
2. **Transparence** : L'utilisateur sait pourquoi il a été déconnecté
3. **Fiabilité** : Le système fonctionne dans tous les scénarios

Une fois tous les tests validés, le système est prêt pour la production.
