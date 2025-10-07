# Documentation : Système de Rapport d'Accidents avec Parties Impliquées

## Vue d'ensemble

Ce système remplace l'ancien concept de "Véhicules impliqués" par un système plus complet de **"Parties impliquées"** avec maximum 4 parties, incluant les passagers, photos, et analyse de responsabilité.

---

## 📋 Fonctionnalités principales

### 1. **Parties impliquées (max 4)**
- Chaque partie peut avoir un véhicule associé
- Rôle de la partie : Responsable, Victime, Témoin matériel, Autre
- Informations du conducteur (nom et état)
- Liste des passagers avec leur état (indemne, blessé léger/grave, décédé)
- Photos spécifiques à chaque partie
- Dommages du véhicule
- Notes additionnelles

### 2. **Services de l'État présents**
- Police
- Ambulance
- Pompiers
- Gendarmerie
- Protection civile

### 3. **Analyse de responsabilité**
- Sélection de la partie responsable
- Explication détaillée de la faute
- Raison juridique/factuelle de la responsabilité

### 4. **Gestion complète**
- Photos principales de l'accident
- Témoins (inchangé)
- Gravité de l'accident
- Lieu et description
- Date et heure précises

---

## 🗄️ Structure de la base de données

### Table `parties_impliquees`
```sql
- id (INT PRIMARY KEY)
- accident_id (FK vers accidents)
- vehicule_plaque_id (FK vers vehicule_plaque, nullable)
- role (ENUM: responsable, victime, temoin_materiel, autre)
- conducteur_nom (VARCHAR)
- conducteur_etat (ENUM: indemne, blesse_leger, blesse_grave, decede)
- dommages_vehicule (TEXT)
- photos (TEXT - JSON array)
- notes (TEXT)
- created_at, updated_at
```

### Table `passagers_partie`
```sql
- id (INT PRIMARY KEY)
- partie_id (FK vers parties_impliquees)
- nom (VARCHAR)
- etat (ENUM: indemne, blesse_leger, blesse_grave, decede)
- created_at
```

### Table `accidents` (colonnes ajoutées)
```sql
- services_etat_present (TEXT - JSON array)
- partie_fautive_id (INT - référence à parties_impliquees.id)
- raison_faute (TEXT)
- updated_at
```

---

## 🚀 Installation

### 1. Exécuter le script d'initialisation de la base de données
```bash
php api/database/setup_parties_impliquees.php
```

Ce script va :
- ✅ Créer la table `parties_impliquees`
- ✅ Créer la table `passagers_partie`
- ✅ Ajouter les colonnes manquantes dans `accidents`
- ✅ Créer les dossiers uploads nécessaires

### 2. Vérifier les dossiers uploads
Les dossiers suivants doivent exister :
- `/uploads/parties_impliquees/` - Photos des parties
- `/uploads/accidents/` - Photos principales de l'accident

---

## 📱 Interface Flutter

### Modals créées

#### 1. **PartieImpliqueeModal**
**Fichier :** `/lib/widgets/partie_impliquee_modal.dart`

**Fonctionnalités :**
- Recherche de véhicule par plaque
- Création rapide de véhicule si non trouvé
- Sélection du rôle de la partie
- Informations du conducteur (nom + état)
- Ajout de passagers avec leur état
- Upload de photos multiples pour la partie
- Description des dommages
- Notes additionnelles

#### 2. **RapportAccidentModal** (mise à jour)
**Fichier :** `/lib/widgets/rapport_accident_modal.dart`

**Nouvelles sections :**
- **Parties impliquées** : Liste avec compteur (X/4)
- **Services de l'État présents** : Chips sélectionnables
- **Responsabilité** : Dropdown + champ explication

**Contraintes :**
- Maximum 4 parties impliquées
- Au moins une partie pour définir la responsabilité

### Modèles Flutter

**Fichier :** `/lib/models/accident_models.dart`

