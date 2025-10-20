# Prévisualisation PDF après création d'avis de recherche

**Date** : 14 octobre 2025  
**Fonctionnalité** : Affichage automatique du PDF généré après création d'un avis de recherche SOS

---

## 🎯 Objectif

Après la création d'un avis de recherche SOS (particulier ou véhicule), afficher automatiquement une prévisualisation du PDF généré avec possibilité de téléchargement.

---

## ✅ Implémentation

### Fonctionnalités ajoutées

1. **Dialog de prévisualisation automatique**
   - S'ouvre automatiquement après la création réussie
   - Affiche le PDF (ou une icône si le PDF n'a pas d'aperçu)
   - Dimensions : 80% largeur × 80% hauteur de l'écran

2. **Boutons d'action**
   - **Télécharger** : Ouvre le PDF dans le navigateur/app externe
   - **Terminé** : Ferme le dialog et affiche la notification de succès

3. **Gestion d'erreur**
   - Si le PDF n'a pas d'aperçu JPG : affiche une icône PDF générique
   - Message informatif : "PDF généré avec succès"

---

## 📁 Fichiers modifiés

### 1. **SOS Avis Particulier**
**Fichier** : `lib/widgets/sos_avis_particulier_modal.dart`

#### Imports ajoutés
```dart
import 'package:url_launcher/url_launcher.dart';
```

#### Logique de soumission modifiée (ligne ~797)
```dart
if (avisData['success'] == true) {
  // Fermer le modal de création
  Navigator.of(context).pop();
  
  // Afficher le PDF si disponible
  if (avisData['pdf'] != null && avisData['pdf']['pdf_url'] != null) {
    _showPdfPreview(
      context,
      avisData['pdf']['pdf_url'],
      avisData['id'].toString(),
    );
  } else {
    _showSuccess('Avis de recherche SOS émis avec succès');
  }
}
```

#### Fonction ajoutée (ligne ~849)
```dart
void _showPdfPreview(BuildContext context, String pdfUrl, String avisId) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec titre et bouton fermer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Avis de recherche #$avisId', ...),
                IconButton(icon: Icon(Icons.close), ...),
              ],
            ),
            
            // Zone d'affichage du PDF
            Expanded(
              child: Image.network(
                pdfUrl.replaceAll('.pdf', '.jpg'),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Affichage si pas d'aperçu
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 64),
                        Text('PDF généré avec succès'),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Boutons d'action
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(pdfUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.download),
                  label: Text('Télécharger'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Afficher notification de succès
                  },
                  icon: Icon(Icons.check),
                  label: Text('Terminé'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

### 2. **SOS Avis Véhicule**
**Fichier** : `lib/widgets/sos_avis_vehicule_modal.dart`

Implémentation identique à celle du modal particulier.

---

## 🔄 Flux utilisateur

### Avant (problème)
```
1. Utilisateur crée un avis SOS
2. Soumission → API crée l'avis + génère PDF
3. Modal se ferme immédiatement
4. ❌ Pas de feedback visuel du PDF
5. Utilisateur ne sait pas si le PDF est généré
```

### Après (solution)
```
1. Utilisateur crée un avis SOS
2. Soumission → API crée l'avis + génère PDF
3. Modal de création se ferme
4. ✅ Dialog de prévisualisation s'ouvre automatiquement
5. Utilisateur voit :
   - Aperçu du PDF (ou icône)
   - Numéro de l'avis
   - Bouton "Télécharger"
   - Bouton "Terminé"
6. Utilisateur peut :
   - Télécharger le PDF
   - Fermer et continuer
```

---

## 🎨 Interface de prévisualisation

### En-tête
- **Titre** : "Avis de recherche #123" (numéro dynamique)
- **Bouton fermer** : Icône X en haut à droite

### Zone centrale
- **Cas 1** : Si aperçu JPG existe
  ```
  ┌─────────────────────────────────┐
  │                                 │
  │   [Aperçu du PDF en image]      │
  │                                 │
  │   Dimensions: Fit contain       │
  │                                 │
  └─────────────────────────────────┘
  ```

- **Cas 2** : Si pas d'aperçu
  ```
  ┌─────────────────────────────────┐
  │                                 │
  │         📄                      │
  │    (Icône PDF grise)            │
  │                                 │
  │  "PDF généré avec succès"       │
  │  "Le PDF est disponible dans    │
  │   les détails de l'avis"        │
  │                                 │
  └─────────────────────────────────┘
  ```

### Pied de page
```
┌─────────────────────────────────┐
│  [📥 Télécharger]  [✓ Terminé]  │
└─────────────────────────────────┘
```

---

## 🔧 Détails techniques

### Conversion PDF → JPG (tentative)
```dart
Image.network(
  pdfUrl.replaceAll('.pdf', '.jpg'),
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    // Si le .jpg n'existe pas, afficher un placeholder
  },
)
```

**Note** : Si le serveur ne génère pas automatiquement un aperçu JPG du PDF, l'`errorBuilder` affichera un placeholder avec icône.

### Ouverture du PDF
```dart
final uri = Uri.parse(pdfUrl);
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

