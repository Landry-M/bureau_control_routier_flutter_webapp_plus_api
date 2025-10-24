# ⏱️ Déconnexion Automatique par Inactivité

## 🎯 Fonctionnalité Implémentée

Le système déconnecte automatiquement l'utilisateur après **30 minutes d'inactivité** pour des raisons de sécurité.

---

## ⚙️ Configuration

### Durée d'Inactivité
- **Timeout** : 30 minutes
- **Avertissement** : 5 minutes avant la déconnexion (à 25 minutes d'inactivité)

### Fichier de Configuration
**`lib/providers/auth_provider.dart`** (lignes 33-34)
```dart
static const Duration inactivityTimeout = Duration(minutes: 30);
static const Duration warningBeforeTimeout = Duration(minutes: 5);
```

---

## 🔄 Fonctionnement

### 1. **Détection d'Activité**
Le widget `ActivityDetector` enveloppe toute l'application et détecte :
- ✅ Clics de souris
- ✅ Mouvements de souris (hover)
- ✅ Gestes tactiles
- ✅ Défilement de page
- ✅ Touches clavier (via pointer events)

**Fichier** : `lib/widgets/activity_detector.dart`

### 2. **Vérification Périodique**
Le système vérifie l'inactivité **toutes les 1 minute**.

**Fichier** : `lib/providers/auth_provider.dart` (ligne 287-290)
```dart
_inactivityCheckTimer = Timer.periodic(
  const Duration(minutes: 1),
  (timer) => _checkInactivity(),
);
```

### 3. **Timeline de Déconnexion**

```
┌────────────────────────────────────────────────────┐
│  0 min          25 min                    30 min   │
│   │              │                          │       │
│   ✅             ⚠️                         ❌      │
│ Actif        Avertissement             Déconnexion │
└────────────────────────────────────────────────────┘
```

#### Scénario 1 : Utilisateur Actif
```
Minute 0    : Connexion
Minute 1-24 : Utilisateur clique, scroll, bouge la souris
            → Timer réinitialisé à chaque action
Résultat    : ✅ Reste connecté
```

#### Scénario 2 : Utilisateur Inactif avec Intervention
```
Minute 0    : Connexion
Minute 1-24 : Aucune activité
Minute 25   : ⚠️ AVERTISSEMENT affiché
            → "Vous serez déconnecté dans 5 minutes"
Minute 26   : Utilisateur clique sur "Rester connecté"
            → Timer réinitialisé
Résultat    : ✅ Reste connecté
```

#### Scénario 3 : Utilisateur Inactif sans Intervention
```
Minute 0    : Connexion
Minute 1-24 : Aucune activité
Minute 25   : ⚠️ AVERTISSEMENT affiché
Minute 30   : ❌ DÉCONNEXION AUTOMATIQUE
            → Dialogue "Session expirée"
            → Redirection vers /login
```

---

## 🎨 Interface Utilisateur

### 1. Dialogue d'Avertissement (25 minutes)

```
┌──────────────────────────────────────────────┐
│  ⏱️ Inactivité détectée                      │
├──────────────────────────────────────────────┤
│                                              │
│  Vous serez déconnecté dans 5 minutes       │
│  en raison d'une inactivité prolongée.      │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │ ℹ️  Bougez votre souris ou cliquez    │  │
│  │     pour rester connecté.            │  │
│  └──────────────────────────────────────┘  │
│                                              │
│         [J'ai compris] [✓ Rester connecté]  │
└──────────────────────────────────────────────┘
```

**Actions possibles** :
- **"J'ai compris"** : Ferme le dialogue (déconnexion dans 5 min si aucune activité)
- **"Rester connecté"** : Réinitialise le timer + ferme le dialogue

### 2. Dialogue de Déconnexion (30 minutes)

```
┌──────────────────────────────────────────────┐
│  🚪 Session expirée                          │
├──────────────────────────────────────────────┤
│                                              │
│  Votre session a expiré en raison           │
│  d'une inactivité de 30 minutes.            │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │ 🔒 Par mesure de sécurité, vous      │  │
│  │     allez être déconnecté.           │  │
│  └──────────────────────────────────────┘  │
│                                              │
│                      [🔑 Se reconnecter]    │
└──────────────────────────────────────────────┘
```

**Action** :
- **"Se reconnecter"** : Déconnexion + redirection vers `/login`

---

## 📁 Architecture du Code

### Composants Principaux

```
┌─────────────────────────────────────────────┐
│           MyApp (main.dart)                 │
│  ┌───────────────────────────────────────┐ │
│  │      ScheduleGuard                    │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │    InactivityGuard (NOUVEAU)    │ │ │
│  │  │  ┌───────────────────────────┐  │ │ │
│  │  │  │   ActivityDetector        │  │ │ │
│  │  │  │  ┌─────────────────────┐  │  │ │ │
│  │  │  │  │  MaterialApp.router │  │  │ │ │
│  │  │  │  └─────────────────────┘  │  │ │ │
│  │  │  └───────────────────────────┘  │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Fichiers Modifiés/Créés

| Fichier | Action | Description |
|---------|--------|-------------|
| `lib/providers/auth_provider.dart` | ✏️ Modifié | Timeout changé à 30 min, ajout callback warning |
| `lib/widgets/inactivity_guard.dart` | ✨ Créé | Gestion des dialogues d'avertissement |
| `lib/widgets/activity_detector.dart` | ✅ Existant | Détection d'activité (déjà implémenté) |
| `lib/main.dart` | ✏️ Modifié | Ajout de InactivityGuard dans l'arbre |

---

## 🔧 Détails Techniques

### 1. Enregistrement d'Activité

**Fichier** : `lib/providers/auth_provider.dart` (lignes 303-311)
```dart
void recordActivity() {
  if (!isAuthenticated) {
    return;
  }
  
  _lastActivityTime = DateTime.now();
  _warningShown = false; // Réinitialiser le flag d'avertissement
  debugPrint('Activité utilisateur enregistrée: ${_lastActivityTime}');
}
```

**Appelé par** : `lib/widgets/activity_detector.dart`
```dart
void _recordActivity(BuildContext context) {
  final authProvider = context.read<AuthProvider>();
  authProvider.recordActivity();
}
```

### 2. Vérification d'Inactivité

**Fichier** : `lib/providers/auth_provider.dart` (lignes 314-344)
```dart
void _checkInactivity() {
  // Récupérer la durée d'inactivité
  final inactiveDuration = now.difference(_lastActivityTime!);
  
  // Cas 1: Timeout atteint (30 minutes)
  if (inactiveDuration >= inactivityTimeout) {
    onInactivityTimeout!(); // Déclenche la déconnexion
  }
  // Cas 2: Avertissement (25 minutes)
  else if (!_warningShown && inactiveDuration >= (inactivityTimeout - warningBeforeTimeout)) {
    _warningShown = true;
    onInactivityWarning!(minutesRemaining); // Affiche l'avertissement
  }
}
```

### 3. Callbacks

**Configuration** : `lib/widgets/inactivity_guard.dart` (lignes 25-41)
```dart
// Callback pour l'avertissement
authProvider.onInactivityWarning = (minutesRemaining) {
  _showInactivityWarning(minutesRemaining);
};

// Callback pour la déconnexion
authProvider.onInactivityTimeout = () {
  _handleInactivityTimeout();
};
```

---

## 🧪 Tests

### Test 1 : Activité Normale
1. Connectez-vous à l'application
2. Utilisez l'application normalement (cliquez, scrollez)
3. **Résultat attendu** : Aucun avertissement, reste connecté

### Test 2 : Inactivité avec Intervention
1. Connectez-vous
2. **Ne touchez à rien pendant 25 minutes**
3. **Résultat attendu** : Dialogue d'avertissement apparaît
4. Cliquez sur "Rester connecté"
5. **Résultat attendu** : Timer réinitialisé, reste connecté

### Test 3 : Déconnexion Automatique
1. Connectez-vous
2. **Ne touchez à rien pendant 30 minutes**
3. **Résultat attendu** : Dialogue de déconnexion apparaît
4. Cliquez sur "Se reconnecter"
5. **Résultat attendu** : Redirection vers `/login`

### Test Rapide (pour développement)

Pour tester rapidement, modifiez temporairement les durées :

```dart
// Dans auth_provider.dart
static const Duration inactivityTimeout = Duration(minutes: 2);  // Au lieu de 30
static const Duration warningBeforeTimeout = Duration(seconds: 30); // Au lieu de 5 min
```

Puis :
1. Connectez-vous
2. Attendez 1 min 30 : Avertissement
3. Attendez 2 min : Déconnexion

**N'oubliez pas de remettre les vraies valeurs après !**

---

## 📊 Logs de Débogage

Le système affiche des logs dans la console :

```
✅ Connexion
flutter: Activité utilisateur enregistrée: 2025-10-23 04:30:00.000

⏱️ Vérifications périodiques (toutes les 1 min)
flutter: Vérification inactivité: 1 minutes
flutter: Vérification inactivité: 2 minutes
...
flutter: Vérification inactivité: 25 minutes

⚠️ Avertissement
flutter: Avertissement inactivité: 5 minutes restantes

❌ Déconnexion
flutter: Vérification inactivité: 30 minutes
flutter: Session expirée par inactivité (30 minutes)
```

---

## 🎯 Avantages

| Aspect | Bénéfice |
|--------|----------|
| 🔒 **Sécurité** | Empêche l'accès non autorisé si l'utilisateur oublie de se déconnecter |
| ⚠️ **Avertissement** | L'utilisateur est prévenu 5 minutes avant |
| 🔄 **Flexibilité** | Peut cliquer pour rester connecté |
| 🎨 **UX** | Dialogues clairs et professionnels |
| 📝 **Traçabilité** | Logs de débogage pour suivre l'activité |

---

## ⚙️ Personnalisation

### Modifier la Durée de Timeout

**Fichier** : `lib/providers/auth_provider.dart`

```dart
// Ligne 33
static const Duration inactivityTimeout = Duration(minutes: 30); // Changer ici

// Exemples :
Duration(minutes: 15)  // 15 minutes
Duration(minutes: 45)  // 45 minutes
Duration(hours: 1)     // 1 heure
```

### Modifier l'Avertissement

**Fichier** : `lib/providers/auth_provider.dart`

```dart
// Ligne 34
static const Duration warningBeforeTimeout = Duration(minutes: 5); // Changer ici

// Exemples :
Duration(minutes: 2)   // Avertir 2 min avant
Duration(minutes: 10)  // Avertir 10 min avant
```

### Désactiver pour les Superadmins

Le système peut être configuré pour ne pas déconnecter les superadmins :

```dart
// Dans auth_provider.dart, méthode startInactivityCheck()
void startInactivityCheck() {
  if (!isAuthenticated || _role == 'superadmin') {
    return; // Ne pas démarrer pour les superadmins
  }
  // ... reste du code
}
```

---

## 🐛 Dépannage

### Problème : L'avertissement ne s'affiche pas

**Solutions** :
1. Vérifier que `InactivityGuard` est bien dans `main.dart`
2. Vérifier les logs : `flutter: Vérification inactivité`
3. Vérifier que l'utilisateur est connecté

### Problème : Déconnexion trop rapide/lente

**Solutions** :
1. Vérifier `inactivityTimeout` dans `auth_provider.dart`
2. Vérifier les logs pour voir la durée réelle
3. S'assurer que l'horloge système est correcte

### Problème : L'activité n'est pas détectée

**Solutions** :
1. Vérifier que `ActivityDetector` enveloppe bien l'app
2. Vérifier les logs : `flutter: Activité utilisateur enregistrée`
3. Tester différents types d'interactions (clic, scroll, hover)

---

## 📋 Checklist de Validation

- [ ] L'utilisateur reçoit un avertissement après 25 minutes d'inactivité
- [ ] L'utilisateur peut cliquer sur "Rester connecté" pour réinitialiser le timer
- [ ] L'utilisateur est déconnecté après 30 minutes sans activité
- [ ] Le dialogue de déconnexion redirige vers `/login`
- [ ] Toute activité (clic, scroll, hover) réinitialise le timer
- [ ] Le flag d'avertissement est réinitialisé lors d'une activité
- [ ] Les logs de débogage s'affichent correctement
- [ ] Le système fonctionne sur Web, Mobile et Desktop

---

## 🚀 Résultat Final

✅ **Déconnexion automatique après 30 minutes d'inactivité**  
✅ **Avertissement à 25 minutes**  
✅ **Détection complète d'activité**  
✅ **Interface utilisateur claire**  
✅ **Sécurité renforcée**  

**L'application est maintenant conforme aux normes de sécurité avec une gestion automatique des sessions inactives !** 🔒

---

**Date** : 23 octobre 2025  
**Version** : 1.0 - Système de Déconnexion Automatique
