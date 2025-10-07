# 🚀 Installation Rapide - Système de Rapport d'Accidents avec Parties Impliquées

## ✅ Étapes d'installation (5 minutes)

### 1️⃣ Initialiser la base de données
```bash
cd /Users/apple/Documents/dev/flutter/bcr/api/database
php setup_parties_impliquees.php
```

**Résultat attendu :**
```
=== Initialisation des tables parties impliquées ===

✓ Connexion à la base de données réussie

Création de la table parties_impliquees...
✓ Table parties_impliquees créée avec succès

Création de la table passagers_partie...
✓ Table passagers_partie créée avec succès

Mise à jour de la table accidents...
✓ Colonne services_etat_present ajoutée
✓ Colonne partie_fautive_id ajoutée
✓ Colonne raison_faute ajoutée
✓ Colonne updated_at ajoutée

Création des dossiers uploads...
✓ Dossier créé: parties_impliquees
✓ Dossier créé: accidents

=== ✓ Initialisation terminée avec succès ===
```

### 2️⃣ Vérifier les fichiers créés

**Backend :**
- ✅ `/api/controllers/AccidentRapportController.php`
- ✅ `/api/database/parties_impliquees.sql`
- ✅ `/api/database/setup_parties_impliquees.php`
- ✅ `/api/routes/index.php` (endpoint `/create-accident` ajouté)

**Frontend :**
- ✅ `/lib/models/accident_models.dart` (enrichi)
- ✅ `/lib/widgets/partie_impliquee_modal.dart`
- ✅ `/lib/widgets/rapport_accident_modal.dart` (mis à jour)
- ✅ `/lib/services/accident_api_service.dart` (mis à jour)
- ✅ `/lib/widgets/temoin_modal.dart` (corrigé)

**Documentation :**
- ✅ `/RAPPORT_ACCIDENT_PARTIES_IMPLIQUEES.md`
- ✅ `/INSTALLATION_RAPPORT_ACCIDENT.md` (ce fichier)

### 3️⃣ Redémarrer le serveur PHP
```bash
# Si vous utilisez le serveur PHP intégré
cd /Users/apple/Documents/dev/flutter/bcr/api
php -S localhost:8000 routes/index.php

# Ou redémarrer votre serveur Apache/Nginx
```

### 4️⃣ Tester l'application Flutter

**Hot reload :**
```bash
# Dans votre terminal Flutter
r
```

**Ou redémarrer complètement :**
```bash
flutter run
```

---

## 🧪 Tests de validation

### Test 1 : Vérifier les tables
```sql
-- Connectez-vous à MySQL
mysql -u root control_routier

-- Vérifiez les tables
SHOW TABLES LIKE '%partie%';
-- Doit afficher : parties_impliquees, passagers_partie

-- Vérifiez les colonnes de accidents
DESCRIBE accidents;
-- Doit afficher les colonnes : services_etat_present, partie_fautive_id, raison_faute, updated_at
```

### Test 2 : Tester l'endpoint API
```bash
# Test basique avec curl
curl -X POST http://localhost:8000/create-accident \
  -F "date_accident=2025-10-06T12:00:00" \
  -F "lieu=Avenue de la Liberté" \
  -F "gravite=materiel" \
  -F "description=Test accident"

# Devrait retourner un JSON avec success: true
```

### Test 3 : Utiliser l'interface Flutter

1. **Ouvrir la modal de création d'accident**
2. **Remplir les informations de base** :
   - Date/heure : Utiliser le calendrier
   - Lieu : Ex. "Avenue Mobutu, Lubumbashi"
   - Gravité : Sélectionner (Matériel/Corporel/Mortel)
   - Description : Ex. "Collision entre deux véhicules"

3. **Ajouter des photos** (optionnel)

4. **Ajouter des témoins** (optionnel)

5. **Ajouter une partie impliquée** :
   - Cliquer sur "Ajouter une partie"
   - Rechercher un véhicule par plaque
   - Remplir les informations du conducteur
   - Ajouter des passagers
   - Uploader des photos
   - Valider

6. **Répéter pour d'autres parties** (max 4)

7. **Sélectionner les services de l'État présents**

8. **Définir la responsabilité** :
   - Choisir la partie fautive
   - Expliquer la raison

