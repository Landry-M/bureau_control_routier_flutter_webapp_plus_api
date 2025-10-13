# Système de Contraventions - Génération Dynamique

## Principe

Le système **ne stocke PAS** de chemin PDF (`pdf_path`) dans la base de données. Le PDF est **généré dynamiquement à la demande** lors de l'affichage.

## Flux de fonctionnement

### 1. Création de contravention

**Données stockées en base :**
```sql
INSERT INTO contraventions (
    dossier_id,          -- ID du véhicule, particulier ou entreprise
    type_dossier,        -- 'vehicule_plaque', 'particulier', ou 'entreprise'
    date_infraction,
    lieu,
    type_infraction,
    description,
    reference_loi,
    amende,
    payed,
    photos,
    created_at
) VALUES (...)
```

**Pas de `pdf_path` stocké** ✅

### 2. Récupération des contraventions

**Endpoint API :**
```
GET /contraventions/vehicule/{vehicule_id}
```

**Contrôleur :**
```php
public function getByVehicule($vehiculeId) {
    $query = "SELECT * FROM contraventions 
             WHERE dossier_id = :dossier_id 
             AND type_dossier = 'vehicule_plaque'
             ORDER BY created_at DESC";
    // Retourne les données sans pdf_path
}
```

**Réponse JSON :**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "dossier_id": "45",
      "type_dossier": "vehicule_plaque",
      "type_infraction": "Excès de vitesse",
      "amende": "50000",
      "lieu": "Avenue Kasa-Vubu",
      "date_infraction": "2025-10-13 14:30:00"
      // Pas de pdf_path
    }
  ]
}
```

### 3. Affichage du PDF (Génération dynamique)

**URL d'affichage :**
```
GET /contravention/{contravention_id}/display
```

**Fichier :** `/api/contravention_display.php`

**Processus :**
1. Récupère les données de la contravention par ID
2. Fait les JOINs nécessaires selon `type_dossier`
3. Génère le HTML/PDF à la volée
4. Retourne le PDF au navigateur

**SQL dans contravention_display.php :**
```php
$stmt = $pdo->prepare("
    SELECT 
        c.*,
        CASE 
            WHEN c.type_dossier = 'particulier' THEN p.nom
            WHEN c.type_dossier = 'entreprise' THEN e.designation
            WHEN c.type_dossier = 'vehicule_plaque' THEN CONCAT('Véhicule ', vp.plaque)
        END as nom_contrevenant,
        vp.plaque as plaque_vehicule,
        vp.marque as marque_vehicule,
        vp.modele as modele_vehicule
    FROM contraventions c
    LEFT JOIN particuliers p ON c.type_dossier = 'particulier' AND c.dossier_id = p.id
    LEFT JOIN entreprises e ON c.type_dossier = 'entreprise' AND c.dossier_id = e.id
    LEFT JOIN vehicule_plaque vp ON c.type_dossier = 'vehicule_plaque' AND c.dossier_id = vp.id
    WHERE c.id = :id
");
```

## Avantages de cette approche

### ✅ Avantages

1. **Pas de stockage de fichiers**
   - Économie d'espace disque
   - Pas de gestion de fichiers orphelins
   - Pas de problèmes de synchronisation

2. **Toujours à jour**
   - Si on modifie une contravention, le PDF reflète immédiatement les changements
   - Pas besoin de régénérer le PDF

3. **Simplicité**
   - Pas de logique de génération de PDF à la création
   - Pas de nettoyage de fichiers

4. **Flexibilité**
   - Facile d'ajouter de nouveaux champs à afficher
   - Facile de changer le template

### ⚠️ Inconvénients (mineurs)

1. **Génération à chaque affichage**
   - Léger impact performance (négligeable)
   - Solution : Cache si nécessaire

2. **Nécessite wkhtmltopdf (si PDF binaire)**
   - Alternative : Afficher HTML stylisé
   - Ou utiliser PDF client-side (JavaScript)

## Implémentation Flutter

### Affichage des contraventions d'un véhicule

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class VehiculeDetailsScreen extends StatefulWidget {
  final int vehiculeId;
  // ...
}

class _VehiculeDetailsScreenState extends State<VehiculeDetailsScreen> {
  List<Map<String, dynamic>> _contraventions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadContraventions();
  }

  Future<void> _loadContraventions() async {
    setState(() => _loading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/contraventions/vehicule/${widget.vehiculeId}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _contraventions = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Erreur chargement contraventions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _viewPDF(int contraventionId) {
    // URL de génération dynamique du PDF
    final pdfUrl = '${ApiConfig.baseUrl}/contravention/$contraventionId/display';
    launchUrl(Uri.parse(pdfUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_loading)
          const CircularProgressIndicator(),
        
        if (_contraventions.isEmpty && !_loading)
          const Text('Aucune contravention'),
        
        ..._contraventions.map((cv) => Card(
          child: ListTile(
            title: Text(cv['type_infraction'] ?? ''),
            subtitle: Text('Amende: ${cv['amende']} FC'),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _viewPDF(cv['id']),
              tooltip: 'Voir PDF',
            ),
          ),
        )),
      ],
    );
  }
}
```

## Test du système

### Script de test créé

**Fichier :** `/api/test_vehicule_contravention_flow.php`

**Uploadez et exécutez :**
```
https://controls.heaventech.net/api/test_vehicule_contravention_flow.php
```

**Le script teste :**
1. ✅ Création d'une contravention
2. ✅ Vérification en base (pas de pdf_path)
3. ✅ Récupération via API
4. ✅ Jointure SQL pour l'affichage
5. ✅ URLs de test

### Test manuel

```bash
# 1. Créer un véhicule avec contravention via l'app

# 2. Récupérer les contraventions via API
curl 'https://controls.heaventech.net/api/contraventions/vehicule/123'

# 3. Afficher le PDF d'une contravention
# Dans le navigateur :
https://controls.heaventech.net/api/contravention/456/display
```

## Dépannage

### Problème : Contravention non affichée dans l'app

**Causes possibles :**

1. **Contravention non créée**
   - Vérifier les logs PHP
   - Vérifier que la transaction n'échoue pas
   - Script de test : `test_vehicule_contravention_flow.php`

2. **API ne retourne pas les données**
   - Tester avec curl
   - Vérifier le type_dossier ('vehicule_plaque')
   - Vérifier que dossier_id correspond à l'ID du véhicule

3. **Flutter ne parse pas correctement**
   - Vérifier la structure JSON attendue
   - Ajouter des logs dans le code Flutter

4. **Bouton PDF ne fonctionne pas**
   - Vérifier l'URL construite
   - Vérifier que contravention_display.php existe
   - Tester l'URL directement dans un navigateur

### Problème : PDF ne s'affiche pas (404)

**Causes :**

1. **Fichier contravention_display.php manquant**
   - Vérifier : `/api/contravention_display.php`
   - Uploader si manquant

2. **Route non configurée**
   - Vérifier dans `/api/routes/index.php`
   - Route doit être : `GET /contravention/{id}/display`

3. **Problème de .htaccess**
   - Vérifier la réécriture d'URL
   - Tester URL directe : `/contravention_display.php?id=123`

### Problème : Erreur lors de la génération PDF

**Causes :**

1. **Jointure SQL échoue**
   - Vérifier que la table vehicule_plaque existe
   - Vérifier l'alias `vp` dans le SQL

2. **wkhtmltopdf non installé**
   - Le fichier affiche HTML au lieu de PDF
   - Installer wkhtmltopdf ou accepter HTML

3. **Données manquantes**
   - Contravention existe mais véhicule supprimé
   - Gérer les LEFT JOIN NULL

## Structure de base de données

### Table contraventions

```sql
CREATE TABLE contraventions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dossier_id BIGINT NOT NULL,
    type_dossier VARCHAR(50) NOT NULL,  -- 'vehicule_plaque', 'particulier', 'entreprise'
    date_infraction DATETIME,
    lieu VARCHAR(255),
    type_infraction VARCHAR(255),
    description TEXT,
    reference_loi VARCHAR(255),
    amende DECIMAL(10,2),
    payed VARCHAR(10),
    photos TEXT,
    -- PAS DE pdf_path
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Index recommandés

```sql
CREATE INDEX idx_dossier ON contraventions(dossier_id, type_dossier);
CREATE INDEX idx_created ON contraventions(created_at);
```

## Checklist de vérification

- [ ] ✅ Table contraventions existe
- [ ] ✅ Table vehicule_plaque existe
- [ ] ✅ ContraventionController->create() n'essaie pas de générer PDF
- [ ] ✅ ContraventionController->getByVehicule() existe
- [ ] ✅ Route GET /contraventions/vehicule/{id} existe
- [ ] ✅ Fichier contravention_display.php existe
- [ ] ✅ Route GET /contravention/{id}/display existe
- [ ] ✅ Jointure SQL inclut vehicule_plaque (alias vp)
- [ ] ✅ Code Flutter appelle la bonne API
- [ ] ✅ Code Flutter construit la bonne URL PDF

## Conclusion

Le système fonctionne comme une **bibliothèque virtuelle** :
- Les **données** sont stockées en base
- Le **PDF** est généré à la demande quand on veut le consulter
- Pas de fichiers statiques à gérer

C'est plus simple, plus flexible, et toujours à jour !

## Statut

✅ **Système fonctionnel** - Génération dynamique
✅ **Pas de pdf_path** - Stockage minimal
✅ **Tests disponibles** - Scripts de diagnostic
📋 **Documentation** - Ce fichier
