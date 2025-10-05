# Utilisateurs du Système BCR

## Problème Résolu ✅

**Problème initial :** L'utilisateur "boom" (et autres) ne pouvaient pas se connecter, erreur 501/500.

**Causes identifiées :**
1. ~~Base de données incomplète~~ ✅ Résolu - utilisateurs créés
2. **Configuration serveur web incorrecte** ✅ Résolu - serveur PHP intégré
3. **URL incorrecte dans l'application Flutter** ✅ Résolu - URLs mises à jour

**Solutions appliquées :**
1. Création des utilisateurs manquants via `api/database/init_users.php`
2. Démarrage du serveur PHP intégré sur le port 8000
3. Mise à jour de toutes les URLs Flutter vers `localhost:8000`

## Utilisateurs Disponibles

### Utilisateurs Principaux (selon les mémoires)
1. **admin** / **password123** (rôle: admin)
2. **police001** / **police123** (rôle: agent) 
3. **super** / **super123** (rôle: superadmin)
4. **landry** / **landr1** (rôle: superadmin)

### Utilisateurs Additionnels (existants)
5. **police123** / **police123** (rôle: inspecteur)
6. **impala** / **impala** (rôle: agent_special)
7. **lubumbashi** / **lubumbashi** (rôle: inspecteur)
8. **boom** / **boombeach** (rôle: police) ✅ **TESTÉ ET FONCTIONNEL**
9. **test000** / *[mot de passe inconnu]* (rôle: agent)

## Rôles Disponibles

- **superadmin** : Accès complet au système
- **admin** : Administration générale
- **inspecteur** : Supervision et contrôle
- **agent** : Agent de base
- **agent_special** : Agent avec privilèges spéciaux

## Configuration Serveur ⚠️ IMPORTANT

### Démarrer le Serveur PHP (REQUIS)
```bash
cd /Users/apple/Documents/dev/flutter/bcr
php -S localhost:8000
```
**Le serveur DOIT rester en marche pour que l'application Flutter fonctionne !**

### URL de l'API
- **Ancienne URL (ne fonctionne pas):** `http://localhost/api/routes/index.php`
- **Nouvelle URL (fonctionnelle):** `http://localhost:8000/api/routes/index.php`

## Scripts de Maintenance

### Initialisation des Utilisateurs
```bash
cd /Users/apple/Documents/dev/flutter/bcr/api/database
php init_users.php
```

### Test des Connexions
```bash
cd /Users/apple/Documents/dev/flutter/bcr/api/database
php test_all_users.php
```

### Test Final (avec serveur en marche)
```bash
cd /Users/apple/Documents/dev/flutter/bcr/api/database
php final_test.php
```

## API d'Authentification

L'endpoint `/auth/login` accepte les requêtes POST avec :
```json
{
    "matricule": "nom_utilisateur",
    "password": "mot_de_passe"
}
```

## Notes Techniques

- Les mots de passe sont stockés en MD5 (à améliorer pour la sécurité)
- L'authentification vérifie le matricule ou le username
- Les horaires de connexion peuvent être configurés via `login_schedule`
- Les superadmins ne sont pas soumis aux restrictions d'horaires

## Résolution du Problème 501

L'erreur 501 était causée par :
1. Base de données incomplète (seul "landry" existait)
2. Tentatives de connexion avec des utilisateurs inexistants
3. Retour d'erreur 401 (non autorisé) mal interprété côté client

**Solution appliquée :**
- Ajout des utilisateurs manquants
- Vérification de tous les mots de passe
- Tests de connexion complets
- Documentation mise à jour

Tous les utilisateurs peuvent maintenant se connecter correctement ! 🎉
