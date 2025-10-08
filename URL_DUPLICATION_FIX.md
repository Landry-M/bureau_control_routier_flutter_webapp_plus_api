# 🔧 Correction de la duplication d'URLs

## 🚨 Problème identifié

Les URLs des fichiers PDF et images contenaient une duplication :

**URL incorrecte** :
```
http://localhost:8000/api/routes/index.php/api/uploads/contraventions/contravention_22_2025-10-08_02-25-05.pdf
```

**URL correcte** :
```
http://localhost:8000/api/uploads/contraventions/contravention_22_2025-10-08_02-25-05.pdf
```

## 🔍 Cause du problème

Le problème venait de l'utilisation de `ApiConfig.baseUrl` au lieu de `ApiConfig.imageBaseUrl` pour construire les URLs de fichiers statiques.

### Configuration dans `api_config.dart` :

```dart
// Pour les appels API
static String get baseUrl => 'http://localhost:8000/api/routes/index.php';

// Pour les fichiers statiques (images, PDF)
static String get imageBaseUrl => 'http://localhost:8000';
```

### Construction incorrecte (AVANT) :

```dart
// Dans entreprise_details_modal.dart et particulier_details_modal.dart
pdfUrl = '${ApiConfig.baseUrl}$pathStr';
// Résultat: http://localhost:8000/api/routes/index.php/api/uploads/...
```

### Construction correcte (APRÈS) :

```dart
// Dans entreprise_details_modal.dart et particulier_details_modal.dart
pdfUrl = '${ApiConfig.imageBaseUrl}$pathStr';
// Résultat: http://localhost:8000/api/uploads/...
```

## ✅ Corrections apportées

### 1. **entreprise_details_modal.dart**

**Méthode** : `_viewPdf()`

```dart
// AVANT
pdfUrl = '${ApiConfig.baseUrl}$pathStr';

// APRÈS
pdfUrl = '${ApiConfig.imageBaseUrl}$pathStr';
```

### 2. **particulier_details_modal.dart**

**Méthode** : `_viewPdf()`

```dart
// AVANT
pdfUrl = '${ApiConfig.baseUrl}$pathStr';

// APRÈS
pdfUrl = '${ApiConfig.imageBaseUrl}$pathStr';
```

## 📋 Vérification des autres composants

### ✅ **Composants déjà corrects** :

| Fichier | Méthode | URL utilisée | Statut |
|---------|---------|--------------|---------|
| `edit_particulier_modal.dart` | Affichage images | `ApiConfig.imageBaseUrl` | ✅ Correct |
| `particulier_details_modal.dart` | Affichage images | `ApiConfig.imageBaseUrl` | ✅ Correct |
| `accidents_screen.dart` | Affichage images | `ApiConfig.imageBaseUrl` | ✅ Correct |
| `vehicule_details_modal.dart` | Affichage images | `imageUrl` direct | ✅ Correct |

### ✅ **Appels API (doivent utiliser baseUrl)** :

| Fichier | Type | URL utilisée | Statut |
|---------|------|--------------|---------|
| `contravention_preview_modal.dart` | API call | `ApiConfig.baseUrl` | ✅ Correct |
| `vehicule_details_modal.dart` | API call | `ApiConfig.baseUrl` | ✅ Correct |
| `global_search_service.dart` | API call | `ApiConfig.baseUrl` | ✅ Correct |
| Tous les providers | API calls | `ApiConfig.baseUrl` | ✅ Correct |

## 🎯 Règles à suivre

### **Pour les appels API** :
```dart
// ✅ CORRECT
final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/endpoint'));
```

### **Pour les fichiers statiques** :
```dart
// ✅ CORRECT - Images
Image.network('${ApiConfig.imageBaseUrl}$imagePath')

// ✅ CORRECT - PDF
final pdfUrl = '${ApiConfig.imageBaseUrl}$pdfPath';
```

### **À éviter** :
```dart
// ❌ INCORRECT - Ne jamais faire cela pour les fichiers statiques
final fileUrl = '${ApiConfig.baseUrl}$filePath';
```

## 🧪 Test de validation

### Script de test créé :
```bash
php test_url_construction.php
```

Ce script :
- ✅ Crée une contravention de test
- ✅ Génère un PDF
- ✅ Vérifie le format des URLs
- ✅ Détecte les duplications
- ✅ Teste différentes constructions d'URLs

### Résultats attendus :
```
✅ Format URL correct: commence par /api/uploads/contraventions/
✅ Pas de duplication /api/routes/index.php
✅ URL correcte (avec imageBaseUrl)
❌ PROBLÈME: Duplication détectée! (avec baseUrl)
```

## 🌐 Impact sur les environnements

### **Développement (localhost)** :
- ✅ `imageBaseUrl` = `http://localhost:8000`
- ✅ `baseUrl` = `http://localhost:8000/api/routes/index.php`

### **Production (heaventech.net)** :
- ✅ `imageBaseUrl` = `https://heaventech.net` ou URL relative
- ✅ `baseUrl` = `https://heaventech.net/api/routes/index.php` ou URL relative

### **Mobile (Android/iOS)** :
- ✅ URLs absolues avec IP ou domaine approprié

## 📊 Avant/Après

### **AVANT (avec duplication)** :
```
http://localhost:8000/api/routes/index.php/api/uploads/contraventions/file.pdf
                      ^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^
                      Partie API           Partie fichier
                      (en trop)
```

### **APRÈS (correct)** :
```
http://localhost:8000/api/uploads/contraventions/file.pdf
                      ^^^^^^^^
                      Partie fichier uniquement
```

## ✅ Validation finale

- [x] **URLs PDF** : Corrigées dans les deux modals
- [x] **URLs images** : Déjà correctes partout
- [x] **Appels API** : Utilisent correctement `baseUrl`
- [x] **Test de validation** : Script créé et fonctionnel
- [x] **Documentation** : Complète avec exemples

## 🎉 Résultat

Les URLs des contraventions PDF sont maintenant correctement formées :
- ❌ `http://localhost:8000/api/routes/index.php/api/uploads/contraventions/file.pdf`
- ✅ `http://localhost:8000/api/uploads/contraventions/file.pdf`

Le problème de duplication est résolu pour tous les fichiers statiques !
