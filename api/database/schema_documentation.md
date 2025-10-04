# Structure de la base de données BCR

Généré automatiquement le 2025-10-03 03:22:50

## Table: `accident_vehicules`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | int(10) unsigned | NO | PRI |  | auto_increment |
| `accident_id` | int(10) unsigned | NO | MUL |  |  |
| `vehicule_plaque_id` | int(10) unsigned | NO | MUL |  |  |
| `role` | varchar(50) | YES |  |  |  |
| `dommages` | text | YES |  |  |  |
| `notes` | varchar(255) | YES |  |  |  |
| `created_at` | datetime | YES |  | current_timestamp() |  |

## Table: `accidents`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `date_accident` | datetime | NO |  |  |  |
| `lieu` | varchar(100) | NO |  |  |  |
| `gravite` | varchar(200) | NO |  |  |  |
| `description` | longtext | NO |  |  |  |
| `images` | longtext | YES |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `activites`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | int(11) | NO | PRI |  | auto_increment |
| `username` | varchar(100) | YES | MUL |  |  |
| `action` | varchar(255) | NO | MUL |  |  |
| `details_operation` | text | YES |  |  |  |
| `ip_address` | varchar(45) | YES |  |  |  |
| `user_agent` | text | YES |  |  |  |
| `created_at` | timestamp | NO | MUL | current_timestamp() |  |

### Exemples de données:

```json
[
    {
        "id": 1,
        "username": "fsdfsdfsd",
        "action": "POST \/auth\/login",
        "details_operation": "{\"method\":\"POST\",\"params\":{\"matricule\":\"fsdfsdfsd\",\"password\":\"fsdfsdfds\"}}",
        "ip_address": "::1",
        "user_agent": "Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit\/537.36 (KHTML, like Gecko) Chrome\/140.0.0.0 Safari\/537.36",
        "created_at": "2025-10-03 03:21:09"
    },
    {
        "id": 2,
        "username": "teste",
        "action": "POST \/auth\/login",
        "details_operation": "{\"method\":\"POST\",\"params\":{\"matricule\":\"teste\",\"password\":\"teste\"}}",
        "ip_address": "::1",
        "user_agent": "Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit\/537.36 (KHTML, like Gecko) Chrome\/140.0.0.0 Safari\/537.36",
        "created_at": "2025-10-03 03:23:26"
    },
    {
        "id": 3,
        "username": "admin",
        "action": "POST \/auth\/login",
        "details_operation": "{\"method\":\"POST\",\"params\":{\"matricule\":\"admin\",\"password\":\"password123\"}}",
        "ip_address": "::1",
        "user_agent": "Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit\/537.36 (KHTML, like Gecko) Chrome\/140.0.0.0 Safari\/537.36",
        "created_at": "2025-10-03 03:24:48"
    },
    {
        "id": 4,
        "username": "landry",
        "action": "Connexion",
        "details_operation": "{\"user_id\":\"3\",\"role\":\"superadmin\",\"first_connection\":false}",
        "ip_address": "::1",
        "user_agent": "Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit\/537.36 (KHTML, like Gecko) Chrome\/140.0.0.0 Safari\/537.36",
        "created_at": "2025-10-03 05:14:31"
    },
    {
        "id": 5,
        "username": "landry",
        "action": "POST \/auth\/login",
        "details_operation": "{\"method\":\"POST\",\"params\":{\"matricule\":\"landry\",\"password\":\"landr1\"}}",
        "ip_address": "::1",
        "user_agent": "Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit\/537.36 (KHTML, like Gecko) Chrome\/140.0.0.0 Safari\/537.36",
        "created_at": "2025-10-03 05:14:31"
    }
]
```

## Table: `agents`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `matricule` | longtext | NO |  |  |  |
| `nom` | varchar(30) | NO |  |  |  |
| `postnom` | varchar(30) | NO |  |  |  |
| `poste` | varchar(59) | NO |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `arrestations`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | int(10) unsigned | NO | PRI |  | auto_increment |
| `particulier_id` | int(10) unsigned | NO | MUL |  |  |
| `motif` | text | NO |  |  |  |
| `lieu` | varchar(255) | YES |  |  |  |
| `date_arrestation` | datetime | YES |  |  |  |
| `date_sortie_prison` | datetime | YES |  |  |  |
| `created_by` | varchar(100) | YES |  |  |  |
| `created_at` | datetime | NO | MUL |  |  |
| `updated_at` | datetime | NO |  |  |  |

## Table: `assurance_vehicule`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `vehicule_plaque_id` | bigint(20) | NO | MUL |  |  |
| `societe_assurance` | varchar(255) | YES |  |  |  |
| `nume_assurance` | varchar(100) | YES |  |  |  |
| `date_valide_assurance` | date | YES |  |  |  |
| `date_expire_assurance` | date | YES | MUL |  |  |
| `montant_prime` | decimal(10,2) | YES |  |  |  |
| `type_couverture` | varchar(100) | YES |  |  |  |
| `notes` | text | YES |  |  |  |
| `created_at` | timestamp | YES | MUL | current_timestamp() |  |
| `updated_at` | timestamp | YES |  | current_timestamp() | on update current_timestamp() |

