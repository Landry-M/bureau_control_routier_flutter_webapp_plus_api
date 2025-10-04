# 🗄️ SCHÉMA DE BASE DE DONNÉES BCR

> **Important**: Ce fichier doit être mis à jour chaque fois que vous modifiez la structure de la base de données.
> Exécutez `./sync_schema.sh` pour générer automatiquement la documentation.

## 📋 Tables principales

### `users` - Utilisateurs/Agents
```sql
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricule VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    telephone VARCHAR(20),
    role ENUM('admin', 'superadmin', 'agent', 'controleur', 'instructeur', 'inspecteur', 'inspectrice', 'police', 'agent_special') DEFAULT 'agent',
    password VARCHAR(255) NOT NULL,
    statut ENUM('actif', 'inactif') DEFAULT 'actif',
    first_connection ENUM('true', 'false') DEFAULT 'true',
    login_schedule TEXT, -- JSON des horaires autorisés
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### `activites` - Logs d'activités
```sql
CREATE TABLE activites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    action VARCHAR(255) NOT NULL,
    details TEXT, -- JSON des détails de l'action
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);
```

## 🔧 Commandes utiles

### Générer la documentation automatiquement
```bash
# Rendre le script exécutable (une seule fois)
chmod +x sync_schema.sh

# Exécuter la synchronisation
./sync_schema.sh
```

### Tester l'API
```bash
# Tester l'endpoint de schéma
curl "http://localhost/bcr/api/routes/index.php?route=/schema"

# Tester les logs
curl "http://localhost/bcr/api/routes/index.php?route=/logs"
```

## 📝 Règles importantes

1. **Toujours utiliser les noms de champs exacts** de la base de données
2. **Mettre à jour ce fichier** après chaque modification de structure
3. **Exécuter `sync_schema.sh`** pour générer la documentation automatique
4. **Tester les endpoints** après chaque changement

## 🚨 Champs critiques à retenir

- **users**: `matricule`, `username`, `telephone`, `role`, `password`, `statut`
- **activites**: `username`, `action`, `details`, `ip_address`, `created_at`

**❌ Champs supprimés** (ne plus utiliser):
- `prenom` (supprimé de users)
- `email` (supprimé de users)
- `details_operation` (renommé en `details` dans activites)
