# Configuration du dossier uploads pour l'hébergement

## Problème résolu
Le dossier `uploads` était masqué lors de l'hébergement à cause de :
- Chemins absolus dans le `.htaccess` du dossier uploads
- Absence de règles d'exclusion dans le `.htaccess` principal

## Modifications effectuées

### 1. `/api/uploads/.htaccess`
✅ Suppression des chemins absolus incompatibles
✅ Configuration compatible avec tous les hébergeurs
✅ Maintien des règles CORS pour l'accès aux fichiers

### 2. `/api/.htaccess`
✅ Exclusion explicite du dossier uploads des redirections
✅ Autorisation d'accès direct aux fichiers et dossiers existants
✅ Configuration compatible hébergement

### 3. `/api/.htaccess_intermediate`
✅ Version avancée avec règles de routing améliorées
✅ Protection complète du dossier uploads
✅ Prêt pour production

## Déploiement sur serveur hébergé

### Étape 1 : Vérifier les fichiers
```bash
# Assurez-vous que ces fichiers sont présents
/api/.htaccess
/api/uploads/.htaccess
```

### Étape 2 : Permissions du dossier uploads
```bash
# Sur le serveur, définir les permissions
chmod 755 /chemin/vers/api/uploads
chmod 644 /chemin/vers/api/uploads/.htaccess
```

### Étape 3 : Tester l'accès
Accédez à : `https://votre-domaine.com/api/uploads/contraventions/fichier.pdf`
- ✅ Le fichier doit s'afficher
- ❌ Si erreur 404/403, vérifier les permissions

## Structure des URLs

### Développement local
```
http://localhost/bcr/api/uploads/contraventions/file.pdf
```

### Production hébergée
```
https://votre-domaine.com/api/uploads/contraventions/file.pdf
```

## Vérifications importantes

1. **Module mod_rewrite activé** : Requis pour les règles RewriteEngine
2. **AllowOverride All** : Doit être activé dans la config Apache du serveur
3. **Permissions fichiers** : 
   - Dossiers : 755
   - Fichiers : 644
   - .htaccess : 644

## En cas de problème

### Erreur 403 (Forbidden)
- Vérifier les permissions du dossier uploads
- Vérifier que AllowOverride All est activé
- Consulter les logs d'erreur Apache

### Erreur 404 (Not Found)
- Vérifier que le fichier existe réellement
- Vérifier le chemin d'accès (sensible à la casse)
- Vérifier les règles RewriteRule dans .htaccess

### Fichiers non accessibles
- Désactiver temporairement le .htaccess principal pour isoler le problème
- Vérifier les logs d'erreur du serveur
- Contacter le support de l'hébergeur si mod_rewrite n'est pas disponible

## Configuration hébergeur commun

### cPanel / Hostinger / OVH
- Les configurations actuelles devraient fonctionner directement
- AllowOverride All est généralement activé par défaut

### Serveur VPS / Dédié
Ajouter dans la config Apache (`/etc/apache2/sites-available/votre-site.conf`) :
```apache
<Directory /var/www/votre-site/api/uploads>
    AllowOverride All
    Require all granted
</Directory>
```

Puis redémarrer Apache :
```bash
sudo systemctl restart apache2
```