## Table: `avis_recherche`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `cible_type` | varchar(50) | NO | MUL |  |  |
| `cible_id` | bigint(20) | NO |  |  |  |
| `motif` | text | NO |  |  |  |
| `niveau` | varchar(20) | NO |  | moyen |  |
| `statut` | varchar(20) | NO | MUL | actif |  |
| `created_by` | varchar(100) | YES |  |  |  |
| `created_at` | datetime | NO |  |  |  |
| `updated_at` | datetime | NO |  |  |  |

## Table: `conducteur_vehicule`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `nom` | varchar(200) | NO |  |  |  |
| `numero_permis` | varchar(200) | YES |  |  |  |
| `date_naissance` | datetime | YES |  |  |  |
| `adresse` | longtext | YES |  |  |  |
| `photo` | longtext | NO |  |  |  |
| `permis_recto` | longtext | YES |  |  |  |
| `permis_verso` | longtext | YES |  |  |  |
| `permis_valide_le` | datetime | NO |  | current_timestamp() |  |
| `permis_expire_le` | datetime | YES |  | current_timestamp() |  |
| `observations` | longtext | YES |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `contraventions`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `dossier_id` | varchar(30) | NO |  |  |  |
| `type_dossier` | varchar(70) | NO |  |  |  |
| `date_infraction` | datetime | NO |  |  |  |
| `lieu` | longtext | YES |  |  |  |
| `type_infraction` | longtext | YES |  |  |  |
| `description` | longtext | YES |  |  |  |
| `reference_loi` | longtext | YES |  |  |  |
| `amende` | varchar(200) | YES |  |  |  |
| `payed` | varchar(10) | NO |  | non |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |
| `photos` | text | YES |  |  |  |

## Table: `entreprise_vehicule`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) unsigned | NO | PRI |  |  |
| `entreprise_id` | bigint(20) unsigned | NO | MUL |  |  |
| `vehicule_plaque_id` | int(10) unsigned | NO | MUL |  |  |
| `date_assoc` | datetime | YES |  |  |  |
| `notes` | varchar(255) | YES |  |  |  |
| `created_at` | datetime | YES |  | current_timestamp() |  |
| `created_by` | varchar(100) | YES |  |  |  |

## Table: `entreprises`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `designation` | varchar(250) | NO |  |  |  |
| `siege_social` | longtext | NO |  |  |  |
| `gsm` | varchar(30) | NO |  |  |  |
| `email` | varchar(50) | YES |  |  |  |
| `personne_contact` | varchar(29) | YES |  |  |  |
| `fonction_contact` | varchar(100) | NO |  |  |  |
| `telephone_contact` | varchar(20) | NO |  |  |  |
| `rccm` | varchar(70) | YES |  |  |  |
| `secteur` | varchar(70) | YES |  |  |  |
| `observations` | longtext | YES |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `particulier_vehicule`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | int(10) unsigned | NO |  |  |  |
| `particulier_id` | bigint(20) | NO |  |  |  |
| `vehicule_plaque_id` | bigint(20) | NO |  |  |  |
| `role` | varchar(50) | NO |  | proprietaire |  |
| `date_assoc` | datetime | YES |  |  |  |
| `notes` | text | YES |  |  |  |
| `created_at` | datetime | YES |  |  |  |
| `created_by` | varchar(100) | YES |  |  |  |

## Table: `particuliers`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `nom` | varchar(100) | NO |  |  |  |
| `adresse` | longtext | YES |  |  |  |
| `profession` | varchar(40) | YES |  |  |  |
| `date_naissance` | datetime | YES |  |  |  |
| `genre` | varchar(10) | YES |  |  |  |
| `numero_national` | varchar(50) | YES |  |  |  |
| `gsm` | varchar(20) | YES |  |  |  |
| `email` | varchar(90) | YES |  |  |  |
| `lieu_naissance` | varchar(120) | YES |  |  |  |
| `nationalite` | varchar(90) | YES |  |  |  |
| `etat_civil` | varchar(50) | YES |  |  |  |
| `personne_contact` | varchar(200) | YES |  |  |  |
| `personne_contact_telephone` | varchar(20) | YES |  |  |  |
| `observations` | longtext | YES |  |  |  |
| `photo` | varchar(255) | YES |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |
| `permis_recto` | varchar(255) | YES |  |  |  |
| `permis_verso` | varchar(255) | YES |  |  |  |
| `permis_date_emission` | date | YES |  |  |  |
| `permis_date_expiration` | date | YES |  |  |  |

## Table: `permis_temporaire`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | int(10) unsigned | NO | PRI |  |  |
| `cible_type` | enum('particulier','conducteur','vehicule_plaque') | NO | MUL | particulier |  |
| `cible_id` | bigint(20) unsigned | NO |  |  |  |
| `numero` | varchar(50) | NO | UNI |  |  |
| `motif` | text | YES |  |  |  |
| `date_debut` | date | NO |  |  |  |
| `date_fin` | date | NO |  |  |  |
| `statut` | enum('actif','clos') | NO | MUL | actif |  |
| `pdf_path` | varchar(255) | YES | MUL |  |  |
| `created_by` | varchar(100) | YES |  |  |  |
| `created_at` | datetime | NO |  |  |  |
| `updated_at` | datetime | NO |  |  |  |

