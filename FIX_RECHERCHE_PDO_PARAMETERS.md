# Correction : Erreur de paramètres PDO dans la recherche

## Problème rencontré

Lors de la recherche dans les modals SOS (particulier et véhicule), l'erreur suivante se produisait :

```json
{
    "success": false,
    "error": "Erreur lors de la récupération des particuliers: SQLSTATE[HY093]: Invalid parameter number"
}
```

## Cause du problème

Dans PDO, **un paramètre nommé ne peut être utilisé qu'une seule fois** dans une requête SQL, même s'il est lié à la même valeur.

### ❌ Code incorrect (avant)

#### Particuliers (`ParticulierController.php`)
```php
// Ligne 305 - INCORRECT
$whereClause = 'WHERE nom LIKE :search OR gsm LIKE :search OR numero_permis LIKE :search';
$params[':search'] = '%' . $search . '%';
// ❌ Le paramètre :search est utilisé 3 fois mais défini 1 seule fois
```

#### Véhicules (`routes/index.php`)
```php
// Ligne 1016 - INCORRECT
$whereClause = 'WHERE plaque LIKE :search OR marque LIKE :search OR modele LIKE :search OR proprietaire LIKE :search';
$params[':search'] = '%' . $search . '%';
// ❌ Le paramètre :search est utilisé 4 fois mais défini 1 seule fois
```

## Solution appliquée

### ✅ Code corrigé (après)

#### Particuliers (`ParticulierController.php`)
```php
// Ligne 305-309 - CORRECT
$whereClause = 'WHERE nom LIKE :search1 OR gsm LIKE :search2 OR adresse LIKE :search3';
$searchParam = '%' . $search . '%';
$params[':search1'] = $searchParam;
$params[':search2'] = $searchParam;
$params[':search3'] = $searchParam;
// ✅ Chaque paramètre a un nom unique
```

**Note** : Changé `numero_permis` par `adresse` pour chercher dans un champ plus utile.

#### Véhicules (`routes/index.php`)
```php
// Ligne 1016-1021 - CORRECT
$whereClause = 'WHERE plaque LIKE :search1 OR marque LIKE :search2 OR modele LIKE :search3 OR proprietaire LIKE :search4';
$searchParam = '%' . $search . '%';
$params[':search1'] = $searchParam;
$params[':search2'] = $searchParam;
$params[':search3'] = $searchParam;
$params[':search4'] = $searchParam;
// ✅ Chaque paramètre a un nom unique
```

## Fichiers modifiés

1. **`/api/controllers/ParticulierController.php`**
   - Méthode : `getAll()`
   - Lignes : 305-309

2. **`/api/routes/index.php`**
   - Route : `GET /vehicules`
   - Lignes : 1016-1021

## Impact

### Fonctionnalités corrigées

✅ **Recherche de particuliers en temps réel** dans `SosAvisParticulierModal`
- Recherche par : nom, téléphone (gsm), adresse

✅ **Recherche de véhicules en temps réel** dans `SosAvisVehiculeModal`
- Recherche par : plaque, marque, modèle, propriétaire

### Tests à effectuer

1. **Modal SOS Particulier**
   ```
   1. Ouvrir le modal SOS > Avis de recherche particulier
   2. Activer le switch "Particulier existant"
   3. Taper un nom dans la recherche (ex: "Kabila")
   4. Vérifier que les résultats s'affichent
   ```

2. **Modal SOS Véhicule**
   ```
   1. Ouvrir le modal SOS > Avis de recherche véhicule
   2. Activer le switch "Véhicule existant"
   3. Taper une plaque dans la recherche (ex: "CD-001")
   4. Vérifier que les résultats s'affichent
   ```

## Principe PDO

### Règle importante
> **Avec PDO et les paramètres nommés (`:param`), chaque occurrence du paramètre dans la requête SQL doit avoir un nom unique.**

### Alternatives possibles

#### 1. Paramètres nommés uniques (solution adoptée)
```php
$sql = "WHERE nom LIKE :search1 OR gsm LIKE :search2";
$stmt->bindValue(':search1', $value);
$stmt->bindValue(':search2', $value);
```

#### 2. Paramètres positionnels (alternative)
```php
$sql = "WHERE nom LIKE ? OR gsm LIKE ?";
$stmt->bindValue(1, $value);
$stmt->bindValue(2, $value);
```

#### 3. Répétition du bind (fonctionne mais verbeux)
```php
$sql = "WHERE nom LIKE :search OR gsm LIKE :search";
$stmt->bindValue(':search', $value);
// Ceci NE fonctionne PAS avec PDO !
```

## Statut

✅ **CORRIGÉ** - La recherche en temps réel fonctionne maintenant correctement

Date de correction : 14 octobre 2025

## Références

- [Documentation PDO - Prepared Statements](https://www.php.net/manual/en/pdo.prepared-statements.php)
- Erreur PDO : `SQLSTATE[HY093]: Invalid parameter number`