**Nouveaux modèles :**
- `RolePartie` (enum)
- `EtatPersonne` (enum)
- `Passager`
- `PartieImpliquee`
- `Accident` (enrichi avec nouvelles propriétés)

---

## 🔌 API Backend

### Endpoint principal
**POST** `/create-accident`

**Contrôleur :** `AccidentRapportController.php`

### Données attendues (multipart/form-data)

#### Champs principaux
- `date_accident` - ISO 8601 format
- `lieu` - Lieu de l'accident
- `gravite` - materiel, corporel, mortel
- `description` - Description détaillée
- `temoins_data` - JSON array des témoins
- `parties_data` - JSON array des parties impliquées
- `services_etat_present` - JSON array des services présents
- `partie_fautive_id` - Index de la partie responsable (1-based)
- `raison_faute` - Explication de la responsabilité

#### Fichiers
- `images[]` - Photos principales de l'accident
- `partie_0_photos[]` - Photos de la partie 0
- `partie_1_photos[]` - Photos de la partie 1
- `partie_2_photos[]` - Photos de la partie 2
- `partie_3_photos[]` - Photos de la partie 3

### Format JSON des parties
```json
{
  "vehicule_plaque_id": 123,
  "role": "responsable",
  "conducteur_nom": "Jean Dupont",
  "conducteur_etat": "indemne",
  "passagers": "[{\"nom\":\"Marie\",\"etat\":\"blesse_leger\"}]",
  "dommages_vehicule": "Pare-choc avant endommagé",
  "notes": "Véhicule immatriculé en France"
}
```

### Processus de création
1. **Transaction SQL** démarrée
2. **Création de l'accident** principal
3. **Upload des images** principales
4. **Création des témoins**
5. **Création des parties impliquées** :
   - Upload des photos de chaque partie
   - Création de la partie dans `parties_impliquees`
   - Création des passagers dans `passagers_partie`
6. **Mise à jour de la partie fautive** si spécifiée
7. **Commit de la transaction**

En cas d'erreur à n'importe quelle étape : **Rollback complet**

---

## 🎨 Interface utilisateur

### Section Parties impliquées
```
┌──────────────────────────────────────────────────┐
│ Parties impliquées (max 4)                       │
│ [+ Ajouter une partie (2/4)]                     │
│                                                   │
│ ┌────────────────────────────────────────────┐   │
│ │ 🚗 AB-123-CD (Toyota Corolla)             │   │
│ │ Rôle: Responsable | Conducteur: Jean      │   │
│ │ Passagers: 2 | Photos: 3              [×] │   │
│ └────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
```

### Section Services de l'État
```
┌──────────────────────────────────────────────────┐
│ Services de l'État présents                      │
│ [Police] [Ambulance] [Pompiers] [...]           │
│ (chips sélectionnables)                          │
└──────────────────────────────────────────────────┘
```

### Section Responsabilité
```
┌──────────────────────────────────────────────────┐
│ Responsabilité                                   │
│ Partie responsable: [Dropdown]                   │
│ Raison: [TextArea multiligne]                    │
└──────────────────────────────────────────────────┘
```

---

## ✅ Workflow complet

### Côté utilisateur
1. Cliquer sur "Créer un rapport d'accident"
2. Remplir les informations de base (date, lieu, gravité, description)
3. Ajouter des photos de la scène
4. Ajouter des témoins (optionnel)
5. **Ajouter les parties impliquées** (1 à 4) :
   - Pour chaque partie :
     - Rechercher le véhicule par plaque
     - Définir le rôle
     - Renseigner le conducteur et son état
     - Ajouter les passagers
     - Uploader les photos de cette partie
6. **Sélectionner les services présents** (chips)
7. **Définir la responsabilité** :
   - Choisir la partie fautive
   - Expliquer pourquoi
8. Enregistrer le rapport