## Table: `roles`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `level` | int(11) | NO |  |  |  |
| `description` | varchar(30) | NO |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `temoins`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `id_accident` | bigint(20) | NO |  |  |  |
| `nom` | varchar(200) | NO |  |  |  |
| `telephone` | varchar(30) | YES |  |  |  |
| `age` | varchar(40) | YES |  |  |  |
| `lien_avec_accident` | varchar(250) | NO |  |  |  |
| `temoignage` | longtext | NO |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

## Table: `users`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  | auto_increment |
| `username` | varchar(70) | NO |  |  |  |
| `password` | longtext | NO |  |  |  |
| `telephone` | varchar(40) | YES |  |  |  |
| `first_connection` | varchar(10) | NO |  | yes |  |
| `role` | varchar(30) | NO | MUL |  |  |
| `matricule` | varchar(50) | YES | UNI |  |  |
| `poste` | varchar(70) | YES |  |  |  |
| `photo` | longtext | YES |  |  |  |
| `updated_at` | datetime | YES |  |  |  |
| `status` | varchar(30) | NO |  | active |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |
| `login_schedule` | text | YES |  |  |  |
| `statut` | varchar(20) | YES | MUL | actif |  |

### Exemples de données:

```json
[
    {
        "id": 3,
        "username": "landry",
        "password": "b0e69c61cf08f6e6ce12b4575886407d",
        "telephone": null,
        "first_connection": "false",
        "role": "superadmin",
        "matricule": "landry",
        "poste": null,
        "photo": null,
        "updated_at": "2025-10-03 04:19:14",
        "status": "active",
        "created_at": "2025-10-03 03:56:50",
        "login_schedule": null,
        "statut": "actif"
    },
    {
        "id": 4,
        "username": "micahel",
        "password": "670b14728ad9902aecba32e22fa4f6bd",
        "telephone": "+343",
        "first_connection": "true",
        "role": "instructeur",
        "matricule": "000000",
        "poste": null,
        "photo": null,
        "updated_at": null,
        "status": "active",
        "created_at": "2025-10-03 05:20:18",
        "login_schedule": "{\"Lundi\":{\"enabled\":true,\"start\":\"08:00\",\"end\":\"17:00\"},\"Mardi\":{\"enabled\":true,\"start\":\"08:00\",\"end\":\"17:00\"},\"Mercredi\":{\"enabled\":false,\"start\":\"08:00\",\"end\":\"17:00\"},\"Jeudi\":{\"enabled\":false,\"start\":\"08:00\",\"end\":\"17:00\"},\"Vendredi\":{\"enabled\":false,\"start\":\"08:00\",\"end\":\"17:00\"},\"Samedi\":{\"enabled\":false,\"start\":\"08:00\",\"end\":\"17:00\"},\"Dimanche\":{\"enabled\":false,\"start\":\"08:00\",\"end\":\"17:00\"}}",
        "statut": "actif"
    }
]
```

## Table: `vehicule_plaque`

| Colonne | Type | Null | Clé | Défaut | Extra |
|---------|------|------|-----|-----------|-------|
| `id` | bigint(20) | NO | PRI |  |  |
| `images` | longtext | YES |  |  |  |
| `marque` | varchar(80) | NO |  |  |  |
| `annee` | varchar(10) | NO |  |  |  |
| `couleur` | varchar(50) | YES |  |  |  |
| `modele` | varchar(100) | YES |  |  |  |
| `numero_chassis` | varchar(250) | YES |  |  |  |
| `frontiere_entree` | varchar(191) | YES |  |  |  |
| `date_importation` | date | YES |  |  |  |
| `plaque` | varchar(20) | YES |  |  |  |
| `plaque_valide_le` | datetime | YES |  |  |  |
| `plaque_expire_le` | datetime | YES |  |  |  |
| `en_circulation` | tinyint(1) | NO |  | 1 |  |
| `nume_assurance` | varchar(90) | YES |  |  |  |
| `date_expire_assurance` | datetime | YES |  |  |  |
| `date_valide_assurance` | datetime | YES |  |  |  |
| `societe_assurance` | varchar(90) | YES |  |  |  |
| `genre` | varchar(100) | YES |  |  |  |
| `usage` | varchar(150) | YES |  |  |  |
| `numero_declaration` | varchar(150) | YES |  |  |  |
| `num_moteur` | varchar(150) | YES |  |  |  |
| `origine` | varchar(150) | YES |  |  |  |
| `source` | varchar(150) | YES |  |  |  |
| `annee_fab` | varchar(10) | YES |  |  |  |
| `annee_circ` | varchar(10) | YES |  |  |  |
| `type_em` | varchar(100) | YES |  |  |  |
| `created_at` | datetime | NO |  | current_timestamp() |  |

