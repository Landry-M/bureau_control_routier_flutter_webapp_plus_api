# Correction : Colonne prenom inexistante

## Problème

Erreur lors de la création d'un particulier via SOS Avis de recherche :
```json
{
    "success": false,
    "message": "Erreur lors de la création du particulier: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'prenom' in 'field list'"
}
```

## Cause

La table `particuliers` dans la base de données n'a **qu'une seule colonne `nom`** qui contient à la fois le nom et le prénom.

Il n'y a **pas de colonne `prenom` séparée**.

## Solution appliquée

✅ **Fichier modifié** : `/api/routes/index.php` (ligne ~1806)

### Avant :
```php
$insertQuery = "INSERT INTO particuliers (
    nom, prenom, gsm, adresse, ...  // ❌ colonne 'prenom' n'existe pas
```

### Après :
```php
// Concaténer nom et prenom dans la colonne 'nom'
$nomComplet = $data['nom'];
if (!empty($data['prenom'])) {
    $nomComplet = trim($data['nom'] . ' ' . $data['prenom']);
}

$insertQuery = "INSERT INTO particuliers (
    nom, gsm, adresse, ...  // ✅ Seulement 'nom', pas de 'prenom'
```

## Comportement

### Cas 1 : Seulement le nom fourni
```json
{
    "nom": "Kabila"
}
```
**Résultat dans la BDD** : `nom = "Kabila"`

### Cas 2 : Nom et prénom fournis
```json
{
    "nom": "Kabila",
    "prenom": "Joseph"
}
```
**Résultat dans la BDD** : `nom = "Kabila Joseph"`

### Cas 3 : Nom complet dans le champ nom
```json
{
    "nom": "Tshisekedi Tshilombo Félix"
}
```
**Résultat dans la BDD** : `nom = "Tshisekedi Tshilombo Félix"`

## Impact

✅ **SosAvisParticulierModal** : Fonctionne maintenant correctement
✅ **Autres modals** : Non impactées
✅ **Compatibilité** : Préserve les données existantes

## Structure de la table

```sql
CREATE TABLE `particuliers` (
  `id` bigint(20) NOT NULL,
  `nom` varchar(100) NOT NULL,  -- ✅ Nom complet (nom + prénom)
  `adresse` longtext DEFAULT NULL,
  `profession` varchar(100) DEFAULT NULL,
  `date_naissance` date DEFAULT NULL,
  `genre` varchar(10) DEFAULT NULL,
  `numero_national` varchar(50) DEFAULT NULL,
  `gsm` varchar(20) DEFAULT NULL,
  -- ... autres colonnes
  PRIMARY KEY (`id`)
);
```

**Important** : Il n'y a **pas** de colonne `prenom` distincte.

## Tests

### Test 1 : Création avec nom seul
```bash
curl -X POST "http://localhost/api/routes/index.php?route=/particuliers/create" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Kabila",
    "telephone": "+243 XXX",
    "username": "test"
  }'
```
✅ Résultat : `nom = "Kabila"`

### Test 2 : Création avec nom et prénom
```bash
curl -X POST "http://localhost/api/routes/index.php?route=/particuliers/create" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Kabila",
    "prenom": "Joseph",
    "telephone": "+243 XXX",
    "username": "test"
  }'
```
✅ Résultat : `nom = "Kabila Joseph"`

## Statut

✅ **CORRIGÉ** - Le système fonctionne maintenant correctement

Date de correction : 14 octobre 2025