### Côté backend
1. Validation des données
2. Début de transaction
3. Création de l'accident
4. Upload de toutes les images
5. Création des enregistrements liés
6. Commit
7. Réponse JSON avec ID de l'accident

---

## 🔒 Sécurité et validation

### Côté Flutter
- ✅ Validation des champs requis
- ✅ Limite de 4 parties maximum
- ✅ Vérification de l'existence des véhicules
- ✅ Format de date ISO 8601
- ✅ Gestion d'erreurs avec try/catch

### Côté Backend
- ✅ Validation des champs obligatoires
- ✅ Transactions SQL (atomicité)
- ✅ Upload sécurisé des fichiers
- ✅ Gestion des erreurs avec rollback
- ✅ Validation des ENUM values
- ✅ Protection contre les injections SQL (PDO prepared statements)

---

## 📊 Enums et valeurs possibles

### RolePartie
- `responsable` - Partie responsable de l'accident
- `victime` - Partie victime
- `temoin_materiel` - Témoin matériel (véhicule non impliqué directement)
- `autre` - Autre rôle

### EtatPersonne
- `indemne` - Aucune blessure
- `blesse_leger` - Blessures légères
- `blesse_grave` - Blessures graves
- `decede` - Décédé

### AccidentGravite
- `materiel` - Dégâts matériels uniquement
- `corporel` - Blessures corporelles
- `mortel` - Au moins un décès

---

## 🧪 Tests

### Pour tester l'installation
```bash
# 1. Exécuter le script d'installation
php api/database/setup_parties_impliquees.php

# 2. Vérifier les tables créées
mysql -u root control_routier -e "SHOW TABLES LIKE 'parties%'"

# 3. Vérifier les colonnes ajoutées
mysql -u root control_routier -e "DESCRIBE accidents"
```

### Pour tester l'API
```bash
# Utiliser Postman ou curl pour tester l'endpoint /create-accident
# Voir la documentation API ci-dessus pour le format des données
```

---

## 📝 Notes importantes

1. **Compatibilité Web** : Le système utilise `Image.memory()` avec `XFile.readAsBytes()` pour être compatible Flutter Web

2. **Gestion des photos** : Les photos sont stockées séparément :
   - Photos principales : `/uploads/accidents/`
   - Photos des parties : `/uploads/parties_impliquees/`

3. **Limitation des parties** : Maximum 4 parties pour éviter la surcharge de données

4. **Ancien système** : Les anciennes tables `accident_vehicules` peuvent coexister pour compatibilité

5. **Responsabilité** : La partie fautive est optionnelle (peut rester "Indéterminé")

---

## 🔄 Migration depuis l'ancien système

Si vous avez des données dans `accident_vehicules`, vous pouvez les migrer vers `parties_impliquees` :

```sql
INSERT INTO parties_impliquees 
  (accident_id, vehicule_plaque_id, role, dommages_vehicule, notes, created_at)
SELECT 
  accident_id,
  vehicule_plaque_id,
  CASE 
    WHEN role = 'responsable' THEN 'responsable'
    WHEN role = 'victime' THEN 'victime'
    ELSE 'autre'
  END as role,
  dommages,
  notes,
  created_at
FROM accident_vehicules;
```

---

## 🆘 Dépannage

### Erreur : "Table doesn't exist"
→ Exécuter `php api/database/setup_parties_impliquees.php`

### Erreur : "Cannot add foreign key constraint"
→ Vérifier que les tables `accidents` et `vehicule_plaque` existent

### Erreur upload : "Failed to move uploaded file"
→ Vérifier les permissions des dossiers uploads (chmod 777)

### Erreur : "Maximum 4 parties atteint"
→ C'est normal, limite volontaire pour l'interface utilisateur

---

## 👥 Auteur

Implémenté le 06/10/2025 pour le système BCR (Bureau de Contrôle Routier)

---

## 📄 Licence

Propriétaire - Usage interne uniquement