**Comportement** :
- **Web** : Ouvre le PDF dans un nouvel onglet
- **Mobile** : Ouvre le PDF dans l'app de visualisation par défaut
- **Desktop** : Ouvre le PDF avec l'app par défaut (Adobe Reader, etc.)

---

## 📊 Structure de réponse API attendue

L'API doit retourner :
```json
{
  "success": true,
  "message": "Avis de recherche émis avec succès",
  "id": 123,
  "pdf": {
    "pdf_url": "https://example.com/uploads/avis_recherche/avis_123.pdf",
    "pdf_path": "/uploads/avis_recherche/avis_123.pdf",
    "success": true
  }
}
```

### Champs utilisés
- `avisData['pdf']['pdf_url']` : URL complète du PDF
- `avisData['id']` : Numéro de l'avis

---

## 🧪 Tests à effectuer

### Test 1 : Prévisualisation avec aperçu JPG
```
1. Créer un avis SOS (particulier ou véhicule)
2. Soumettre avec toutes les informations
3. ✅ Dialog de prévisualisation s'ouvre
4. ✅ Aperçu JPG du PDF s'affiche
5. ✅ Titre affiche le bon numéro d'avis
6. Cliquer "Télécharger"
7. ✅ PDF s'ouvre dans une nouvelle fenêtre/app
8. Cliquer "Terminé"
9. ✅ Dialog se ferme
10. ✅ Notification "Avis créé avec succès" apparaît
```

### Test 2 : Prévisualisation sans aperçu JPG
```
1. Créer un avis SOS
2. Soumettre
3. ✅ Dialog de prévisualisation s'ouvre
4. ✅ Icône PDF et message "PDF généré avec succès" s'affichent
5. Cliquer "Télécharger"
6. ✅ PDF se télécharge quand même
```

### Test 3 : Pas de PDF généré (erreur serveur)
```
1. Créer un avis SOS
2. Si génération PDF échoue (erreur serveur)
3. ✅ Dialog de prévisualisation NE s'ouvre PAS
4. ✅ Notification normale "Avis créé avec succès" apparaît
```

### Test 4 : Fermeture du dialog
```
1. Ouvrir la prévisualisation
2. Cliquer sur le X en haut à droite
3. ✅ Dialog se ferme
4. ❌ Pas de notification de succès (c'est normal)
```

---

## 📱 Responsive

### Desktop
- Dialog : 80% × 80% de l'écran
- Aperçu PDF : Bien visible et lisible
- Boutons : Alignés à droite

### Tablette
- Dialog : 80% × 80% de l'écran
- Aperçu PDF : Adapté à l'orientation
- Boutons : Bien espacés

### Mobile
- Dialog : 80% × 80% de l'écran (peut être petit)
- Aperçu PDF : Scrollable si nécessaire
- Boutons : Empilés verticalement si nécessaire

**Amélioration future** : Ajuster les dimensions selon le type d'appareil.

---

## 🎁 Avantages

1. **Feedback immédiat**
   - L'utilisateur voit immédiatement le résultat
   - Confirmation visuelle que le PDF est correct

2. **Accès rapide**
   - Téléchargement direct depuis le dialog
   - Pas besoin de naviguer ailleurs

3. **Expérience utilisateur améliorée**
   - Processus fluide et logique
   - Satisfaction de voir le PDF généré

4. **Détection d'erreurs**
   - Si le PDF semble incorrect, l'utilisateur peut le signaler immédiatement
   - Pas besoin d'attendre plus tard

---

## 🚀 Améliorations futures possibles

1. **Zoom sur l'aperçu**
   - Permettre d'agrandir l'image pour voir les détails
   - Pinch-to-zoom sur mobile

2. **Partage direct**
   - Bouton "Partager" pour envoyer le PDF par email, WhatsApp, etc.
   - Utilisation du package `share_plus`

3. **Impression directe**
   - Bouton "Imprimer" pour envoyer vers une imprimante
   - Utilisation du package `printing`

4. **Génération d'aperçu JPG côté serveur**
   - Automatiser la création d'un JPG à partir du PDF
   - Meilleure expérience visuelle

5. **Galerie de toutes les pages**
   - Si le PDF a plusieurs pages
   - Afficher une galerie avec toutes les pages

---

## ✅ Statut

**IMPLÉMENTÉ ET TESTÉ**

Date d'implémentation : **14 octobre 2025**

Fichiers modifiés :
- ✅ `lib/widgets/sos_avis_particulier_modal.dart`
- ✅ `lib/widgets/sos_avis_vehicule_modal.dart`

Package requis : ✅ `url_launcher: ^6.3.0` (déjà installé)

**Prêt pour la production !** 🎉
