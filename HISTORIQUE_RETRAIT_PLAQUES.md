# Historique des Retraits de Plaques

## Vue d'ensemble

Cette fonctionnalité permet d'enregistrer et de consulter l'historique complet de tous les retraits de plaques d'immatriculation effectués sur les véhicules.

## Fonctionnalités implémentées

### 1. ✅ Table de base de données

**Table : `historique_retrait_plaques`**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | INT (PK) | Identifiant unique |
| `vehicule_plaque_id` | INT (FK) | Référence au véhicule |
| `ancienne_plaque` | VARCHAR(50) | Numéro de plaque retirée |
| `date_retrait` | DATETIME | Date et heure du retrait |
| `motif` | VARCHAR(255) | Motif du retrait (optionnel) |
| `observations` | TEXT | Observations supplémentaires (optionnel) |
| `username` | VARCHAR(100) | Utilisateur ayant effectué le retrait |
| `created_at` | TIMESTAMP | Date de création de l'enregistrement |

**Indexes :**
- `idx_vehicule_plaque_id` : Index sur vehicule_plaque_id
- `idx_date_retrait` : Index sur date_retrait

**Contrainte :**
- Foreign Key vers `vehicule_plaque(id)` avec `ON DELETE CASCADE`

### 2. ✅ Backend API

#### Contrôleur : `HistoriqueRetraitPlaqueController`

**Méthodes disponibles :**

```php
// Créer un enregistrement d'historique
create($vehiculePlaqueId, $anciennePlaque, $dateRetrait, $motif, $observations, $username)

// Récupérer l'historique pour un véhicule
getByVehiculeId($vehiculePlaqueId)

// Récupérer tous les historiques avec pagination
getAll($limit = 20, $offset = 0)
```

#### Endpoint API

**GET `/vehicule/{id}/historique-retraits`**