9. **Enregistrer le rapport**

---

## 🎯 Points de contrôle

### ✅ Backend fonctionnel
- [ ] Tables créées dans MySQL
- [ ] Dossiers uploads créés avec permissions 777
- [ ] Endpoint `/create-accident` accessible
- [ ] Pas d'erreurs PHP dans les logs

### ✅ Frontend fonctionnel
- [ ] Aucune erreur de compilation Dart
- [ ] Modal s'ouvre sans erreur
- [ ] Recherche de véhicule fonctionne
- [ ] Upload de photos fonctionne
- [ ] Notifications toastification s'affichent

### ✅ Flux complet
- [ ] Création d'un rapport avec 1 partie → Succès
- [ ] Création d'un rapport avec 4 parties → Succès
- [ ] Tentative de 5ème partie → Message d'avertissement
- [ ] Vérification dans la base de données → Données correctes

---

## 🐛 Dépannage rapide

### Erreur : "Table 'parties_impliquees' doesn't exist"
**Solution :**
```bash
php api/database/setup_parties_impliquees.php
```

### Erreur : "Failed to move uploaded file"
**Solution :**
```bash
chmod -R 777 uploads/
```

### Erreur : "Call to undefined method Database::getConnection()"
**Solution :** Déjà corrigé dans `AccidentRapportController.php`

### Erreur Flutter : "The named parameter 'vehiculesImpliques' isn't defined"
**Solution :** Déjà corrigé - utilise `partiesImpliquees` maintenant

### Erreur : "LienAccident.temoinDirect doesn't exist"
**Solution :** Déjà corrigé - utilise `LienAccident.passant`

---

## 📊 Structure des données créées

Après création d'un rapport avec 2 parties :

```
accidents
├─ id: 1
├─ date_accident: 2025-10-06 12:00:00
├─ lieu: Avenue Mobutu
├─ gravite: corporel
├─ description: Collision...
├─ services_etat_present: ["Police","Ambulance"]
├─ partie_fautive_id: 1
└─ raison_faute: Non-respect du stop

parties_impliquees
├─ id: 1 (Responsable)
│  ├─ accident_id: 1
│  ├─ vehicule_plaque_id: 123
│  ├─ role: responsable
│  ├─ conducteur_nom: Jean Dupont
│  ├─ conducteur_etat: indemne
│  ├─ photos: ["/uploads/parties_impliquees/abc123.jpg"]
│  └─ passagers_partie
│     ├─ id: 1 → nom: Marie, etat: blesse_leger
│     └─ id: 2 → nom: Paul, etat: indemne
│
└─ id: 2 (Victime)
   ├─ accident_id: 1
   ├─ vehicule_plaque_id: 456
   ├─ role: victime
   ├─ conducteur_nom: Alice Martin
   └─ conducteur_etat: blesse_grave
```

---

## 🎓 Formations utilisateurs

### Pour les agents
1. **Arrivée sur les lieux** → Ouvrir l'app
2. **Créer rapport** → Remplir infos de base
3. **Photographier** → Scène + chaque véhicule
4. **Identifier parties** → Ajouter chaque véhicule impliqué
5. **Interroger** → Ajouter témoins
6. **Analyser** → Définir responsabilité
7. **Enregistrer** → Validation finale

### Pour les superviseurs
- Consulter les rapports
- Vérifier les photos
- Valider les responsabilités
- Exporter en PDF (à venir)

---

## 📞 Support

En cas de problème persistant :
1. Vérifier les logs PHP : `/var/log/apache2/error.log`
2. Vérifier la console Flutter : Messages d'erreur
3. Tester l'API avec Postman
4. Consulter `RAPPORT_ACCIDENT_PARTIES_IMPLIQUEES.md`

---

## 🎉 Fonctionnalité complète !

Votre système de rapport d'accidents avec parties impliquées est maintenant **opérationnel** !

**Prochaines étapes suggérées :**
- [ ] Tester avec des données réelles
- [ ] Former les utilisateurs
- [ ] Ajouter export PDF des rapports
- [ ] Ajouter statistiques sur les accidents
- [ ] Implémenter la modification des rapports

---

**Date de mise en production :** 06/10/2025  
**Version :** 2.0 - Système Parties Impliquées
