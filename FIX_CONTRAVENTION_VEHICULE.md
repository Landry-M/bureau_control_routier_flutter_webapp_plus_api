# Fix : Contraventions de véhicules non affichées

## Problème

Après création d'un véhicule avec contravention :
- La contravention ne s'affiche pas
- Le bouton "voir PDF" ne fonctionne pas

## Diagnostic

**Script créé :** `/api/debug_vehicule_contravention.php`

**Uploadez-le et exécutez :**
```
https://controls.heaventech.net/api/debug_vehicule_contravention.php
```

## Solutions selon le diagnostic

### Solution 1 : Contravention non créée (Transaction échoue)

**Symptôme :** Le script montre aucune contravention de type `vehicule_plaque`

**Cause :** La création échoue silencieusement dans la transaction

**Fix :** Améliorer la gestion d'erreurs

```php
// Dans VehiculeController.php, ligne ~175
$contraventionResult = $contraventionController->create($contraventionData);

if (!$contraventionResult['success']) {
    // Logger l'erreur détaillée
    error_log("Erreur création contravention: " . json_encode($contraventionResult));
    throw new Exception('Erreur contravention: ' . $contraventionResult['message']);
}
```

**Test :** Créer un véhicule avec contravention et consulter les logs PHP

### Solution 2 : PDF non généré (wkhtmltopdf manquant)

**Symptôme :** Contravention créée mais `pdf_path` est NULL

**Cause :** wkhtmltopdf n'est pas installé sur le serveur

**Fix 1 - Installer wkhtmltopdf (si accès serveur) :**
```bash
# Debian/Ubuntu
sudo apt-get install wkhtmltopdf

# Via hébergeur
Contacter le support technique
```

**Fix 2 - Génération alternative sans wkhtmltopdf :**
Créer une vue HTML simple au lieu d'un PDF

**Test :** Vérifier installation
```bash
which wkhtmltopdf
wkhtmltopdf --version
```

### Solution 3 : Permissions /uploads/

**Symptôme :** PDF enregistré en base mais fichier absent

**Cause :** Permissions d'écriture manquantes

**Fix :**
```bash
# Via SSH
chmod 755 uploads/contraventions
chown www-data:www-data uploads/contraventions

# Via FTP/cPanel
Permissions : 755 pour uploads/contraventions/
```

**Test :** Créer un fichier test
```bash
touch uploads/contraventions/test.txt
# Si erreur = problème de permissions
```

### Solution 4 : URL PDF incorrecte

**Symptôme :** Contravention existe, PDF existe, mais erreur 404

**Cause :** Chemin `pdf_path` incorrect dans la base

**Fix :** Vérifier le format du chemin

```sql
-- Le chemin doit être relatif
SELECT id, pdf_path FROM contraventions WHERE type_dossier = 'vehicule_plaque' LIMIT 5;

-- Bon format : uploads/contraventions/contravention_123_2025-10-13.pdf
-- Mauvais format : /home/user/public_html/uploads/...
```

### Solution 5 : Endpoint Flutter incorrect

**Symptôme :** Tout OK côté serveur mais pas d'affichage Flutter

**Cause :** L'app Flutter n'appelle pas le bon endpoint

**Vérifier dans votre code Flutter :**
```dart
// Doit appeler :
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/contraventions/vehicule/$vehiculeId')
);

// Et pour le PDF :
final pdfUrl = '${ApiConfig.baseUrl}/contravention/$contraventionId/display';
```

## Test complet

### 1. Test API - Récupérer contraventions

```bash
curl 'https://controls.heaventech.net/api/contraventions/vehicule/VEHICULE_ID'
```

**Réponse attendue :**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "dossier_id": "VEHICULE_ID",
      "type_dossier": "vehicule_plaque",
      "type_infraction": "Excès de vitesse",
      "pdf_path": "uploads/contraventions/contravention_123_2025-10-13.pdf",
      ...
    }
  ]
}
```

### 2. Test PDF - Afficher

```bash
# Dans le navigateur
https://controls.heaventech.net/api/contravention/123/display

# Doit afficher ou télécharger le PDF
```

## Vérification Flutter

### Dans votre VehiculeDetailsModal ou équivalent

```dart
// 1. Charger les contraventions
Future<void> _loadContraventions() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/contraventions/vehicule/$vehiculeId'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _contraventions = data['data'] as List;
      });
    }
  } catch (e) {
    print('Erreur chargement contraventions: $e');
  }
}

// 2. Afficher le PDF
void _viewPDF(int contraventionId) {
  final url = '${ApiConfig.baseUrl}/contravention/$contraventionId/display';
  launchUrl(Uri.parse(url));
}
```

## Checklist de résolution

- [ ] Exécuter `debug_vehicule_contravention.php`
- [ ] Identifier le problème exact
- [ ] Appliquer la solution correspondante
- [ ] Tester création véhicule + contravention
- [ ] Vérifier affichage de la contravention
- [ ] Tester bouton "Voir PDF"
- [ ] Supprimer le fichier de debug

## Logs à consulter

```bash
# Logs PHP
tail -f /var/log/php_errors.log

# Logs Apache/Nginx
tail -f /var/log/apache2/error.log
tail -f /var/log/nginx/error.log

# Logs application (si configuré)
tail -f api/logs/app.log
```

## Contact support si problème persiste

**Informations à fournir :**
1. Résultat du script de diagnostic
2. Logs PHP (dernières lignes)
3. Screenshot de l'erreur Flutter
4. Réponse de `curl` test API

## Fichiers importants

- `/api/controllers/VehiculeController.php` (création)
- `/api/controllers/ContraventionController.php` (récupération)
- `/api/contravention_display.php` (affichage PDF)
- `/api/routes/index.php` (routes API)

## Statut

⚠️ **En attente du diagnostic** - Exécutez le script de debug
📋 **Documentation** : Ce fichier
🧪 **Script créé** : `/api/debug_vehicule_contravention.php`