**Paramètres :**
- `id` : ID du véhicule (dans l'URL)
- `username` : Nom de l'utilisateur (query parameter, optionnel)

**Réponse :**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "vehicule_plaque_id": 123,
      "ancienne_plaque": "AB-1234-CD",
      "date_retrait": "2024-10-06 14:30:00",
      "motif": "Plaque endommagée",
      "observations": "Remplacement nécessaire",
      "username": "admin",
      "created_at": "2024-10-06 14:30:00"
    }
  ]
}
```

#### Logging automatique

- Consultation de l'historique → Enregistré dans la table `activites`
- Action : "Consultation historique retraits plaque"
- Détails : vehicule_id, total_retraits

### 3. ✅ Intégration avec le retrait de plaque

Le contrôleur `VehiculeController` a été modifié pour **automatiquement** enregistrer l'historique lors d'un retrait de plaque :

**Méthode : `retirerPlaque($id, $agentUsername, $motif, $observations)`**

Lors de l'exécution :
1. Vérifie l'existence du véhicule
2. **Enregistre l'historique** avec l'ancienne plaque
3. Met à jour le véhicule (plaque = NULL)
4. Commit de la transaction

### 4. ✅ Interface utilisateur Flutter

#### Nouvel onglet dans `VehiculeDetailsModal`

**Onglet : "Historique retraits"**
- Icône : `Icons.history`
- Position : 6ème onglet (après Avis de recherche)

**Fonctionnalités :**
- ✅ Chargement automatique à l'ouverture de la modal
- ✅ Affichage dans un tableau DataTable responsive
- ✅ Gestion des états : loading, erreur, vide, données
- ✅ Bouton réessayer en cas d'erreur
- ✅ Message informatif si aucun retrait

**Colonnes du tableau :**
1. **ID** : Numéro de l'enregistrement
2. **Plaque retirée** : Numéro de plaque (en gras)
3. **Date retrait** : Date formatée (DD/MM/YYYY HH:MM)
4. **Motif** : Raison du retrait
5. **Agent** : Nom de l'utilisateur
6. **Observations** : Notes supplémentaires

**Design :**
- En-tête avec compteur : "Historique des retraits (X)"
- Tableau avec bordures arrondies
- Scroll vertical pour gérer plusieurs entrées
- Police de 12px pour optimiser l'espace
- Overflow ellipsis sur 2 lignes max

## Installation

### 1. Créer la table

Exécuter le script d'initialisation :

```bash
cd api/database
php init_historique_retrait_plaques.php
```

Ou exécuter le SQL directement :

```bash
mysql -u votre_user -p votre_db < create_historique_retrait_plaques.sql
```

### 2. Tester l'installation

```bash
cd api/database
php test_historique_retrait.php
```

### 3. Vérifier dans l'application Flutter

1. Ouvrir un dossier véhicule
2. Naviguer vers l'onglet "Historique retraits"
3. Vérifier l'affichage des données

## Utilisation

### Scénario : Retrait d'une plaque

1. **Action utilisateur :** Clic sur "Retirer la plaque" dans l'onglet véhicules
2. **Système :**
   - Enregistre automatiquement dans `historique_retrait_plaques`
   - Met à jour le véhicule
   - Logue l'activité
3. **Consultation :** L'historique apparaît dans l'onglet dédié

### Consultation de l'historique

1. Ouvrir la modal détails d'un véhicule
2. Cliquer sur l'onglet "Historique retraits"
3. Consulter tous les retraits passés

## Avantages

✅ **Traçabilité complète** : Chaque retrait est enregistré avec date, motif, agent  
✅ **Historique préservé** : Les données ne sont jamais supprimées  
✅ **Audit facile** : Possibilité de suivre qui a retiré quelle plaque et quand  
✅ **Interface intuitive** : Tableau clair avec toutes les informations  
✅ **Logging automatique** : Toutes les consultations sont tracées  
✅ **Performance optimisée** : Index sur les colonnes clés  

## Fichiers créés/modifiés

### Backend
- ✅ `/api/controllers/HistoriqueRetraitPlaqueController.php` - Nouveau contrôleur
- ✅ `/api/controllers/VehiculeController.php` - Méthode `retirerPlaque()` modifiée
- ✅ `/api/routes/index.php` - Import du contrôleur
- ✅ `/api/database/create_historique_retrait_plaques.sql` - Script SQL
- ✅ `/api/database/init_historique_retrait_plaques.php` - Script d'initialisation
- ✅ `/api/database/test_historique_retrait.php` - Script de test

### Frontend
- ✅ `/lib/widgets/vehicule_details_modal.dart` - Nouvel onglet ajouté
  - État : `_historiqueRetraits`, `_loadingHistoriqueRetraits`, `_errorHistoriqueRetraits`
  - Méthode : `_loadHistoriqueRetraits()`
  - Widget : `_buildHistoriqueRetraitsTab()`
  - TabController : length: 5 → 6

## Tests

### Test Backend

```bash
php api/database/test_historique_retrait.php
```

**Vérifie :**
- ✅ Récupération de tous les historiques
- ✅ Récupération pour un véhicule spécifique
- ✅ Structure de données

### Test Frontend

1. Ouvrir l'application Flutter
2. Naviguer vers "Consulter tous les dossiers" → Véhicules
3. Cliquer sur "Voir détails" pour un véhicule
4. Vérifier l'onglet "Historique retraits"
5. Tester les états : loading, erreur (déconnecter API), vide, avec données

## Maintenance

### Ajouter un champ à l'historique

1. Modifier la table SQL
2. Mettre à jour `HistoriqueRetraitPlaqueController::create()`
3. Mettre à jour `VehiculeController::retirerPlaque()`
4. Ajouter la colonne dans le DataTable Flutter

### Supprimer un historique

⚠️ **Attention** : Les historiques sont liés aux véhicules avec `ON DELETE CASCADE`.  
Si un véhicule est supprimé, son historique est automatiquement supprimé.

## Sécurité

✅ **Validation des données** : ID véhicule vérifié côté backend  
✅ **Transactions SQL** : Atomicité garantie pour les retraits  
✅ **Logging complet** : Traçabilité de toutes les actions  
✅ **Foreign Key** : Intégrité référentielle garantie  
✅ **Username enregistré** : Responsabilité tracée  

## Support

En cas de problème :

1. Vérifier que la table existe : `SHOW TABLES LIKE 'historique_retrait_plaques';`
2. Vérifier les logs d'activités pour les erreurs
3. Tester l'endpoint API avec Postman/Insomnia
4. Vérifier les logs du serveur PHP

---

**Date de création** : 2025-10-06  
**Version** : 1.0.0  
**Auteur** : BCR Development Team
